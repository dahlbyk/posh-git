. $PSScriptRoot\Shared.ps1

Describe 'ParamsTabExpansion Azure CLI Tests' {

    Context 'Push Parameters TabExpansion Tests' {
        # Create a git alias for 'pr', as if we'd installed az-cli
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo

            # Test with non-standard vsts pr alias name
            &$gitbin config alias.test-az-pr "!f() { exec az.cmd repos pr \`"`$`@\`"; }; f"
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
        }

        It 'Tab completes empty for git pr oops parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr oops --'
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes empty for git pr oops short parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr oops -'
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes empty for git pr update --**= ' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr update --**='
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes git pr create parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr create --'
            $result -contains '--auto-complete' | Should Be $true
        }

        It 'Tab completes git pr create auto-complete parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr create --auto-complete --'
            $result -contains '--delete-source-branch' | Should Be $true
        }

        It 'Tab completes git pr show all parameters values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr show --'
            $result -contains '--' | Should Be $false
            $result -contains '--debug' | Should Be $true
            $result -contains '--help' | Should Be $true
            $result -contains '--output' | Should Be $true
            $result -contains '--query' | Should Be $true
            $result -contains '--verbose' | Should Be $true
            $result -contains '--id' | Should Be $true
            $result -contains '--detect' | Should Be $true
            $result -contains '--open' | Should Be $true
            $result -contains '--organization' | Should Be $true
            $result -contains '--instance' | Should Be $false
        }

        It 'Tab completes git pr create all short parameters' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr create -'
            $result -contains '-d' | Should Be $true
            $result -contains '-i' | Should Be $false
            $result -contains '-p' | Should Be $true
            $result -contains '-r' | Should Be $true
            $result -contains '-s' | Should Be $true
            $result -contains '-t' | Should Be $true
            $result -contains '-h' | Should Be $true
            $result -contains '-o' | Should Be $true
        }

        It 'Tab completes git pr reviewer add all parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr reviewer add --'
            $result -contains '--' | Should Be $false
            $result -contains '--id' | Should Be $true
            $result -contains '--detect' | Should Be $true
            $result -contains '--instance' | Should Be $false
            $result -contains '--reviewers' | Should Be $true
        }

        It 'Tab completes git pr work-item list all short parameters' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr work-item list -'
            $result -contains '-i' | Should Be $false
            $result -contains '-h' | Should Be $true
            $result -contains '-o' | Should Be $true
        }

        It 'Tab completes git pr list --output types' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr list --output '
            $result -contains 'json' | Should Be $true
            $result -contains 'jsonc' | Should Be $true
            $result -contains 'table' | Should Be $true
            $result -contains 'tsv' | Should Be $true
        }

        It 'Tab completes git pr policy list -o types' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr policy list -o '
            $result -contains 'json' | Should Be $true
            $result -contains 'jsonc' | Should Be $true
            $result -contains 'table' | Should Be $true
            $result -contains 'tsv' | Should Be $true
        }

        It 'Tab completes git pr reviewers list --output= types' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr reviewer list --output='
            $result -contains '--output=' | Should Be $false
            $result -contains '--output=json' | Should Be $true
            $result -contains '--output=jsonc' | Should Be $true
            $result -contains '--output=table' | Should Be $true
            $result -contains '--output=tsv' | Should Be $true
        }

        It 'Tab completes git pr update --status= types' {
            $result = & $module GitTabExpansionInternal 'git test-az-pr update --status='
            $result -contains '--status=abandoned' | Should Be $true
            $result -contains '--status=active' | Should Be $true
            $result -contains '--status=completed' | Should Be $true
        }

        # need to mock gitRemoteUniqueBranches
        InModuleScope 'posh-git' {

            Mock gitRemoteUniqueBranches { return 'master' } -ParameterFilter {   $filter -eq 'm' }
            Mock gitRemoteUniqueBranches { return 'develop','master' } -ParameterFilter { $filter -eq '' }

            It 'Tab completes git pr create --target-branch partial branch names' {
                $result = GitTabExpansionInternal 'git test-az-pr create --target-branch m'
                $result -contains 'develop' | Should Be $false
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create -t branch names' {
                $result = GitTabExpansionInternal 'git test-az-pr create -t '

                $result -contains 'develop' | Should Be $true
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create -s branch names' {
                $result = GitTabExpansionInternal 'git test-az-pr create -s m'

                $result -contains 'develop' | Should Be $false
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create --source-branch branch names' {
                $result = GitTabExpansionInternal 'git test-az-pr create --source-branch '
                $result -contains 'develop' | Should Be $true
                $result -contains 'master' | Should Be $true
            }
        }
    }
}
