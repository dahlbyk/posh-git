. $PSScriptRoot\Shared.ps1

Describe 'ParamsTabExpansion Tests' {
    Context 'Push Parameters TabExpansion Tests' {
        It 'Tab completes all long push parameters' {
            $result = & $module GitTabExpansionInternal 'git push --'
            $result -contains '--all' | Should Be $true
            $result -contains '--delete' | Should Be $true
            $result -contains '--dry-run' | Should Be $true
            $result -contains '--exec=' | Should Be $true
            $result -contains '--follow-tags' | Should Be $true
            $result -contains '--force' | Should Be $true
            $result -contains '--force-with-lease' | Should Be $true
            $result -contains '--mirror' | Should Be $true
            $result -contains '--no-force-with-lease' | Should Be $true
            $result -contains '--no-thin' | Should Be $true
            $result -contains '--no-verify' | Should Be $true
            $result -contains '--porcelain' | Should Be $true
            $result -contains '--progress' | Should Be $true
            $result -contains '--prune' | Should Be $true
            $result -contains '--quiet' | Should Be $true
            $result -contains '--receive-pack=' | Should Be $true
            $result -contains '--recurse-submodules=' | Should Be $true
            $result -contains '--repo=' | Should Be $true
            $result -contains '--set-upstream' | Should Be $true
            $result -contains '--tags' | Should Be $true
            $result -contains '--thin' | Should Be $true
            $result -contains '--verbose' | Should Be $true
            $result -contains '--verify' | Should Be $true
        }
        It 'Tab completes all short push parameters' {
            $result = & $module GitTabExpansionInternal 'git push -'
            $result -contains '-f' | Should Be $true
            $result -contains '-n' | Should Be $true
            $result -contains '-q' | Should Be $true
            $result -contains '-u' | Should Be $true
            $result -contains '-v' | Should Be $true
        }
        It 'Tab completes push parameters values' {
            $result = & $module GitTabExpansionInternal 'git push --recurse-submodules='
            $result -contains '--recurse-submodules=check' | Should Be $true
            $result -contains '--recurse-submodules=on-demand' | Should Be $true
        }
    }
}

