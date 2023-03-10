BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

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
            $result | Should -Be @()
        }

        It 'Tab completes empty for git pr oops short parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr oops -'
            $result | Should -Be @()
        }

        It 'Tab completes git pr create parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create --'
            $result | Should -Contain '--auto-complete'
        }
        It 'Tab completes git pr create auto-complete parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create --auto-complete --'
            $result | Should -Contain '--delete-source-branch'
        }

        It 'Tab completes git pr show all parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr show --'
            $result | Should -Not -Contain '--'
            $result | Should -Contain '--debug'
            $result | Should -Contain '--help'
            $result | Should -Contain '--output'
            $result | Should -Contain '--query'
            $result | Should -Contain '--verbose'
        }

        It 'Tab completes git pr create all short push parameters' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create -'
            $result | Should -Contain '-d'
            $result | Should -Contain '-i'
            $result | Should -Contain '-p'
            $result | Should -Contain '-r'
            $result | Should -Contain '-s'
            $result | Should -Contain '-h'
            $result | Should -Contain '-o'
        }
    }
}
