<#
.SYNOPSIS
    Restores Intune configuration profiles from a backup.

.DESCRIPTION
    Restores Intune configuration profiles from a backup JSON file. Can restore all profiles or specific ones by name.
    Supports overwriting existing profiles or forcing creation of new ones.

.PARAMETER BackupFile
    The path to the backup JSON file.

.PARAMETER Name
    The name of the configuration profile to restore. This is case sensitive.

.PARAMETER Force
    Forces creation of new profiles even if they already exist.

.PARAMETER Overwrite
    Overwrites existing profiles if they exist.

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    # Restore all configuration profiles from backup, creating new ones
    Restore-IntuneConfigurationProfile -BackupFile "backup.json" -Force

.EXAMPLE
    # Restore all configuration profiles from backup, overwriting existing ones
    Restore-IntuneConfigurationProfile -BackupFile "backup.json" -Overwrite

.EXAMPLE
    # Restore specific configuration profile by name
    Restore-IntuneConfigurationProfile -BackupFile "backup.json" -Name "MyProfile" -Force

.EXAMPLE
    # Restore specific configuration profile by name in USGov environment
    Restore-IntuneConfigurationProfile -BackupFile "backup.json" -Name "MyProfile" -Force -Environment USGov
#>
function Restore-IntuneConfigurationProfile {
    [CmdletBinding(DefaultParameterSetName="All")]
    param(
        [Parameter(Mandatory)]
        [string]$BackupFile,
        
        [Parameter(ParameterSetName="ByName")]
        [string]$Name,
        
        [Parameter(ParameterSetName="All")]
        [Parameter(ParameterSetName="ByName")]
        [switch]$Force,
        
        [Parameter(ParameterSetName="All")]
        [Parameter(ParameterSetName="ByName")]
        [switch]$Overwrite,
        
        [ValidateSet("Global", "USGov", "USGovDoD")]
        [string]$Environment="Global"
    )

    begin {
        $scopes = @(
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementRBAC.ReadWrite.All"
        )
        
        if($false -eq (Initialize-IntuneAccess -Scopes $scopes -Modules @("Microsoft.Graph.Authentication") -Environment $Environment)) {
            return
        }
    }

    process {
        # Read backup file
        try {
            $backup = Get-Content -Path $BackupFile -Raw | ConvertFrom-Json
        }
        catch {
            Write-Error "Failed to read backup file: $_"
            return
        }

        # Filter configurations based on parameters
        $configurations = $backup.configurations
        if($Name) {
            $configurations = $configurations | Where-Object { $_.name -eq $Name }
            if(-not $configurations) {
                Write-Error "No configuration profile found with name: $Name"
                return
            }
        }

        foreach($configuration in $configurations) {
            # Check if profile already exists
            $existingProfile = Get-IntuneConfigurationProfile -Name $configuration.name -Environment $Environment
            
            if($existingProfile) {
                if($Force) {
                    # Skip and create new
                    $configuration.name = "$($configuration.name)_Restored"
                }
                elseif($Overwrite) {
                    # Remove existing profile
                    Remove-IntuneConfigurationProfile -Id $existingProfile.id -Environment $Environment
                }
                else {
                    Write-Warning "Profile '$($configuration.name)' already exists. Use -Force to create new or -Overwrite to replace."
                    continue
                }
            }

            # Create new configuration profile
            $newProfile = New-IntuneConfigurationProfile `
                -Name $configuration.name `
                -Description $configuration.description `
                -Platform $configuration.platforms `
                -Technologies $configuration.technologies `
                -Settings $configuration.settings `
                -RoleScopeTagIds $configuration.roleScopeTagIds `
                -Environment $Environment

            # Check if all filters exist
            if($configuration.filters) {
                foreach($filter in $configuration.filters) {
                    $existingFilter = Get-IntuneFilter -Name $filter.name -Environment $Environment

                    if(-not $existingFilter) {
                        New-IntuneFilter `
                            -Name $filter.displayName `
                            -Description $filter.description `
                            -Platform $filter.platform `
                            -Rule $filter.rule `
                            -RoleScopeTagIds $filter.roleScopeTags `
                            -Environment $Environment
                    }
                }
            }
            
            if($newProfile) {
                # Restore assignments if they exist
                if($configuration.assignments) {
                    foreach($assignment in $configuration.assignments) {
                        

                        Add-IntuneConfigurationProfileAssignment `
                            -Id $newProfile.id `
                            -AssignmentObject $assignment `
                            -Environment $Environment
                    }
                }

                # Restore tags if they exist
                if($configuration.tags) {
                    foreach($tag in $configuration.tags) {
                        # Check if tag already exists using Get-IntuneTag
                        $existingTag = Get-IntuneTag -Name $tag.name -Environment $Environment

                        if(-not $existingTag) {
                            New-IntuneTag `
                                -Name $tag.name `
                                -Description $tag.description `
                                -Environment $Environment
                        }
                    }
                }

                Write-Output "Restored configuration profile: $($configuration.name)"
            }
        }
    }
}