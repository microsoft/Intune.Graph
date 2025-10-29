#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'Copy-IntunePlatformScript' {
    
    BeforeAll {
        $script:testSourceScopeTag = "Production"
        $script:testDestinationScopeTag = "Development"
        $script:testScriptBaseName = "PesterTest_PlatformScript"
    }
    
    It 'Handles non-existent platform script gracefully' {
        $warning = $null
        
        Copy-IntunePlatformScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ScriptName "NonExistentScriptName12345" `
            -WarningVariable warning `
            -WarningAction SilentlyContinue
        
        $warning | Should -Not -BeNullOrEmpty
    }
    
    It 'Validates source scope tag exists' {
        { Copy-IntunePlatformScript `
            -SourceScopeTagName "NonExistentScopeTag12345" `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ScriptName "$testScriptBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Validates destination scope tag exists' {
        { Copy-IntunePlatformScript `
            -SourceScopeTagName $testSourceScopeTag `
            -DestinationScopeTagName "NonExistentScopeTag12345" `
            -ScriptName "$testScriptBaseName-Test" } | 
                Should -Throw "*scope tag*not found*"
    }
    
    It 'Enforces single source scope tag' {
        { Copy-IntunePlatformScript `
            -SourceScopeTagName @("Tag1", "Tag2") `
            -DestinationScopeTagName $testDestinationScopeTag `
            -ScriptName "Test" } | 
                Should -Throw
    }
}
