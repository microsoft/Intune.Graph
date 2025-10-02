#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication, Pester

Describe 'New-IntuneConfigurationProfile' {
    
    It 'Creates a new configuration profile' {
        $settingsJson = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }
            }
        }
"@
        $settings = ConvertFrom-Json $settingsJson
        $newConfig = New-IntuneConfigurationProfile -Name "PesterTest" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 
        $newConfig | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-IntuneConfigurationProfile' {
    It 'Gets all configuration profiles' {
        Get-IntuneConfigurationProfile -All | 
            Should -Not -BeNullOrEmpty
    }

    It 'Gets a specific configuration profile' {
        Get-IntuneConfigurationProfile -Name "PesterTest" | 
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Remove-IntuneConfigurationProfile' {
    It 'Removes a configuration profile' {
        $settingsJson = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }
            }
        }
"@
        $settings = ConvertFrom-Json $settingsJson
        $newConfig = New-IntuneConfigurationProfile -Name "PesterTest" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 
        
        { Get-IntuneConfigurationProfile -Name "PesterTest" | 
            ForEach-Object { Remove-IntuneConfigurationProfile -Id $_.id  } } | 
                Should -Not -Throw
                
    }
}

Describe 'Compare-IntuneConfigurationProfileSettings' {
    
    It 'Compares two configuration profiles' {
        $settingsJson = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }   
        }         
        }
"@
        $settings = ConvertFrom-Json $settingsJson
        $newConfig = New-IntuneConfigurationProfile -Name "PesterTest" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 
        $newConfig2 = New-IntuneConfigurationProfile -Name "PesterTest2" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 

         { Compare-IntuneConfigurationProfileSettings -SourceConfigurationId $newConfig.id -DestinationConfigurationId $newConfig2.id | 
            Should -not -BeNullOrEmpty } | 
                Should -Not -Throw
    }
}

Describe "Backup-IntuneConfigurationProfile" {
    It "Backs up a configuration profile" {
        $settingsJson = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }   
        }         
        }
"@
        $settings = ConvertFrom-Json $settingsJson
        $newConfig = New-IntuneConfigurationProfile -Name "PesterTest" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 

        { Backup-IntuneConfigurationProfile -Name "PesterTest" | 
            Should -Not -BeNullOrEmpty } | 
                Should -Not -Throw
    }
}

Describe "Sync-IntuneConfigurationProfileSettings" {
    It "Syncs two configuration profiles" {
        $settingsJson = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }   
        }         
        }
"@
        $settings = ConvertFrom-Json $settingsJson
        $newConfig = New-IntuneConfigurationProfile -Name "PesterTest" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 
        $newConfig2 = New-IntuneConfigurationProfile -Name "PesterTest2" -Description "Desc" -Platform windows10 -Technologies "mdm" -RoleScopeTagIds @('0') -Settings @($settings) 

        { Sync-IntuneConfigurationProfileSettings -SourceConfigurationId $newConfig.id -DestinationConfigurationId $newConfig2.id | 
            Should -BeNullOrEmpty } | 
                Should -Not -Throw
    }
}

Describe "Backup and Restore Configuration Profile Integration Tests" {
    BeforeAll {
        # Test configuration
        $testProfileName = "IntegrationTest_ConfigProfile"
        $backupPath = "D:\ConfigProfileBackup.json"
        $testDescription = "Integration test configuration profile"
        $testPlatform = "windows10"
        $testTechnologies = "mdm"
        $testSettings = @"
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
            "settingDefinitionId": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock",
            "settingInstanceTemplateReference": null,
            "choiceSettingValue": {
                "settingValueTemplateReference": null,
                "value": "device_vendor_msft_policy_config_abovelock_allowcortanaabovelock_1",
                "children": []
            }   
        }         
        }
"@ | ConvertFrom-Json
        $testRoleScopeTagIds = @("0")
    }

    AfterAll {
        # Cleanup - Remove test profile if it exists
        $existingProfile = Get-IntuneConfigurationProfile -Name $testProfileName
        if ($existingProfile) {
            Remove-IntuneConfigurationProfile -Id $existingProfile.id
        }
        
        # Remove backup file if exists
        if (Test-Path $backupPath) {
            Remove-Item -Path $backupPath -Force
        }

        # Remove restored profile if exists
        $restoredProfile = Get-IntuneConfigurationProfile -Name "$testProfileName_Restored"
        if ($restoredProfile) {
            Remove-IntuneConfigurationProfile -Id $restoredProfile.id
        }
    }

    Context "Backup and Restore Workflow" {
        It "Should create a test configuration profile" {
            $testProfile = New-IntuneConfigurationProfile `
                -Name $testProfileName `
                -Description $testDescription `
                -Platform $testPlatform `
                -Technologies $testTechnologies `
                -Settings $testSettings `
                -RoleScopeTagIds $testRoleScopeTagIds

            $testProfile | Should -Not -BeNullOrEmpty
            $testProfile.name | Should -Be $testProfileName
        }

        It "Should backup the configuration profile" {
            $testProfile = New-IntuneConfigurationProfile `
                -Name $testProfileName `
                -Description $testDescription `
                -Platform $testPlatform `
                -Technologies $testTechnologies `
                -Settings $testSettings `
                -RoleScopeTagIds $testRoleScopeTagIds

            $testProfile | Should -Not -BeNullOrEmpty

            { Backup-IntuneConfigurationProfile -Name $testProfileName | ConvertTo-Json -Depth 50 | Out-File $backupPath } | 
                Should -Not -Throw

            Test-Path $backupPath | Should -Be $true
            $backupContent = Get-Content $backupPath | ConvertFrom-Json
            $backupContent.configurations.Count | Should -BeGreaterThan 0
            $backupContent.configurations[0].name | Should -Be $testProfileName
        }

        It "Should restore the configuration profile with Force parameter" {
            { Restore-IntuneConfigurationProfile -BackupFile $backupPath -Name $testProfileName -Force } | 
                Should -Not -Throw

            $restoredProfile = Get-IntuneConfigurationProfile -Name "$testProfileName_Restored"
            $restoredProfile | Should -Not -BeNullOrEmpty
            $restoredProfile.name | Should -Be "$testProfileName_Restored"
        }

        It "Should restore the configuration profile with Overwrite parameter" {
            { Restore-IntuneConfigurationProfile -BackupFile $backupPath -Name $testProfileName -Overwrite } | 
                Should -Not -Throw

            $restoredProfile = Get-IntuneConfigurationProfile -Name $testProfileName
            $restoredProfile | Should -Not -BeNullOrEmpty
            $restoredProfile.name | Should -Be $testProfileName
        }

        It "Should verify restored profile settings match original" {
            $restoredProfile = Get-IntuneConfigurationProfile -Name $testProfileName
            $settings = Get-IntuneConfigurationProfileSettings -Id $restoredProfile.id

            $settings | Should -Not -BeNullOrEmpty
            $settings[0].name | Should -Be $testSettings[0].displayName
            $settings[0].setting | Should -Be $testSettings[0].setting
        }
    }

    Context "Error Handling" {
        It "Should handle invalid backup file path" {
            { Restore-IntuneConfigurationProfile -BackupFile "NonExistentPath.json" } | 
                Should -Throw
        }

        It "Should handle non-existent profile name" {
            { Restore-IntuneConfigurationProfile -BackupFile $backupPath -Name "NonExistentProfile" } | 
                Should -Throw
        }

        It "Should warn when profile exists without Force or Overwrite" {
            $warning = $null
            { Restore-IntuneConfigurationProfile -BackupFile $backupPath -Name $testProfileName -WarningVariable warning } | 
                Should -Not -Throw
            $warning | Should -Not -BeNullOrEmpty
        }
    }
}