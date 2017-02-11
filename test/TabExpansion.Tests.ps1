. $PSScriptRoot\Shared.ps1

Describe 'TabExpansion Tests' {
    It 'Exports a TabExpansion function' {
        $module.ExportedFunctions.Keys -contains 'TabExpansion' | Should Be $true
    }
    Context 'Fetch/Push/Pull TabExpansion Tests' {
        It 'Tab completes all remotes' {
            $result = & $module GitTabExpansionInternal 'git push '
            $result | Should BeExactly (git remote)
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
            $origPath = Get-Location
            $temp = [System.IO.Path]::GetTempPath()
            $repoPath = Join-Path $temp ([IO.Path]::GetRandomFileName())

            git init $repoPath
            Set-Location $repoPath
        }
        AfterEach {
            Set-Location $origPath
            if (Test-Path $repoPath) {
                Remove-Item $repoPath -Recurse -Force
            }
        }
        It 'Tab completes non-ASCII file name' {
            git config core.quotepath true # Problematic (default) config

            $fileName = "posh$([char]8226)git.txt"
            New-Item $fileName

            $GitStatus = & $module Get-GitStatus

            $result = & $module GitTabExpansionInternal 'git add ' $GitStatus

            $result | Should BeExactly $fileName
        }
    }
}
