. $PSScriptRoot\Shared.ps1

Describe 'TabExpansion Tests' {
    It 'Exports a TabExpansion function' {
        $module.ExportedFunctions.Keys -contains 'TabExpansion' | Should Be $true
    }
    Context 'Fetch/Push/Pull TabExpansion Tests' {
        BeforeEach {
            # Ensure master branch exists
            git branch -q master origin/master 2>$null
        }
        It 'Tab completes all remotes' {
            (git remote) -contains 'origin' | Should Be $true

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
            if (git branch --list -q $branchName) {
                git branch -D $branchName
            }

            git branch $branchName
            try {
                $result = & $module GitTabExpansionInternal 'git push origin branch-'
                $result | Should BeExactly $branchName

                $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin '
                $result -contains $branchName | Should Be $true
            }
            finally {
                git branch -D $branchName
            }
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
            git.exe config core.quotepath true # Problematic (default) config

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
            if (!(git config --global "alias.$Name")) {
                git.exe config --global "alias.$Name" $Value
                $addedAliases += $Name
            }
        }
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
        }
        AfterAll {
            $addedAliases | Where-Object { $_ } | ForEach-Object {
                git.exe config --global --unset "alias.$_" 2>$null
            }

            RemoveGitTempRepo $repoPath
        }
        It 'Command completion includes unique list of aliases' {
            $alias = "test-$(New-Guid)"

            Add-GlobalTestAlias $alias config
            git.exe config alias.$alias help
            (git.exe config --get-all alias.$alias).Count | Should Be 2

            $result = @(& $module GitTabExpansionInternal "git $alias")
            $result.Count | Should Be 1
            $result[0] | Should BeExactly $alias
        }
        It 'Tab completes when there is one alias of a given name' {
            $alias = "test-$(New-Guid)"

            git.exe config alias.$alias checkout
            (git.exe config --get-all alias.$alias).Count | Should Be 1

            $result = & $module GitTabExpansionInternal "git $alias ma"
            $result | Should BeExactly 'master'
        }
        It 'Tab completes when there are multiple aliases of the same name' {
            Add-GlobalTestAlias co checkout

            git.exe config alias.co checkout
            (git.exe config --get-all alias.co).Count | Should BeGreaterThan 1

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
            git.exe remote add '#test' https://github.com/dahlbyk/posh-git.git 2> $null

            $result = & $module GitTabExpansionInternal 'git push #'
            $result | Should BeExactly "'#test'"
        }
        It 'Tab completes branch name with special char as quoted' {
            git.exe branch '#develop' 2>$null

            $result = & $module GitTabExpansionInternal 'git checkout #'
            $result | Should BeExactly "'#develop'"
        }
        It 'Tab completes git feature branch name with special char as quoted' {
            git.exe branch '#develop' 2>$null

            $result = & $module GitTabExpansionInternal 'git flow feature list #'
            $result | Should BeExactly "'#develop'"
        }
        It 'Tab completes a tag name with special char as quoted' {
            $tag = "v1.0.0;abcdef"
            git.exe tag $tag

            $result = & $module GitTabExpansionInternal 'git show v1'
            $result | Should BeExactly "'$tag'"
        }
        It 'Tab completes a tag name with single quote correctly' {
            git.exe tag "v2.0.0'"

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
