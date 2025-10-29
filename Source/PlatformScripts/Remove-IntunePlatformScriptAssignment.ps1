# Write the comment-based HELP for Remove-IntunePlatformScriptAssignment
<#
.SYNOPSIS
    Removes an Intune platform script assignment.

.DESCRIPTION
    Removes an Intune platform script assignment.

.PARAMETER Id
    The id of the platform script to remove assignment from.

.PARAMETER GroupId
    The id of the group to remove the platform script assignment from.

.PARAMETER Environment
    The environment to connect to. Valid values are Global, USGov, USGovDoD. Default is Global.

.EXAMPLE
    # Remove a platform script assignment.
    Remove-IntunePlatformScriptAssignment -Id "00000000-0000-0000-0000-000000000000" -GroupId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    # Remove a platform script assignment in the USGov environment.
    Remove-IntunePlatformScriptAssignment -Id "00000000-0000-0000-0000-000000000000" -GroupId "00000000-0000-0000-0000-000000000000" -Environment USGov
#>

function Remove-IntunePlatformScriptAssignment
{
    param (     
        [Parameter(Mandatory, ParameterSetName="Group", Position=0, HelpMessage="platform script Id")]
        [Parameter(Mandatory, ParameterSetName="PSObject", Position=0, HelpMessage="platform script Id")]
        [ValidateScript({$GUIDRegex = "^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$";If ($_ -match $GUIDRegex){return $true}throw "'$_': This is not a valid GUID format"})]
        [string]$Id,   
        [Parameter(Mandatory, ParameterSetName="Group", Position=1)]
        [ValidateScript({$GUIDRegex = "^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$";If ($_ -match $GUIDRegex){return $true}throw "'$_': This is not a valid GUID format"})]
        [string]$GroupId,
        [Parameter(ParameterSetName="Group")]
        [Parameter(ParameterSetName="PSObject")]
        [ValidateSet("Global", "USGov", "USGovDoD")]
        [string]$Environment="Global"
    )
    begin 
    {
        if($false -eq (Initialize-IntuneAccess -Scopes @("DeviceManagementConfiguration.ReadWrite.All") -Modules @("Microsoft.Graph.Authentication") -Environment $Environment))
        {
            return
        }
        
        if($PSBoundParameters.ContainsKey("GroupId"))
        {
            $groupId = $GroupId
        }
        else 
        {
            $groupId = $Id
        }

        switch ($Environment) {
            "USGov" { $uri = "https://graph.microsoft.us" }
            "USGovDoD" { $uri = "https://dod-graph.microsoft.us" }
            Default { $uri = "https://graph.microsoft.com" }
        }
        $graphVersion = "beta"
    }
    process
    {

        $Assignments = Get-IntunePlatformScriptAssignments -Id $id -Environment $Environment
        $updatedAssignmentArray = @()

        ForEach($assignment in $Assignments){

            If ($Assignment.target.groupId -ne $groupID){

                If ([string]::IsNullOrEmpty($Assignment.target.deviceAndAppManagementAssignmentFilterType) -eq $FALSE){

                    $targetGroup = [PSCustomObject]@{

                        target = [PSCustomObject]@{
                            "@odata.type" = $Assignment.target.'@odata.type'
                            deviceAndAppManagementAssignmentFilterId = $Assignment.target.deviceAndAppManagementAssignmentFilterId
                            deviceAndAppManagementAssignmentFilterType = $Assignment.target.deviceAndAppManagementAssignmentFilterType
                            groupId = $Assignment.target.groupId

                        }
                    }  

                }Else{

                    $targetGroup = [PSCustomObject]@{

                        target = [PSCustomObject]@{
                            "@odata.type" = $Assignment.target.'@odata.type'
                            groupId = $Assignment.target.groupId
                        }
                    }

                }
                
                $updatedAssignmentArray += $TargetGroup   

            }
        
        }

        $body = @{
            deviceManagementScriptAssignments = $updatedAssignmentArray
        }

        $response = Invoke-MgRestMethod -Method POST -Uri "$uri/$graphVersion/deviceManagement/deviceManagementScripts('$Id')/assign" -Body ($body | ConvertTo-Json -Depth 50) -ContentType "application/json" -OutputType Json | ConvertFrom-Json
        return $response

    }

}
