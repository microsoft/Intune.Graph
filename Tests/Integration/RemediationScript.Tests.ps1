#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Get-IntuneRemediationScript' {
    
    It 'Gets all remediation scripts' {
        Get-IntuneRemediationScript -All | 
            Should -Not -BeNullOrEmpty
    }

    It 'Gets a specific remediation script by name' -Skip {
        # Update with actual remediation script name in your tenant
        Get-IntuneRemediationScript -Name "YourRemediationName" | 
            Should -Not -BeNullOrEmpty
    }

    It 'Gets a remediation script by id' -Skip {
        # Get an ID first
        $script = Get-IntuneRemediationScript -All | Select-Object -First 1
        
        Get-IntuneRemediationScript -Id $script.id | 
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Remove-IntuneRemediationScript' {
    
    It 'Removes a remediation script' -Skip {
        # Create a test script first (requires New-IntuneRemediationScript)
        # $testScript = New-IntuneRemediationScript -Name "PesterTestScript"
        
        # { Remove-IntuneRemediationScript -Id $testScript.id } | 
        #     Should -Not -Throw
    }
    
    It 'Supports pipeline input' -Skip {
        # { Get-IntuneRemediationScript -Name "PesterTestScript" | 
        #     Remove-IntuneRemediationScript } | 
        #         Should -Not -Throw
    }
}

Describe 'Get-IntuneRemediationScriptAssignments' {
    
    It 'Gets remediation script assignments' -Skip {
        $script = Get-IntuneRemediationScript -All | Select-Object -First 1
        
        Get-IntuneRemediationScriptAssignments -Id $script.id | 
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Add-IntuneRemediationScriptAssignment' {
    
    It 'Adds a remediation script assignment' -Skip {
        # Requires valid script ID and group ID
        # { Add-IntuneRemediationScriptAssignment -Id "scriptId" -GroupId "groupId" -IncludeExcludeGroup "include" } | 
        #     Should -Not -Throw
    }
}

Describe 'Remove-IntuneRemediationScriptAssignment' {
    
    It 'Removes a remediation script assignment' -Skip {
        # Requires valid script ID and group ID
        # { Remove-IntuneRemediationScriptAssignment -Id "scriptId" -GroupId "groupId" } | 
        #     Should -Not -Throw
    }
}
