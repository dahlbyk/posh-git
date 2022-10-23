BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-GitBranch Tests' {
    Context 'Get-GitBranch GIT_DIR Tests' {
        It 'Returns GIT_DIR! when in .git dir of the repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot\.git -ErrorAction Stop
            InModuleScope posh-git {
                InDotGitOrBareRepoDir (Get-Location) | Should -Be $true
                Get-GitBranch -IsDotGitOrBare | Should -BeExactly 'GIT_DIR!'
            }
        }
        It 'Returns correct path when in a child folder of the .git dir of the repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot\.git\hooks -ErrorAction Stop
            InModuleScope posh-git {
                InDotGitOrBareRepoDir (Get-Location) | Should -Be $true
                Get-GitBranch -IsDotGitOrBare | Should -BeExactly 'GIT_DIR!'
            }
        }
    }
}
