<#
.SYNOPSIS
    Removes an Intune remediation script.

.DESCRIPTION
    Removes an Intune remediation script (proactive remediation).

.PARAMETER Id
    The id of the remediation script to remove.

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    Remove-IntuneRemediationScript -Id "00000000-0000-0000-0000-000000000000"

    Removes a remediation script.

.EXAMPLE
    Remove-IntuneRemediationScript -Id "00000000-0000-0000-0000-000000000000" -Environment USGov

    Removes a remediation script in the USGov environment.

.EXAMPLE
    Get-IntuneRemediationScript -Name "Old Script" | ForEach-Object { Remove-IntuneRemediationScript -Id $_.id }

    Removes all remediation scripts matching "Old Script".
#>

function Remove-IntuneRemediationScript {
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
        Invoke-MgRestMethod -Method Delete -Uri "$uri/$graphVersion/deviceManagement/deviceHealthScripts/$Id" | Out-Null
    }
}
