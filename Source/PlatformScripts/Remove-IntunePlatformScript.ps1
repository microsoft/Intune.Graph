<#
.SYNOPSIS
    Removes an Intune platform script.

.DESCRIPTION
    Removes an Intune platform script (device management script).

.PARAMETER Id
    The id of the platform script to remove.

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    Remove-IntunePlatformScript -Id "00000000-0000-0000-0000-000000000000"

    Removes a platform script.

.EXAMPLE
    Remove-IntunePlatformScript -Id "00000000-0000-0000-0000-000000000000" -Environment USGov

    Removes a platform script in the USGov environment.

.EXAMPLE
    Get-IntunePlatformScript -Name "Old Script" | ForEach-Object { Remove-IntunePlatformScript -Id $_.id }

    Removes all platform scripts matching "Old Script".
#>

function Remove-IntunePlatformScript {
    param (
        [Parameter(Mandatory, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName="id")]
        [string]$Id,
        
        [ValidateSet("Global", "USGov", "USGovDoD")]
        [string]$Environment="Global"
    )
    
    begin {
        if($false -eq (Initialize-IntuneAccess -Scopes @("DeviceManagementConfiguration.ReadWrite.All") -Modules @("Microsoft.Graph.Authentication") -Environment $Environment)) {
            return
        }
        
        switch ($Environment) {
            "USGov" { $uri = "https://graph.microsoft.us" }
            "USGovDoD" { $uri = "https://dod-graph.microsoft.us" }
            Default { $uri = "https://graph.microsoft.com" }
        }
        
        $graphVersion = "beta"
    }
    
    process {
        Invoke-MgRestMethod -Method Delete -Uri "$uri/$graphVersion/deviceManagement/deviceManagementScripts/$Id" | Out-Null
    }
}
