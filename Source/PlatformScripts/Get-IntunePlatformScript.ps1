<#
.SYNOPSIS
    Gets Intune platform scripts (device management scripts).

.DESCRIPTION
    Retrieves a single platform script or a list of platform scripts from Intune.

.PARAMETER Name
    The name of the platform script to retrieve. Uses case-insensitive partial match.

.PARAMETER Id
    The id of the platform script to retrieve.

.PARAMETER All
    Return all platform scripts.

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    Get-IntunePlatformScript -All

    Gets all platform scripts.

.EXAMPLE
    Get-IntunePlatformScript -Name "Windows Update"

    Gets platform scripts with names containing "Windows Update".

.EXAMPLE
    Get-IntunePlatformScript -Id "00000000-0000-0000-0000-000000000000"

    Gets a platform script by id.

.EXAMPLE
    Get-IntunePlatformScript -All -Environment USGov

    Gets all platform scripts in the USGov environment.
#>

function Get-IntunePlatformScript {
    param (
        [Parameter(Mandatory, ParameterSetName="Name", Position=0)]
        [string]$Name,
        
        [Parameter(Mandatory, ParameterSetName="Id", Position=1)]
        [string]$Id,
        
        [Parameter(ParameterSetName="Name")]
        [Parameter(ParameterSetName="Id")]
        [Parameter(ParameterSetName="All")]
        [ValidateSet("Global", "USGov", "USGovDoD")]
        [string]$Environment="Global",
        
        [Parameter(ParameterSetName="All")]
        [switch]$All
    )

    begin {
        if($false -eq (Initialize-IntuneAccess -Scopes @("DeviceManagementConfiguration.Read.All") -Modules @("Microsoft.Graph.Authentication") -Environment $Environment)) {
            return
        }
        
        switch ($Environment) {
            "USGov" { $uri = "https://graph.microsoft.us" }
            "USGovDoD" { $uri = "https://dod-graph.microsoft.us" }
            Default { $uri = "https://graph.microsoft.com" }
        }

        $graphVersion = "beta"

        if($PSBoundParameters.Count -eq 0) {
            $All = $true
        }
    }

    process {
        if($All) {
            $scripts = @()
            $requestUri = "$uri/$graphVersion/deviceManagement/deviceManagementScripts"
            do {
                $response = Invoke-MgRestMethod -Method Get -Uri $requestUri -OutputType Json | ConvertFrom-Json
                $scripts += $response.value
                $requestUri = $response.'@odata.nextLink'
            } while ($null -ne $requestUri)

            return $scripts
        }

        if($Name) {
            $scripts = @()
            $requestUri = "$uri/$graphVersion/deviceManagement/deviceManagementScripts"
            do {
                $response = Invoke-MgRestMethod -Method Get -Uri $requestUri -OutputType Json | ConvertFrom-Json
                $scripts += $response.value
                $requestUri = $response.'@odata.nextLink'
            } while ($null -ne $requestUri)

            $scriptsFilteredByName = @()
            foreach($script in $scripts) {
                $scriptName = if([string]::IsNullOrWhiteSpace($script.displayName)) { $script.name } else { $script.displayName }
                if($scriptName -like "*$Name*") {
                    $scriptsFilteredByName += $script
                }
            }

            return $scriptsFilteredByName
        }

        if($Id) {
            $response = Invoke-MgRestMethod -Method Get -Uri "$uri/$graphVersion/deviceManagement/deviceManagementScripts/$Id" -OutputType Json | ConvertFrom-Json
            return $response
        }
    }
}
