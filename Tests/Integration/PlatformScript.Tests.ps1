#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Get-IntunePlatformScript' {
    
    It 'Gets all platform scripts' {
        Get-IntunePlatformScript -All | 
            Should -Not -BeNullOrEmpty
    }

    It 'Gets a specific platform script by name' -Skip {
        # Update with actual platform script name in your tenant
        Get-IntunePlatformScript -Name "YourScriptName" | 
            Should -Not -BeNullOrEmpty
    }

    It 'Gets a platform script by id' -Skip {
        # Get an ID first
        $script = Get-IntunePlatformScript -All | Select-Object -First 1
        
        Get-IntunePlatformScript -Id $script.id | 
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Remove-IntunePlatformScript' {
    
    It 'Removes a platform script' -Skip {
        # Create a test script first (requires New-IntunePlatformScript)
        # $testScript = New-IntunePlatformScript -Name "PesterTestScript"
        
        # { Remove-IntunePlatformScript -Id $testScript.id } | 
        #     Should -Not -Throw
    }
    
    It 'Supports pipeline input' -Skip {
        # { Get-IntunePlatformScript -Name "PesterTestScript" | 
        #     Remove-IntunePlatformScript } | 
        #         Should -Not -Throw
    }
}

Describe 'Get-IntunePlatformScriptAssignments' {
    
    It 'Gets platform script assignments' -Skip {
        $script = Get-IntunePlatformScript -All | Select-Object -First 1
        
        Get-IntunePlatformScriptAssignments -Id $script.id | 
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Add-IntunePlatformScriptAssignment' {
    
    It 'Adds a platform script assignment' -Skip {
        # Requires valid script ID and group ID
        # { Add-IntunePlatformScriptAssignment -Id "scriptId" -GroupId "groupId" -IncludeExcludeGroup "include" } | 
        #     Should -Not -Throw
    }
}

Describe 'Remove-IntunePlatformScriptAssignment' {
    
    It 'Removes a platform script assignment' -Skip {
        # Requires valid script ID and group ID
        # { Remove-IntunePlatformScriptAssignment -Id "scriptId" -GroupId "groupId" } | 
        #     Should -Not -Throw
    }
}
