. $PSScriptRoot\Shared.ps1

Describe 'TabExpansion Tests' {
    It 'Exports a TabExpansion function' {
        $module.ExportedFunctions.Keys -contains 'TabExpansion' | Should Be $true
    }
    Context 'Subcommand TabExpansion Tests' {
        It 'Tab completes without subcommands' {
            $result = & $module GitTabExpansionInternal 'git whatever '

            $result | Should Be @()
        }
        It 'Tab completes bisect subcommands' {
            $result = & $module GitTabExpansionInternal 'git bisect '

            $result -contains '' | Should Be $false
            $result -contains 'start' | Should Be $true
            $result -contains 'run' | Should Be $true

            $result2 = & $module GitTabExpansionInternal 'git bisect s'

            $result2 -contains 'start' | Should Be $true
            $result2 -contains 'skip' | Should Be $true
        }
        It 'Tab completes remote subcommands' {
            $result = & $module GitTabExpansionInternal 'git remote '

            $result -contains '' | Should Be $false
            $result -contains 'add' | Should Be $true
            $result -contains 'set-branches' | Should Be $true
            $result -contains 'get-url' | Should Be $true
            $result -contains 'update' | Should Be $true

            $result2 = & $module GitTabExpansionInternal 'git remote s'

            $result2 -contains 'set-branches' | Should Be $true
            $result2 -contains 'set-head' | Should Be $true
            $result2 -contains 'set-url' | Should Be $true
        }
        It 'Tab completes update-git-for-windows only on Windows' {
            $result = & $module GitTabExpansionInternal 'git update-'

            if ((($PSVersionTable.PSVersion.Major -eq 5) -or $IsWindows)) {
                $result -contains '' | Should Be $false
                $result -contains 'update-git-for-windows' | Should Be $true
            }
            else {
                $result | Should BeNullOrEmpty
            }
        }
    }
    Context 'Fetch/Push/Pull TabExpansion Tests' {
        BeforeEach {
            # Ensure master branch exists
            &$gitbin branch -q master 2>$null
            # Ensure an origin remote exists
            &$gitbin remote add origin . 2>$null
            # Ensure origin/master exists
            &$gitbin update-ref refs/remotes/origin/master $(git rev-parse master) 2>$null
            # Ensure origin/HEAD exists
            &$gitbin symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master 2>$null
        }
        It 'Tab completes all remotes' {
            (&$gitbin remote) -contains 'origin' | Should Be $true

            $result = & $module GitTabExpansionInternal 'git push '
            $result -contains 'origin' | Should Be $true
        }
        It 'Tab completes all branches' {
            $result = & $module GitTabExpansionInternal 'git push origin '
            $result -contains 'master' | Should Be $true
            $result -contains 'origin/master' | Should Be $true
            $result -contains 'origin/HEAD' | Should Be $true
        }
        It 'Tab completes all :branches' {
            $result = & $module GitTabExpansionInternal 'git push origin :'
            $result -contains ':master' | Should Be $true
        }
        It 'Tab completes matching remotes' {
            $result = & $module GitTabExpansionInternal 'git push or'
            $result | Should BeExactly 'origin'
        }
        It 'Tab completes matching branches' {
            $result = & $module GitTabExpansionInternal 'git push origin ma'
            $result | Should BeExactly 'master'
        }
        It 'Tab completes matching remote/branches' {
            $result = & $module GitTabExpansionInternal 'git push origin origin/ma'
            $result | Should BeExactly 'origin/master'
        }
        It 'Tab completes matching :branches' {
            $result = & $module GitTabExpansionInternal 'git push origin :ma'
            $result | Should BeExactly ':master'
        }
        It 'Tab completes matching ref:branches' {
            $result = & $module GitTabExpansionInternal 'git push origin HEAD:ma'
            $result | Should BeExactly 'HEAD:master'
        }
        It 'Tab completes matching +ref:branches' {
            $result = & $module GitTabExpansionInternal 'git push origin +HEAD:ma'
            $result | Should BeExactly '+HEAD:master'
        }
        It 'Tab completes matching remote with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push --follow-tags  -u   or'
            $result | Should BeExactly 'origin'
        }
        It 'Tab completes all branches with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin '
            $result -contains 'master' | Should Be $true
            $result -contains 'origin/master' | Should Be $true
            $result -contains 'origin/HEAD' | Should Be $true
        }
        It 'Tab completes matching branch with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin ma'
            $result | Should BeExactly 'master'
        }
        It 'Tab completes matching branch with intermixed parameters' {
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags ma'
            $result | Should BeExactly 'master'
            $result = & $module GitTabExpansionInternal 'git push  -u  origin  --follow-tags   ma'
            $result | Should BeExactly 'master'
        }
        It 'Tab completes matching ref:branch with intermixed parameters' {
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags HEAD:ma'
            $result | Should BeExactly 'HEAD:master'
            $result = & $module GitTabExpansionInternal 'git push  -u  origin  --follow-tags   +HEAD:ma'
            $result | Should BeExactly '+HEAD:master'
        }
        It 'Tab completes matching multiple push ref specs with intermixed parameters' {
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  ma'
            $result | Should BeExactly 'master'
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  --crazy-param ma'
            $result | Should BeExactly 'master'
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  HEAD:ma'
            $result | Should BeExactly 'HEAD:master'
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  --crazy-param HEAD:ma'
            $result | Should BeExactly 'HEAD:master'

            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  +ma'
            $result | Should BeExactly '+master'
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags one :two three:four  --crazy-param +ma'
            $result | Should BeExactly '+master'
            $result = & $module GitTabExpansionInternal 'git push  -u  origin  --follow-tags one :two three:four  +HEAD:ma'
            $result | Should BeExactly '+HEAD:master'
            $result = & $module GitTabExpansionInternal 'git push  -u  origin  --follow-tags  one :two three:four  --crazy-param  +HEAD:ma'
            $result | Should BeExactly '+HEAD:master'
        }
        It 'Tab complete returns empty result for missing remote' {
            $result = & $module GitTabExpansionInternal 'git push zy'
            $result | Should BeNullOrEmpty
        }
        It 'Tab complete returns empty result for missing branch' {
            $result = & $module GitTabExpansionInternal 'git push origin zy'
            $result | Should BeNullOrEmpty
        }
        It 'Tab complete returns empty result for missing remotebranch' {
            $result = & $module GitTabExpansionInternal 'git fetch origin/zy'
            $result | Should BeNullOrEmpty
        }

        It 'Tab completes branch names with - and -- in them' {
            $branchName = 'branch--for-Pester-tests'
            if (&$gitbin branch --list -q $branchName) {
                &$gitbin branch -D $branchName
            }

            &$gitbin branch $branchName
            try {
                $result = & $module GitTabExpansionInternal 'git push origin branch-'
                $result | Should BeExactly $branchName

                $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin '
                $result -contains $branchName | Should Be $true
            }
            finally {
                &$gitbin branch -D $branchName
            }
        }
    }

    Context 'Vsts' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo

            # Test with non-standard vsts pr alias name
            &$gitbin config alias.test-vsts-pr "!f() { exec vsts code pr \`"`$`@\`"; }; f"
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
        }
        It 'Tab completes pr options' {
            $result = & $module GitTabExpansionInternal 'git test-vsts-pr '
            $result -contains 'abandon' | Should Be $true
        }
    }

    Context 'Add/Reset/Checkout TabExpansion Tests' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
        }
        It 'Tab completes non-ASCII file name' {
            &$gitbin config core.quotepath true # Problematic (default) config

            $fileName = "posh$([char]8226)git.txt"
            New-Item $fileName -ItemType File

            $gitStatus = & $module Get-GitStatus

            $result = & $module GitTabExpansionInternal 'git add ' $gitStatus
            $result | Should BeExactly $fileName
        }
    }

    Context 'Alias TabExpansion Tests' {
        $addedAliases = @()
        function Add-GlobalTestAlias($Name, $Value) {
            if (!(&$gitbin config --global "alias.$Name")) {
                &$gitbin config --global "alias.$Name" $Value
                $addedAliases += $Name
            }
        }
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
        }
        AfterAll {
            $addedAliases | Where-Object { $_ } | ForEach-Object {
                &$gitbin config --global --unset "alias.$_" 2>$null
            }

            RemoveGitTempRepo $repoPath
        }
        It 'Command completion includes unique list of aliases' {
            $alias = "test-$(New-Guid)"

            Add-GlobalTestAlias $alias config
            &$gitbin config alias.$alias help
            (&$gitbin config --get-all alias.$alias).Count | Should Be 2

            $result = @(& $module GitTabExpansionInternal "git $alias")
            $result.Count | Should Be 1
            $result[0] | Should BeExactly $alias
        }
        It 'Tab completes when there is one alias of a given name' {
            $alias = "test-$(New-Guid)"

            &$gitbin config alias.$alias checkout
            (&$gitbin config --get-all alias.$alias).Count | Should Be 1

            $result = & $module GitTabExpansionInternal "git $alias ma"
            $result | Should BeExactly 'master'
        }
        It 'Tab completes when there are multiple aliases of the same name' {
            Add-GlobalTestAlias co checkout

            &$gitbin config alias.co checkout
            (&$gitbin config --get-all alias.co).Count | Should BeGreaterThan 1

            $result = & $module GitTabExpansionInternal 'git co ma'
            $result | Should BeExactly 'master'
        }
    }

    Context 'PowerShell Special Chars Tests' {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
        }
        AfterAll {
            RemoveGitTempRepo $repoPath
        }
        AfterEach {
            ResetGitTempRepoWorkingDir $repoPath
        }
        It 'Tab completes remote name with special char as quoted' {
            &$gitbin remote add '#test' https://github.com/dahlbyk/posh-git.git 2> $null

            $result = & $module GitTabExpansionInternal 'git push #'
            $result | Should BeExactly "'#test'"
        }
        It 'Tab completes branch name with special char as quoted' {
            &$gitbin branch '#develop' 2>$null

            $result = & $module GitTabExpansionInternal 'git checkout #'
            $result | Should BeExactly "'#develop'"
        }
        It 'Tab completes git feature branch name with special char as quoted' {
            &$gitbin branch '#develop' 2>$null

            $result = & $module GitTabExpansionInternal 'git flow feature list #'
            $result | Should BeExactly "'#develop'"
        }
        It 'Tab completes a tag name with special char as quoted' {
            $tag = "v1.0.0;abcdef"
            &$gitbin tag $tag

            $result = & $module GitTabExpansionInternal 'git show v1'
            $result | Should BeExactly "'$tag'"
        }
        It 'Tab completes a tag name with single quote correctly' {
            &$gitbin tag "v2.0.0'"

            $result = & $module GitTabExpansionInternal 'git show v2'
            $result | Should BeExactly "'v2.0.0'''"
        }
        It 'Tab completes add file in working dir with special char as quoted' {
            $filename = 'foo{bar} (x86).txt';
            New-Item $filename -ItemType File

            $gitStatus = & $module Get-GitStatus

            $result = & $module GitTabExpansionInternal 'git add ' $gitStatus
            $result | Should BeExactly "'$filename'"
        }
    }
}
