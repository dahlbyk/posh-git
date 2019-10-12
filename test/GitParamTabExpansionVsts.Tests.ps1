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
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes empty for git pr oops short parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr oops -'
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes empty for git pr set-vote --**= ' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr set-vote --**='
            $result | Should BeNullOrEmpty
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
            $result -contains '--id' | Should Be $true
            $result -contains '--detect' | Should Be $true
            $result -contains '--open' | Should Be $true
            $result -contains '--organization' | Should Be $false
            $result -contains '--instance' | Should Be $true
        }

        It 'Tab completes git pr create all short parameters' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr create -'
            $result -contains '-d' | Should Be $true
            $result -contains '-i' | Should Be $true
            $result -contains '-p' | Should Be $true
            $result -contains '-r' | Should Be $true
            $result -contains '-s' | Should Be $true
            $result -contains '-t' | Should Be $true
            $result -contains '-h' | Should Be $true
            $result -contains '-o' | Should Be $true
        }

        It 'Tab completes git pr reviewers add all parameter values' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr reviewers add --'
            $result -contains '--' | Should Be $false
            $result -contains '--id' | Should Be $true
            $result -contains '--detect' | Should Be $true
            $result -contains '--instance' | Should Be $true
            $result -contains '--reviewers' | Should Be $true
        }

        It 'Tab completes git pr work-items list all short parameters' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr work-items list -'
            $result -contains '-i' | Should Be $true
            $result -contains '-h' | Should Be $true
            $result -contains '-o' | Should Be $true
        }

        It 'Tab completes git pr list --output types' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr list --output '
            $result -contains 'json' | Should Be $true
            $result -contains 'jsonc' | Should Be $true
            $result -contains 'table' | Should Be $true
            $result -contains 'tsv' | Should Be $true
        }

        It 'Tab completes git pr policies list -o types' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr policies list -o '
            $result -contains 'json' | Should Be $true
            $result -contains 'jsonc' | Should Be $true
            $result -contains 'table' | Should Be $true
            $result -contains 'tsv' | Should Be $true
        }

        It 'Tab completes git pr reviewers list --output= types' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr reviewers list --output='
            $result -contains '--output=' | Should Be $false
            $result -contains '--output=json' | Should Be $true
            $result -contains '--output=jsonc' | Should Be $true
            $result -contains '--output=table' | Should Be $true
            $result -contains '--output=tsv' | Should Be $true
        }

        It 'Tab completes git pr set-vote --vote= types' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr set-vote --vote='
            $result -contains '--vote=approve' | Should Be $true
            $result -contains '--vote=approve-with-suggestions' | Should Be $true
            $result -contains '--vote=reject' | Should Be $true
            $result -contains '--vote=reset' | Should Be $true
            $result -contains '--vote=wait-for-author' | Should Be $true
        }

        # need to mock gitRemoteUniqueBranches
        InModuleScope 'posh-git' {

            Mock gitRemoteUniqueBranches { return 'master' } -ParameterFilter {   $filter -eq 'm' }
            Mock gitRemoteUniqueBranches { return 'develop','master' } -ParameterFilter { $filter -eq '' }

            It 'Tab completes git pr create --target-branch partial branch names' {
                $result = GitTabExpansionInternal 'git test-vsts-pr create --target-branch m'

                $result -contains 'develop' | Should Be $false
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create -t branch names' {
                $result = GitTabExpansionInternal 'git test-vsts-pr create -t '
                $result -contains 'develop' | Should Be $true
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create -s branch names' {
                $result = GitTabExpansionInternal 'git test-vsts-pr create -s m'
                $result -contains 'develop' | Should Be $false
                $result -contains 'master' | Should Be $true
            }

            It 'Tab completes git pr create --source-branch branch names' {
                $result = GitTabExpansionInternal 'git test-vsts-pr create --source-branch '
                $result -contains 'develop' | Should Be $true
                $result -contains 'master' | Should Be $true
            }
        }
    }
}
