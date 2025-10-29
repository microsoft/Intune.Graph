<#
.SYNOPSIS
    Clones Intune Settings Catalog policies and Endpoint Security intents with scope tag management.

.DESCRIPTION
    Discovers all Intune configuration policies and intents tagged with EXACTLY the supplied
    source scope tag. Allows interactive selection or direct specification by name.
    Creates clones with ONLY the destination scope tags applied (source tags are used for exact match search only).

    Supports both interactive mode (with prompts) and fully automated mode (no prompts).
    Supports -WhatIf and -Confirm for safe execution.

.PARAMETER SourceScopeTagName
    Display name of the scope tag to search for (e.g., "Production")

.PARAMETER DestinationScopeTagName
    One or more scope tag display names to apply to the clone (e.g., "Development")

.PARAMETER ProfileName
    Optional exact policy name(s) to clone directly; if omitted an interactive picker is shown

.PARAMETER NewProfileName
    Optional new name for cloned policy; if omitted auto-generates unique name

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    Copy-IntuneConfigurationProfile -SourceScopeTagName "Production" -DestinationScopeTagName "Development"

    Displays an interactive picker to select and clone policies tagged with ONLY the Production scope tag.

.EXAMPLE
    Copy-IntuneConfigurationProfile -SourceScopeTagName "Production" -DestinationScopeTagName "Development" -ProfileName "AV Policy"

    Auto-generates unique name for clone (e.g., "Copy of AV Policy - 20251016-131927").

.EXAMPLE
    Copy-IntuneConfigurationProfile -SourceScopeTagName "Production" -DestinationScopeTagName "Development","Test" -ProfileName "AV Policy" -NewProfileName "New AV Policy"

    Fully automated: clones the policy with specified name (no prompts).
    Clone will have Development and Test scope tags.

.EXAMPLE
    Copy-IntuneConfigurationProfile -SourceScopeTagName "Production" -DestinationScopeTagName "Development" -WhatIf

    Shows what policies would be cloned without making any changes.

.NOTES
    Prerequisites:
    - Requires Microsoft.Graph.Authentication module
    - Graph connection with scopes: DeviceManagementConfiguration.ReadWrite.All, DeviceManagementRBAC.ReadWrite.All

    Scope Tag Behavior:
    - Source scope tags: Used to FIND policies (exact match search filter only)
    - Policies must have EXACTLY the source scope tag specified
    - Destination scope tags: Applied to cloned policies (replaces source tags)
    - Clones are NOT tagged with the source scope tag unless also specified as destination tag

    Automation Support:
    - Interactive mode: No ProfileName parameter - shows picker and prompts for names
    - Semi-automated: ProfileName provided - auto-generates unique clone names with timestamp
    - Fully automated: ProfileName + NewProfileName - no prompts, runs unattended
#>

function Copy-IntuneConfigurationProfile {
    [CmdletBinding(PositionalBinding = $true, SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, 1)]
        [string[]]$SourceScopeTagName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, 64)]
        [string[]]$DestinationScopeTagName,

        [Parameter()]
        [string[]]$ProfileName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$NewProfileName,

        [Parameter()]
        [ValidateSet("Global", "USGov", "USGovDoD")]
        [string]$Environment = "Global"
    )
    begin {
        if ($false -eq (Initialize-IntuneAccess -Scopes @("DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementRBAC.ReadWrite.All") -Modules @("Microsoft.Graph.Authentication") -Environment $Environment)) {
            return
        }
        
        switch ($Environment) {
            "USGov" { $uri = "https://graph.microsoft.us" }
            "USGovDoD" { $uri = "https://dod-graph.microsoft.us" }
            Default { $uri = "https://graph.microsoft.com" }
        }

        $graphVersion = "beta"
        $graphRoot = "$uri/$graphVersion"

        function Get-AllPages {
            [CmdletBinding()]
            [OutputType([array])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$Uri
            )

            $items = @()
            $response = Invoke-MgGraphRequest -Method GET -Uri $Uri

            if ($response.value) {
                $items += $response.value
            } else {
                return , $response
            }

            while ($response.'@odata.nextLink') {
                $response = Invoke-MgGraphRequest -Method GET -Uri $response.'@odata.nextLink'
                if ($response.value) {
                    $items += $response.value
                }
            }

            return $items
        }

        function Resolve-ScopeTags {
            [CmdletBinding()]
            [OutputType([hashtable])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string[]]$SourceScopeTagName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string[]]$DestinationScopeTagName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$GraphRoot
            )

            Write-Verbose "Resolving scope tags from Graph..."
            $tags = Get-AllPages -Uri "$GraphRoot/deviceManagement/roleScopeTags?`$select=id,displayName&`$top=999"

            if (-not $tags) {
                throw "No scope tags returned from Graph."
            }

            $sourceIds = foreach ($displayName in $SourceScopeTagName) {
                $matchedTag = $tags | Where-Object { $_.displayName -ieq $displayName }

                if (-not $matchedTag) {
                    throw "Source scope tag '$displayName' not found."
                }

                Write-Verbose "Found source scope tag: $displayName (ID: $($matchedTag.id))"
                $matchedTag.id
            }

            $destinationIds = foreach ($displayName in $DestinationScopeTagName) {
                $matchedTag = $tags | Where-Object { $_.displayName -ieq $displayName }

                if (-not $matchedTag) {
                    throw "Destination scope tag '$displayName' not found."
                }

                Write-Verbose "Found destination scope tag: $displayName (ID: $($matchedTag.id))"
                $matchedTag.id
            }

            @{
                SrcIds = $sourceIds
                AllIds = $destinationIds
            }
        }

        function Get-SourceTaggedItems {
            [CmdletBinding()]
            [OutputType([array])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string[]]$SourceTagIds,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$GraphRoot
            )

            Write-Verbose "Querying Settings Catalog policies..."
            $settingsCatalogPolicies = Get-AllPages -Uri "$GraphRoot/deviceManagement/configurationPolicies?`$select=id,name,roleScopeTagIds,platforms,technologies,templateReference&`$expand=settings&`$top=999"
            $settingsCatalogHits = $settingsCatalogPolicies | Where-Object {
                if ($_.roleScopeTagIds.Count -eq $SourceTagIds.Count) {
                    $allMatch = $true
                    foreach ($tagId in $SourceTagIds) {
                        if ($_.roleScopeTagIds -notcontains $tagId) {
                            $allMatch = $false
                            break
                        }
                    }
                    $allMatch
                } else {
                    $false
                }
            } | ForEach-Object {
                $_ | Select-Object `
                    @{ n = 'Type'; e = { 'SC' } },
                    @{ n = 'Name'; e = { $_.name } },
                    @{ n = 'Id'; e = { $_.id } },
                    @{ n = 'Raw'; e = { $_ } }
            }

            Write-Verbose "Querying Endpoint Security intents..."
            $intents = Get-AllPages -Uri "$GraphRoot/deviceManagement/intents?`$select=id,displayName,roleScopeTagIds,templateId&`$top=999"
            $intentHits = $intents | Where-Object {
                if ($_.roleScopeTagIds.Count -eq $SourceTagIds.Count) {
                    $allMatch = $true
                    foreach ($tagId in $SourceTagIds) {
                        if ($_.roleScopeTagIds -notcontains $tagId) {
                            $allMatch = $false
                            break
                        }
                    }
                    $allMatch
                } else {
                    $false
                }
            } | ForEach-Object {
                $_ | Select-Object `
                    @{ n = 'Type'; e = { 'INTENT' } },
                    @{ n = 'Name'; e = { $_.displayName } },
                    @{ n = 'Id'; e = { $_.id } },
                    @{ n = 'Raw'; e = { $_ } }
            }

            $allItems = @($settingsCatalogHits + $intentHits)
            Write-Verbose "Found $($allItems.Count) policies/intents with exact source tag match."
            $allItems
        }

        function Select-ByNumber {
            [CmdletBinding()]
            [OutputType([object])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                $Items
            )

            if (-not $Items -or $Items.Count -eq 0) {
                throw "No matching policies found."
            }

            $ordered = $Items | Sort-Object Name, Type
            Write-Information "" -InformationAction Continue
            Write-Information "Matching policies:" -InformationAction Continue

            for ($i = 0; $i -lt $ordered.Count; $i++) {
                $number = $i + 1
                Write-Information ("{0,3}. {1}" -f $number, $ordered[$i].Name) -InformationAction Continue
            }

            Write-Information "" -InformationAction Continue

            while ($true) {
                $choice = Read-Host ("Enter number 1-{0} (or Enter to cancel)" -f $ordered.Count)

                if ([string]::IsNullOrWhiteSpace($choice)) {
                    return $null
                }

                if ($choice -as [int]) {
                    $number = [int]$choice

                    if ($number -ge 1 -and $number -le $ordered.Count) {
                        return $ordered[$number - 1]
                    }
                }

                Write-Warning "Invalid selection."
            }
        }

        function ConvertTo-NormalizedName {
            [CmdletBinding()]
            [OutputType([string])]
            param (
                [Parameter(Mandatory = $true)]
                [AllowEmptyString()]
                [string]$String
            )

            if ($null -eq $String) {
                return ""
            }

            $String = $String.Trim()

            if ($String.Length -ge 2 -and (
                ($String.StartsWith("'") -and $String.EndsWith("'")) -or
                ($String.StartsWith('"') -and $String.EndsWith('"')))) {
                $String = $String.Substring(1, $String.Length - 2)
            }

            $String.Trim()
        }

        function Get-ExistingPolicyNames {
            [CmdletBinding()]
            [OutputType([System.Collections.Generic.HashSet[string]])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$GraphRoot
            )

            Write-Verbose "Building list of existing policy names..."
            $names = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

            $allSettingsCatalogPolicies = Get-AllPages -Uri "$GraphRoot/deviceManagement/configurationPolicies?`$select=id,name&`$top=999"

            foreach ($policy in $allSettingsCatalogPolicies) {
                if ($policy.name) {
                    $null = $names.Add($policy.name)
                }
            }

            $allIntents = Get-AllPages -Uri "$GraphRoot/deviceManagement/intents?`$select=id,displayName&`$top=999"

            foreach ($intent in $allIntents) {
                if ($intent.displayName) {
                    $null = $names.Add($intent.displayName)
                }
            }

            Write-Verbose "Found $($names.Count) existing policy/intent names."
            return $names
        }

        function New-UniqueCloneName {
            [CmdletBinding()]
            [OutputType([string])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$BaseName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.Collections.Generic.HashSet[string]]$ExistingNames
            )

            $candidateName = "Copy of $BaseName"
            $counter = 2

            while ($ExistingNames.Contains($candidateName)) {
                $candidateName = "Copy of $BaseName ($counter)"
                $counter++
            }

            Write-Verbose "Auto-generated unique name: $candidateName"
            $null = $ExistingNames.Add($candidateName)
            return $candidateName
        }

        function Read-UniqueName {
            [CmdletBinding()]
            [OutputType([string])]
            param (
                [Parameter()]
                [string]$Default = "",

                [Parameter()]
                [System.Collections.Generic.HashSet[string]]$ExistingNames
            )

            if (-not $ExistingNames) {
                $ExistingNames = Get-ExistingPolicyNames -GraphRoot $graphRoot
            }

            while ($true) {
                $promptSuffix = if ($Default) { " [Default: $Default]" } else { "" }
                $name = Read-Host ("Enter NEW name for the clone{0}" -f $promptSuffix)

                if ([string]::IsNullOrWhiteSpace($name)) {
                    $name = $Default
                }

                $name = ConvertTo-NormalizedName -String $name

                if ([string]::IsNullOrWhiteSpace($name)) {
                    Write-Warning "Name cannot be blank."
                    continue
                }

                if ($ExistingNames.Contains($name)) {
                    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                    $uniqueName = "$name - $timestamp"
                    Write-Information "A policy named '$name' already exists. Using '$uniqueName' instead." -InformationAction Continue
                    return $uniqueName
                }

                return $name
            }
        }

        function Copy-SettingsCatalogPolicy {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                $Item,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$NewName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [string[]]$RoleScopeTagIds,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$GraphRoot
            )

            $policy = $Item.Raw
            $body = [ordered]@{
                name = $NewName
                description = ("Cloned from '{0}' ({1}) on {2:u}" -f $policy.name, $policy.id, (Get-Date))
                platforms = $policy.platforms
                technologies = $policy.technologies
                roleScopeTagIds = $RoleScopeTagIds
                templateReference = $policy.templateReference
                settings = $policy.settings
            } | ConvertTo-Json -Depth 100

            Write-Verbose "Creating Settings Catalog policy: $NewName"
            $newPolicy = Invoke-MgGraphRequest -Method POST -Uri "$GraphRoot/deviceManagement/configurationPolicies" -Body $body -ContentType "application/json"
            Write-Information ("Cloned Settings Catalog: '{0}' -> '{1}' (tags: {2})" -f $policy.name, $newPolicy.name, ($RoleScopeTagIds -join ", ")) -InformationAction Continue
        }

        function Copy-IntentPolicy {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                $Item,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$NewName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [string[]]$RoleScopeTagIds,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]$GraphRoot
            )

            $policy = $Item.Raw

            $copyUri = "$GraphRoot/deviceManagement/intents/$($policy.id)/createCopy"
            $copyBody = @{
                displayName = $NewName
                description = ("Cloned from '{0}' ({1}) on {2:u}" -f $policy.displayName, $policy.id, (Get-Date))
            } | ConvertTo-Json

            Write-Verbose "Creating copy of intent: $NewName"
            $newIntent = Invoke-MgGraphRequest -Method POST -Uri $copyUri -Body $copyBody -ContentType "application/json"

            if (-not $newIntent.id) {
                throw "createCopy did not return a new intent id."
            }

            Write-Verbose "Applying scope tags to intent: $($newIntent.id)"
            $patchBody = @{ roleScopeTagIds = $RoleScopeTagIds } | ConvertTo-Json
            Invoke-MgGraphRequest -Method PATCH -Uri "$GraphRoot/deviceManagement/intents/$($newIntent.id)" -Body $patchBody -ContentType "application/json" | Out-Null

            Write-Information ("Cloned Intent: '{0}' -> '{1}' (tags: {2})" -f $policy.displayName, $NewName, ($RoleScopeTagIds -join ", ")) -InformationAction Continue
        }
    }
    process {
        $tags = Resolve-ScopeTags -SourceScopeTagName $SourceScopeTagName -DestinationScopeTagName $DestinationScopeTagName -GraphRoot $graphRoot
        $items = Get-SourceTaggedItems -SourceTagIds $tags.SrcIds -GraphRoot $graphRoot

        if (-not $items -or $items.Count -eq 0) {
            Write-Information "No policies found with exact source tag match '$($SourceScopeTagName -join ', ')'." -InformationAction Continue
            return
        }

        if (-not $script:_AllExistingNames) {
            $script:_AllExistingNames = Get-ExistingPolicyNames -GraphRoot $graphRoot
        }

        if ($ProfileName) {
            if ($NewProfileName -and $ProfileName.Count -gt 1) {
                Write-Warning "NewProfileName can only be used when cloning a single profile. Ignoring NewProfileName parameter."
                $NewProfileName = $null
            }

            foreach ($policyName in $ProfileName) {
                $trimmedPolicyName = $policyName.Trim()
                $selectedItem = $items | Where-Object { $_.Name.Trim() -ieq $trimmedPolicyName }

                if (-not $selectedItem) {
                    Write-Warning "No source-tagged policy found named '$policyName'."
                    continue
                }

                if ($NewProfileName) {
                    $allCurrent = Get-AllPages -Uri "$graphRoot/deviceManagement/configurationPolicies?`$select=id,name&`$top=999"
                    $allCurrentIntents = Get-AllPages -Uri "$graphRoot/deviceManagement/intents?`$select=id,displayName&`$top=999"
                    $existingNames = @($allCurrent | ForEach-Object { $_.name }) + @($allCurrentIntents | ForEach-Object { $_.displayName })
                    
                    if ($existingNames -contains $NewProfileName) {
                        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                        $newName = "$NewProfileName - $timestamp"
                        Write-Verbose "Policy named '$NewProfileName' already exists. Using '$newName' instead."
                    } else {
                        $newName = $NewProfileName
                    }
                } else {
                    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                    $newName = "Copy of $($selectedItem.Name) - $timestamp"
                }

                try {
                    if ($selectedItem.Type -eq 'SC') {
                        if ($PSCmdlet.ShouldProcess($newName, "Clone Settings Catalog policy and apply scope tags")) {
                            Copy-SettingsCatalogPolicy -Item $selectedItem -NewName $newName -RoleScopeTagIds $tags.AllIds -GraphRoot $graphRoot
                        }
                    } elseif ($selectedItem.Type -eq 'INTENT') {
                        if ($PSCmdlet.ShouldProcess($newName, "Clone Intent policy and apply scope tags")) {
                            Copy-IntentPolicy -Item $selectedItem -NewName $newName -RoleScopeTagIds $tags.AllIds -GraphRoot $graphRoot
                        }
                    }
                } catch {
                    Write-Warning "Clone failed: $($_.Exception.Message)"
                }
            }

            Write-Information "Done." -InformationAction Continue
            return
        }

        while ($true) {
            $selectedItem = Select-ByNumber -Items $items

            if ($null -eq $selectedItem) {
                break
            }

            $currentExisting = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
            
            $allSettingsCatalog = Get-AllPages -Uri "$graphRoot/deviceManagement/configurationPolicies?`$select=id,name&`$top=999"
            foreach ($p in $allSettingsCatalog) {
                if ($p.name) { $null = $currentExisting.Add($p.name) }
            }
            
            $allIntents = Get-AllPages -Uri "$graphRoot/deviceManagement/intents?`$select=id,displayName&`$top=999"
            foreach ($i in $allIntents) {
                if ($i.displayName) { $null = $currentExisting.Add($i.displayName) }
            }

            $newName = Read-UniqueName -Default $selectedItem.Name -ExistingNames $currentExisting

            try {
                if ($selectedItem.Type -eq 'SC') {
                    if ($PSCmdlet.ShouldProcess($newName, "Clone Settings Catalog policy and apply scope tags")) {
                        Copy-SettingsCatalogPolicy -Item $selectedItem -NewName $newName -RoleScopeTagIds $tags.AllIds -GraphRoot $graphRoot
                    }
                } elseif ($selectedItem.Type -eq 'INTENT') {
                    if ($PSCmdlet.ShouldProcess($newName, "Clone Intent policy and apply scope tags")) {
                        Copy-IntentPolicy -Item $selectedItem -NewName $newName -RoleScopeTagIds $tags.AllIds -GraphRoot $graphRoot
                    }
                }
            } catch {
                Write-Warning "Clone failed: $($_.Exception.Message)"
            }

            $again = (Read-Host "Clone another? (y/n)").Trim().ToLowerInvariant()

            if ($again -notin @('y', 'yes')) {
                break
            }
        }

        Write-Information "Done." -InformationAction Continue
    }
    end {
    }
}
