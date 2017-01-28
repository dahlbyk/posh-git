. $PSScriptRoot\Shared.ps1

Describe 'TabExpansion Tests' {
    Context 'Fetch/Push/Pull TabExpansion Tests' {
        It 'Tab completes all remotes' {
            $result = & $module GitTabExpansionInternal 'git push '
            $result | Should BeExactly 'origin'
        }
        It 'Tab completes matching remotes' {
            $result = & $module GitTabExpansionInternal 'git push or'
            $result | Should BeExactly 'origin'
        }
        It 'Tab completes matching remote/branches' {
            $result = & $module GitTabExpansionInternal 'git push origin origin/ma'
            $result | Should BeExactly 'origin/master'
        }
        It 'Tab completes remote and all branches' {
            $result = & $module GitTabExpansionInternal 'git push origin '
            $result -contains 'master' | Should Be $true
            $result -contains 'origin/master' | Should Be $true
            $result -contains 'origin/HEAD' | Should Be $true
        }
        It 'Tab completes remote and matching branches' {
            $result = & $module GitTabExpansionInternal 'git push origin ma'
            $result | Should BeExactly 'master'
        }
        It 'Tab completes matching remote with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push --follow-tags  -u   or'
            $result | Should BeExactly 'origin'
        }
        It 'Tab completes remote and all branches with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin '
            $result -contains 'master' | Should Be $true
            $result -contains 'origin/master' | Should Be $true
            $result -contains 'origin/HEAD' | Should Be $true
        }
        It 'Tab completes remote and matching branch with preceding parameters' {
            $result = & $module GitTabExpansionInternal 'git push  --follow-tags  -u   origin ma'
            $result | Should BeExactly 'master'
        }
        It 'Tab completes remote and matching branch with intermixed parameters' {
            $result = & $module GitTabExpansionInternal 'git push -u origin --follow-tags ma'
            $result | Should BeExactly 'master'
            $result = & $module GitTabExpansionInternal 'git push  -u  origin  --follow-tags   ma'
            $result | Should BeExactly 'master'
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
}
