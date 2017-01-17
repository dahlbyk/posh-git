. $PSScriptRoot\Shared.ps1

Describe 'Get-GitBranch Tests' {
    Context 'Get-GitBranch GIT_DIR Tests' {
        It 'Returns GIT_DIR! when in .git dir of the repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot\.git -PassThru | Should BeExactly (Join-Path $repoRoot .git)
            Get-GitBranch | Should BeExactly 'GIT_DIR!'
        }
        It 'Returns correct path when in a child folder of the .git dir of the repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot\.git\hooks -PassThru | Should BeExactly (Join-Path $repoRoot (Join-Path .git hooks))
            Get-GitBranch | Should BeExactly 'GIT_DIR!'
        }
    }
}
