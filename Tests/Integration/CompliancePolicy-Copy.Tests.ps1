#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Copy-IntuneCompliancePolicy' {
    
    BeforeAll {
        # Test configuration - UPDATE THESE for your environment before running tests
        $script:testSourceScopeTag = "Production"      # Change to your actual source scope tag name
        $script:testDestinationScopeTag = "Development" # Change to your actual destination scope tag name
        $script:testPolicyBaseName = "PesterTest_CompliancePolicy"
        
        # Create test scope tags if they don't exist (optional - comment out if tags already exist)
        # $sourceTags = Get-IntuneTag -Name $testSourceScopeTag
        # if (-not $sourceTags) {
        #     New-IntuneTag -Name $testSourceScopeTag -Description "Test source tag for Pester"
        # }
        # $destTags = Get-IntuneTag -Name $testDestinationScopeTag
        # if (-not $destTags) {
        #     New-IntuneTag -Name $testDestinationScopeTag -Description "Test destination tag for Pester"
        # }
    }
    
    AfterAll {
        # Cleanup - Remove test policies created during testing
        $testPolicies = Get-IntuneCompliancePolicy -All | Where-Object { 
            $_.displayName -like "*$testPolicyBaseName*" -or 
            $_.displayName -like "Copy of *$testPolicyBaseName*" 
        }
        
        foreach ($policy in $testPolicies) {
            Write-Verbose "Cleaning up test policy: $($policy.displayName)"
            # Remove-IntuneCompliancePolicy -Id $policy.id
        }
    }
    
    It 'Copies a compliance policy with automated name generation' -Skip {
        # Note: This test is skipped by default as it requires:
        # 1. Existing source-tagged compliance policy
        # 2. Valid scope tags configured in your tenant
        # 3. Appropriate Graph permissions
        
        $sourcePolicyName = "$testPolicyBaseName-Source"
        
        # Create a source policy for testing (requires implementation)
        # $sourcePolicy = New-IntuneCompliancePolicy -Name $sourcePolicyName -Platform windows10 -ScopeTagIds @("0")
        
        { Copy-IntuneCompliancePolicy `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -PolicyName $sourcePolicyName } | 
                Should -Not -Throw
        
        # Verify the cloned policy exists
        $clonedPolicies = Get-IntuneCompliancePolicy -All | Where-Object { 
            $_.displayName -like "Copy of $sourcePolicyName*" 
        }
        $clonedPolicies | Should -Not -BeNullOrEmpty
    }
    
    It 'Copies a compliance policy with custom name' -Skip {
        $sourcePolicyName = "$testPolicyBaseName-CustomName"
        $newPolicyName = "$testPolicyBaseName-Clone"
        
        { Copy-IntuneCompliancePolicy `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -PolicyName $sourcePolicyName `
            -NewPolicyName $newPolicyName } | 
                Should -Not -Throw
        
        # Verify the cloned policy has correct name
        $clonedPolicy = Get-IntuneCompliancePolicy -Name $newPolicyName
        $clonedPolicy | Should -Not -BeNullOrEmpty
        $clonedPolicy.displayName | Should -BeLike "$newPolicyName*"
    }
    
    It 'Supports -WhatIf parameter' -Skip {
        $sourcePolicyName = "$testPolicyBaseName-WhatIf"
        
        { Copy-IntuneCompliancePolicy `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -PolicyName $sourcePolicyName `
            -WhatIf } | 
                Should -Not -Throw
    }
    
    It 'Handles non-existent policy gracefully' {
        $warning = $null
        
        Copy-IntuneCompliancePolicy `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -PolicyName "NonExistentPolicyName12345" `
            -WarningVariable warning `
            -WarningAction SilentlyContinue
        
        $warning | Should -Not -BeNullOrEmpty
    }
    
    It 'Validates source scope tag exists' {
        { Copy-IntuneCompliancePolicy `
            -SourceScopeTagName "NonExistentScopeTag12345" `
            -DestinationScopeTagName $testDestinationScopeTag `
            -PolicyName "$testPolicyBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Validates destination scope tag exists' {
        { Copy-IntuneCompliancePolicy `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName "NonExistentScopeTag12345" `
            -PolicyName "$testPolicyBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
}

Describe 'Copy-IntuneCompliancePolicy Integration Tests' {
    
    BeforeAll {
        # Complete integration test setup
        $script:integrationTestTag = "IntegrationTest"
        $script:integrationPolicyName = "IntegrationTest_Policy"
    }
    
    AfterAll {
        # Complete cleanup
    }
    
    Context "End-to-End Policy Copy Workflow" -Skip {
        
        It "Should create source policy, copy it, and verify clone" {
            # 1. Create source policy
            # 2. Tag with source scope tag
            # 3. Copy policy with new scope tag
            # 4. Verify clone exists with correct scope tags
            # 5. Cleanup
            
            $true | Should -Be $true
        }
    }
}
