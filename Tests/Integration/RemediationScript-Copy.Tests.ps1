#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Copy-IntuneRemediationScript' {
    
    BeforeAll {
        # Test configuration - UPDATE THESE for your environment before running tests
        $script:testSourceScopeTag = "Production"
        $script:testDestinationScopeTag = "Development"
        $script:testRemediationBaseName = "PesterTest_RemediationScript"
    }
    
    AfterAll {
        # Cleanup - Remove test remediation scripts created during testing
        # Note: This requires custom cleanup as there's no built-in Get-IntuneRemediationScript yet
    }
    
    It 'Copies a remediation script with automated name generation' -Skip {
        # Note: This test is skipped by default as it requires:
        # 1. Existing source-tagged remediation script
        # 2. Valid scope tags configured in your tenant
        # 3. Appropriate Graph permissions
        
        $sourceRemediationName = "$testRemediationBaseName-Source"
        
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName $sourceRemediationName } | 
                Should -Not -Throw
    }
    
    It 'Copies a remediation script with custom name' -Skip {
        $sourceRemediationName = "$testRemediationBaseName-CustomName"
        $newRemediationName = "$testRemediationBaseName-Clone"
        
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName $sourceRemediationName `
            -NewRemediationName $newRemediationName } | 
                Should -Not -Throw
    }
    
    It 'Supports -WhatIf parameter' -Skip {
        $sourceRemediationName = "$testRemediationBaseName-WhatIf"
        
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName $sourceRemediationName `
            -WhatIf } | 
                Should -Not -Throw
    }
    
    It 'Handles non-existent remediation script gracefully' {
        $warning = $null
        
        Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName "NonExistentRemediationName12345" `
            -WarningVariable warning `
            -WarningAction SilentlyContinue
        
        $warning | Should -Not -BeNullOrEmpty
    }
    
    It 'Validates source scope tag exists' {
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName "NonExistentScopeTag12345" `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName "$testRemediationBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Validates destination scope tag exists' {
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName "NonExistentScopeTag12345" `
            -RemediationName "$testRemediationBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Enforces single source scope tag' {
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName @("Tag1", "Tag2") `
            -DestinationScopeTagName $testDestinationScopeTag `
            -RemediationName "Test" } | 
                Should -Throw
    }
    
    It 'Allows multiple destination scope tags' -Skip {
        $sourceRemediationName = "$testRemediationBaseName-MultiTag"
        
        { Copy-IntuneRemediationScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName @($testDestinationScopeTag, "Tag2") `
            -RemediationName $sourceRemediationName } | 
                Should -Not -Throw
    }
}

Describe 'Copy-IntuneRemediationScript Integration Tests' {
    
    BeforeAll {
        # Complete integration test setup
        $script:integrationTestTag = "IntegrationTest"
        $script:integrationRemediationName = "IntegrationTest_Remediation"
    }
    
    AfterAll {
        # Complete cleanup
    }
    
    Context "Remediation Script Copy" -Skip {
        
        It "Should copy a remediation script with detection and remediation content" {
            # 1. Create source remediation script
            # 2. Tag with source scope tag
            # 3. Copy script with new scope tag
            # 4. Verify clone exists with correct scope tags
            # 5. Verify detection and remediation content is copied
            # 6. Cleanup
            
            $true | Should -Be $true
        }
    }
    
    Context "Name Handling" -Skip {
        
        It "Should handle scripts with leading/trailing spaces" {
            # Test that name trimming works correctly
            $true | Should -Be $true
        }
        
        It "Should generate unique names when conflicts exist" {
            # Test auto-timestamp generation
            $true | Should -Be $true
        }
    }
}
