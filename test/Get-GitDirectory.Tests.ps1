BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-GitDiretory Tests' {
    Context "Test normal repository" {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $origPath = Get-Location
        }
        AfterAll {
            Set-Location $origPath
        }

        It 'Returns $null for not a Git repo' {
            Set-Location $env:windir
            Get-GitDirectory | Should -BeNullOrEmpty
        }
        It 'Returns $null for not a filesystem path' {
            Set-Location Alias:\
            Get-GitDirectory | Should -BeNullOrEmpty
        }
        It 'Returns correct path when in the root of repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot
            Get-GitDirectory | Should -BeExactly (MakeNativePath $repoRoot\.git)
        }
        It 'Returns correct path when under a child folder of the root of repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $PSScriptRoot
            Get-GitDirectory | Should -BeExactly (Join-Path $repoRoot .git)
        }
    }

    Context 'Test worktree' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
            $worktree = [IO.Path]::GetRandomFileName()
            $worktreePath = Split-Path $repoPath -Parent
            $worktreePath = Join-Path $worktreePath $worktree

            New-Item $worktreePath -ItemType Directory > $null
            &$gitbin worktree add -b test-worktree $worktreePath master 2>$null
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
            if ($worktreePath -and (Test-Path $worktreePath)) {
                Remove-Item $worktreePath -Recurse -Force
            }
        }

        It 'Returns the correct dir when under a worktree' {
            Set-Location $worktreePath
            $path = GetMacOSAdjustedTempPath $repoPath
            Get-GitDirectory | Should -BeExactly (MakeGitPath $path\.git\worktrees\$worktree)
        }
    }

    Context 'Test bare repository' {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $origPath = Get-Location
            $temp = [System.IO.Path]::GetTempPath()
            $bareRepoName = "test.git"
            $bareRepoPath = Join-Path $temp $bareRepoName
            if (Test-Path $bareRepoPath) {
                Remove-Item $bareRepoPath -Recurse -Force
            }
            &$gitbin init --bare $bareRepoPath
        }
        AfterAll {
            Set-Location $origPath
            if (Test-Path $bareRepoPath) {
                Remove-Item $bareRepoPath -Recurse -Force
            }
        }

        It 'Returns correct path when in the root of bare repo' {
            Set-Location $bareRepoPath
            Get-GitDirectory | Should -BeExactly (MakeNativePath $bareRepoPath)
        }
        It 'Returns correct path when under a child folder of the root of bare repo' {
            Set-Location $bareRepoPath\hooks -ErrorVariable Stop
            $path = GetMacOSAdjustedTempPath $bareRepoPath
            Get-GitDirectory | Should -BeExactly (MakeNativePath $path)
        }
    }

    Context "Test GIT_DIR environment variable" {
        AfterAll {
            Remove-Item Env:\GIT_DIR -ErrorAction SilentlyContinue
        }
        It 'Returns the value in GIT_DIR env var' {
            $env:GIT_DIR = MakeNativePath '/xyzzy/posh-git/.git'
            Get-GitDirectory | Should -BeExactly $env:GIT_DIR
        }
    }
}
