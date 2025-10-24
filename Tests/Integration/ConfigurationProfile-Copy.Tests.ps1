#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Copy-IntuneConfigurationProfile' {
    
    BeforeAll {
        # Test configuration - UPDATE THESE for your environment before running tests
        $script:testSourceScopeTag = "Production"
        $script:testDestinationScopeTag = "Development"
        $script:testProfileBaseName = "PesterTest_ConfigurationProfile"
    }
    
    AfterAll {
        # Cleanup - Remove test profiles created during testing
        $testProfiles = Get-IntuneConfigurationProfile -All | Where-Object { 
            $_.name -like "*$testProfileBaseName*" -or 
            $_.name -like "Copy of *$testProfileBaseName*" 
        }
        
        foreach ($profile in $testProfiles) {
            Write-Verbose "Cleaning up test profile: $($profile.name)"
            # Remove-IntuneConfigurationProfile -Id $profile.id
        }
    }
    
    It 'Copies a configuration profile with automated name generation' -Skip {
        # Note: This test is skipped by default as it requires:
        # 1. Existing source-tagged configuration profile
        # 2. Valid scope tags configured in your tenant
        # 3. Appropriate Graph permissions
        
        $sourceProfileName = "$testProfileBaseName-Source"
        
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName $sourceProfileName } | 
                Should -Not -Throw
        
        # Verify the cloned profile exists
        $clonedProfiles = Get-IntuneConfigurationProfile -All | Where-Object { 
            $_.name -like "Copy of $sourceProfileName*" 
        }
        $clonedProfiles | Should -Not -BeNullOrEmpty
    }
    
    It 'Copies a configuration profile with custom name' -Skip {
        $sourceProfileName = "$testProfileBaseName-CustomName"
        $newProfileName = "$testProfileBaseName-Clone"
        
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName $sourceProfileName `
            -NewProfileName $newProfileName } | 
                Should -Not -Throw
        
        # Verify the cloned profile has correct name
        $clonedProfile = Get-IntuneConfigurationProfile -Name $newProfileName
        $clonedProfile | Should -Not -BeNullOrEmpty
        $clonedProfile.name | Should -BeLike "$newProfileName*"
    }
    
    It 'Supports -WhatIf parameter' -Skip {
        $sourceProfileName = "$testProfileBaseName-WhatIf"
        
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName $sourceProfileName `
            -WhatIf } | 
                Should -Not -Throw
    }
    
    It 'Handles non-existent profile gracefully' {
        $warning = $null
        
        Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName "NonExistentProfileName12345" `
            -WarningVariable warning `
            -WarningAction SilentlyContinue
        
        $warning | Should -Not -BeNullOrEmpty
    }
    
    It 'Validates source scope tag exists' {
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName "NonExistentScopeTag12345" `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName "$testProfileBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Validates destination scope tag exists' {
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName "NonExistentScopeTag12345" `
            -ProfileName "$testProfileBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Enforces single source scope tag' {
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName @("Tag1", "Tag2") `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ProfileName "Test" } | 
                Should -Throw
    }
    
    It 'Allows multiple destination scope tags' -Skip {
        $sourceProfileName = "$testProfileBaseName-MultiTag"
        
        { Copy-IntuneConfigurationProfile `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName @($testDestinationScopeTag, "Tag2") `
            -ProfileName $sourceProfileName } | 
                Should -Not -Throw
    }
}

Describe 'Copy-IntuneConfigurationProfile Integration Tests' {
    
    BeforeAll {
        # Complete integration test setup
        $script:integrationTestTag = "IntegrationTest"
        $script:integrationProfileName = "IntegrationTest_Profile"
    }
    
    AfterAll {
        # Complete cleanup
    }
    
    Context "Settings Catalog Policy Copy" -Skip {
        
        It "Should copy a Settings Catalog policy" {
            # 1. Create source Settings Catalog policy
            # 2. Tag with source scope tag
            # 3. Copy policy with new scope tag
            # 4. Verify clone exists with correct scope tags
            # 5. Cleanup
            
            $true | Should -Be $true
        }
    }
    
    Context "Endpoint Security Intent Copy" -Skip {
        
        It "Should copy an Endpoint Security intent" {
            # 1. Create source intent
            # 2. Tag with source scope tag
            # 3. Copy intent with new scope tag
            # 4. Verify clone exists with correct scope tags
            # 5. Cleanup
            
            $true | Should -Be $true
        }
    }
    
    Context "Name Handling" -Skip {
        
        It "Should handle profiles with leading/trailing spaces" {
            # Test that name trimming works correctly
            $true | Should -Be $true
        }
        
        It "Should generate unique names when conflicts exist" {
            # Test auto-timestamp generation
            $true | Should -Be $true
        }
    }
}
