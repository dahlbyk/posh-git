# For info on Pester mocking see - http://www.powershellmagazine.com/2014/09/30/pester-mock-and-testdrive/
BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Get-GitStatus Tests' {
    Context 'Get-GitStatus Working Directory Tests' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the correct branch name' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding @'
## rkeithill/more-status-tests
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.Branch | Should -Be "rkeithill/more-status-tests"
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Working.Added.Count | Should -Be 0
            $status.Working.Deleted.Count | Should -Be 0
            $status.Working.Modified.Count | Should -Be 0
            $status.Working.Unmerged.Count | Should -Be 0
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 0
            $status.Index.Unmerged.Count | Should -Be 0
        }


        It 'Returns the correct number of added untracked working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
?? test/Foo.Tests.ps1
?? test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 2
            $status.Working.Deleted.Count | Should -Be 0
            $status.Working.Modified.Count | Should -Be 0
            $status.Working.Unmerged.Count | Should -Be 0
            $status.Working.Added[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Working.Added[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of added working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
 A test/Foo.Tests.ps1
 A test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 2
            $status.Working.Deleted.Count | Should -Be 0
            $status.Working.Modified.Count | Should -Be 0
            $status.Working.Unmerged.Count | Should -Be 0
            $status.Working.Added[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Working.Added[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of deleted working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
 D test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 0
            $status.Working.Deleted.Count | Should -Be 2
            $status.Working.Modified.Count | Should -Be 0
            $status.Working.Unmerged.Count | Should -Be 0
            $status.Working.Deleted[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Working.Deleted[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
 M test/Foo.Tests.ps1
 M test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 0
            $status.Working.Deleted.Count | Should -Be 0
            $status.Working.Modified.Count | Should -Be 2
            $status.Working.Unmerged.Count | Should -Be 0
            $status.Working.Modified[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Working.Modified[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of unmerged working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
 U test/Foo.Tests.ps1
 U test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 0
            $status.Working.Deleted.Count | Should -Be 0
            $status.Working.Modified.Count | Should -Be 0
            $status.Working.Unmerged.Count | Should -Be 2
            $status.Working.Unmerged[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Working.Unmerged[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of mixed working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
 ? test/Untracked.Tests.ps1
 A test/Added.Tests.ps1
 D test/Deleted.Tests.ps1
 M test/Modified.Tests.ps1
 U test/Unmerged.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $false
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 2
            $status.Working.Deleted.Count | Should -Be 1
            $status.Working.Modified.Count | Should -Be 1
            $status.Working.Unmerged.Count | Should -Be 1
            $status.Working.Added[0] | Should -Be "test/Untracked.Tests.ps1"
            $status.Working.Added[1] | Should -Be "test/Added.Tests.ps1"
            $status.Working.Deleted[0] | Should -Be "test/Deleted.Tests.ps1"
            $status.Working.Modified[0] | Should -Be "test/Modified.Tests.ps1"
            $status.Working.Unmerged[0] | Should -Be "test/Unmerged.Tests.ps1"
        }

        It 'Returns the correct number of added index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
A  test/Foo.Tests.ps1
A  test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 2
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 0
            $status.Index.Unmerged.Count | Should -Be 0
            $status.Index.Added[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Index.Added[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of deleted index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
D  test/Foo.Tests.ps1
D  test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 2
            $status.Index.Modified.Count | Should -Be 0
            $status.Index.Unmerged.Count | Should -Be 0
            $status.Index.Deleted[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Index.Deleted[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of copied index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
C  test/Foo.Tests.ps1
C  test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 2
            $status.Index.Unmerged.Count | Should -Be 0
            $status.Index.Modified[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Index.Modified[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
M  test/Foo.Tests.ps1
M  test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 2
            $status.Index.Unmerged.Count | Should -Be 0
            $status.Index.Modified[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Index.Modified[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files for a rename' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
R  README.md -> README2.md
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 1
            $status.Index.Unmerged.Count | Should -Be 0
            $status.Index.Modified[0] | Should -Be "README.md"
        }
        It 'Returns the correct number of unmerged index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
U  test/Foo.Tests.ps1
U  test/Bar.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 0
            $status.Index.Deleted.Count | Should -Be 0
            $status.Index.Modified.Count | Should -Be 0
            $status.Index.Unmerged.Count | Should -Be 2
            $status.Index.Unmerged[0] | Should -Be "test/Foo.Tests.ps1"
            $status.Index.Unmerged[1] | Should -Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of mixed index files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
A  test/Added.Tests.ps1
D  test/Deleted.Tests.ps1
C  test/Copied.Tests.ps1
R  README.md -> README2.md
M  test/Modified.Tests.ps1
U  test/Unmerged.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Index.Added.Count | Should -Be 1
            $status.Index.Deleted.Count | Should -Be 1
            $status.Index.Modified.Count | Should -Be 3
            $status.Index.Unmerged.Count | Should -Be 1
            $status.Index.Added[0] | Should -Be "test/Added.Tests.ps1"
            $status.Index.Deleted[0] | Should -Be "test/Deleted.Tests.ps1"
            $status.Index.Modified[0] | Should -Be "test/Copied.Tests.ps1"
            $status.Index.Modified[1] | Should -Be "README.md"
            $status.Index.Modified[2] | Should -Be "test/Modified.Tests.ps1"
            $status.Index.Unmerged[0] | Should -Be "test/Unmerged.Tests.ps1"
        }

        It 'Returns the correct number of mixed index and working files' {
            Mock -ModuleName posh-git git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
A  test/Added.Tests.ps1
D  test/Deleted.Tests.ps1
C  test/Copied.Tests.ps1
R  README.md -> README2.md
M  test/Modified.Tests.ps1
U  test/Unmerged.Tests.ps1
 ? test/Untracked.Tests.ps1
 A test/Added.Tests.ps1
 D test/Deleted.Tests.ps1
 M test/Modified.Tests.ps1
 U test/Unmerged.Tests.ps1
'@
            }

            $status = Get-GitStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $status.HasIndex | Should -Be $true
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 2
            $status.Working.Deleted.Count | Should -Be 1
            $status.Working.Modified.Count | Should -Be 1
            $status.Working.Unmerged.Count | Should -Be 1
            $status.Working.Added[0] | Should -Be "test/Untracked.Tests.ps1"
            $status.Working.Added[1] | Should -Be "test/Added.Tests.ps1"
            $status.Working.Deleted[0] | Should -Be "test/Deleted.Tests.ps1"
            $status.Working.Modified[0] | Should -Be "test/Modified.Tests.ps1"
            $status.Working.Unmerged[0] | Should -Be "test/Unmerged.Tests.ps1"
            $status.Index.Added.Count | Should -Be 1
            $status.Index.Deleted.Count | Should -Be 1
            $status.Index.Modified.Count | Should -Be 3
            $status.Index.Unmerged.Count | Should -Be 1
            $status.Index.Added[0] | Should -Be "test/Added.Tests.ps1"
            $status.Index.Deleted[0] | Should -Be "test/Deleted.Tests.ps1"
            $status.Index.Modified[0] | Should -Be "test/Copied.Tests.ps1"
            $status.Index.Modified[1] | Should -Be "README.md"
            $status.Index.Modified[2] | Should -Be "test/Modified.Tests.ps1"
            $status.Index.Unmerged[0] | Should -Be "test/Unmerged.Tests.ps1"
        }
    }

    Context 'Branch progress suffix' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
        }
        AfterEach {
            Set-Location $PSScriptRoot
            RemoveGitTempRepo $repoPath
        }

        It('Shows CHERRY-PICKING') {
            git checkout -qb test
            Write-Output 1 > test.txt
            git add test.txt
            git commit -qam 'first' 2> $null

            git checkout -qb conflict
            Write-Output 2 > test.txt
            git commit -qam 'second' 2> $null

            $status = Get-GitStatus
            $status.Branch | Should -Be conflict

            git cherry-pick test

            $status = Get-GitStatus
            $status.Branch | Should -Be 'conflict|CHERRY-PICKING'
        }

        It('Shows MERGING') {
            git checkout -qb test
            Write-Output 1 > test.txt
            git add test.txt
            git commit -qam 'first' 2> $null

            Write-Output 2 > test.txt
            git commit -qam 'second' 2> $null

            git checkout HEAD~ -qb conflict
            Write-Output 3 > test.txt
            git commit -qam 'third' 2> $null

            $status = Get-GitStatus
            $status.Branch | Should -Be conflict

            git merge test

            $status = Get-GitStatus
            $status.Branch | Should -Be 'conflict|MERGING'
        }

        It('Shows REVERTING') {
            git checkout -qb test
            Write-Output 1 > test.txt
            git add test.txt
            git commit -qam 'first' 2> $null

            git checkout -qb conflict
            Write-Output 2 > test.txt
            git commit -qam 'second' 2> $null

            $status = Get-GitStatus
            $status.Branch | Should -Be conflict

            git revert test

            $status = Get-GitStatus
            $status.Branch | Should -Be 'conflict|REVERTING'
        }
    }

    Context 'In .git' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo
        }
        AfterEach {
            Set-Location $PSScriptRoot
            RemoveGitTempRepo $repoPath
        }

        It('Does not have files') {
            New-Item "$repoPath/test.txt" -ItemType File

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 1

            Set-Location "$repoPath/.git" -ErrorAction Stop

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Working.Added.Count | Should -Be 0

            Set-Location "$repoPath/.git/refs" -ErrorAction Stop

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $false
            $status.HasWorking | Should -Be $false
            $status.Working.Added.Count | Should -Be 0
        }
    }

    Context 'In .github' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo
            New-Item -Type Directory -Force "$repoPath/.github/workflows"
        }
        AfterEach {
            Set-Location $PSScriptRoot
            RemoveGitTempRepo $repoPath
        }

        It('Files are not ignored') {
            New-Item "$repoPath/test.txt" -ItemType File

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 1

            Set-Location "$repoPath/.github" -ErrorAction Stop

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 1

            Set-Location "$repoPath/.github/workflows" -ErrorAction Stop

            $status = Get-GitStatus
            $status.HasUntracked | Should -Be $true
            $status.HasWorking | Should -Be $true
            $status.Working.Added.Count | Should -Be 1
        }
    }
}
