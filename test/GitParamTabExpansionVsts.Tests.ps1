. $PSScriptRoot\Shared.ps1

Describe 'ParamsTabExpansion VSTS Tests' {
    Context 'Push Parameters TabExpansion Tests' {
        # Create a git alias for 'pr', as if we'd installed vsts-cli
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo

            # Test with non-standard vsts pr alias name
            &$gitbin config alias.test-vsts-pr "!f() { exec vsts code pr \`"`$`@\`"; }; f"
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
        }

        It 'Tab completes empty for git pr oops parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr oops --'
            $result | Should Be @()
        }

        It 'Tab completes empty for git pr oops short parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr oops -'
            $result | Should Be @()
        }

        It 'Tab completes git pr create parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create --'
            $result -contains '--auto-complete' | Should Be $true
        }
        It 'Tab completes git pr create auto-complete parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create --auto-complete --'
            $result -contains '--delete-source-branch' | Should Be $true
        }

        It 'Tab completes git pr show all parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr show --'
            $result -contains '--' | Should Be $false
            $result -contains '--debug' | Should Be $true
            $result -contains '--help' | Should Be $true
            $result -contains '--output' | Should Be $true
            $result -contains '--query' | Should Be $true
            $result -contains '--verbose' | Should Be $true
        }

        It 'Tab completes git pr create all short push parameters' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create -'
            $result -contains '-d' | Should Be $true
            $result -contains '-i' | Should Be $true
            $result -contains '-p' | Should Be $true
            $result -contains '-r' | Should Be $true
            $result -contains '-s' | Should Be $true
            $result -contains '-h' | Should Be $true
            $result -contains '-o' | Should Be $true
        }
    }
}
