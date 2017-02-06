. $PSScriptRoot\Shared.ps1

Describe 'Get-GitDiretory Tests' {
    Context "Test normal repository" {
        BeforeAll {
            $origPath = Get-Location
        }
        AfterAll {
            Set-Location $origPath
        }

        It 'Returns $null for not a Git repo' {
            Set-Location $env:windir
            Get-GitDirectory | Should BeNullOrEmpty
        }
        It 'Returns $null for not a filesystem path' {
            Set-Location Cert:\CurrentUser
            Get-GitDirectory | Should BeNullOrEmpty
        }
        It 'Returns correct path when in the root of repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $repoRoot
            Get-GitDirectory | Should BeExactly (MakeNativePath $repoRoot\.git)
        }
        It 'Returns correct path when under a child folder of the root of repo' {
            $repoRoot = (Resolve-Path $PSScriptRoot\..).Path
            Set-Location $PSScriptRoot
            Get-GitDirectory | Should BeExactly (Join-Path $repoRoot .git)
        }
    }

    Context "Test bare repository" {
        BeforeAll {
            $origPath = Get-Location
            $temp = [System.IO.Path]::GetTempPath()
            $bareRepoName = "test.git"
            $bareRepoPath = Join-Path $temp $bareRepoName
            if (Test-Path $bareRepoPath) {
                Remove-Item $bareRepoPath -Recurse -Force
            }
            git init --bare $bareRepoPath
        }
        AfterAll {
            Set-Location $origPath
            if (Test-Path $bareRepoPath) {
                Remove-Item $bareRepoPath -Recurse -Force
            }
        }

        It 'Returns correct path when in the root of bare repo' {
            Set-Location $bareRepoPath
            Get-GitDirectory | Should BeExactly (MakeNativePath $bareRepoPath)
        }
        It 'Returns correct path when under a child folder of the root of bare repo' {
            Set-Location $bareRepoPath\hooks -ErrorVariable Stop
            MakeNativePath (Get-GitDirectory) | Should BeExactly $bareRepoPath
        }
    }

    Context "Test GIT_DIR environment variable" {
        AfterAll {
            Remove-Item Env:\GIT_DIR -ErrorAction SilentlyContinue
        }
        It 'Returns the value in GIT_DIR env var' {
            $env:GIT_DIR = 'C:\xyzzy\posh-git\.git'
            Get-GitDirectory | Should BeExactly $env:GIT_DIR
        }
    }
}
