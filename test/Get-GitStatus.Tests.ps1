# For info on Pester mocking see - http://www.powershellmagazine.com/2014/09/30/pester-mock-and-testdrive/
. $PSScriptRoot\Shared.ps1

Describe 'Get-GitStatus Tests' {
    Context 'Get-GitStatus Working Directory Tests' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the correct branch name' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## rkeithill/more-status-tests
'@
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.Branch | Should Be "rkeithill/more-status-tests"
        }


        It 'Returns the correct number of added untracked working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
?? test/Foo.Tests.ps1
?? test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $true
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 2
            $status.Working.Deleted.Count | Should Be 0
            $status.Working.Modified.Count | Should Be 0
            $status.Working.Unmerged.Count | Should Be 0
            $status.Working.Added[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Added[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of added working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
 A test/Foo.Tests.ps1
 A test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $true
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 2
            $status.Working.Deleted.Count | Should Be 0
            $status.Working.Modified.Count | Should Be 0
            $status.Working.Unmerged.Count | Should Be 0
            $status.Working.Added[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Added[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of deleted working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
 D test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 0
            $status.Working.Deleted.Count | Should Be 2
            $status.Working.Modified.Count | Should Be 0
            $status.Working.Unmerged.Count | Should Be 0
            $status.Working.Deleted[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Deleted[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
 M test/Foo.Tests.ps1
 M test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 0
            $status.Working.Deleted.Count | Should Be 0
            $status.Working.Modified.Count | Should Be 2
            $status.Working.Unmerged.Count | Should Be 0
            $status.Working.Modified[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Modified[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of unmerged working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
 U test/Foo.Tests.ps1
 U test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 0
            $status.Working.Deleted.Count | Should Be 0
            $status.Working.Modified.Count | Should Be 0
            $status.Working.Unmerged.Count | Should Be 2
            $status.Working.Unmerged[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Unmerged[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of mixed working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
 ? test/Untracked.Tests.ps1
 A test/Added.Tests.ps1
 D test/Deleted.Tests.ps1
 M test/Modified.Tests.ps1
 U test/Unmerged.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $true
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 2
            $status.Working.Deleted.Count | Should Be 1
            $status.Working.Modified.Count | Should Be 1
            $status.Working.Unmerged.Count | Should Be 1
            $status.Working.Added[0] | Should Be "test/Untracked.Tests.ps1"
            $status.Working.Added[1] | Should Be "test/Added.Tests.ps1"
            $status.Working.Deleted[0] | Should Be "test/Deleted.Tests.ps1"
            $status.Working.Modified[0] | Should Be "test/Modified.Tests.ps1"
            $status.Working.Unmerged[0] | Should Be "test/Unmerged.Tests.ps1"
        }

        It 'Returns the correct number of added index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
A  test/Foo.Tests.ps1
A  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 2
            $status.Index.Deleted.Count | Should Be 0
            $status.Index.Modified.Count | Should Be 0
            $status.Index.Unmerged.Count | Should Be 0
            $status.Index.Added[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Added[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of deleted index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
D  test/Foo.Tests.ps1
D  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 0
            $status.Index.Deleted.Count | Should Be 2
            $status.Index.Modified.Count | Should Be 0
            $status.Index.Unmerged.Count | Should Be 0
            $status.Index.Deleted[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Deleted[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of copied index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
C  test/Foo.Tests.ps1
C  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 0
            $status.Index.Deleted.Count | Should Be 0
            $status.Index.Modified.Count | Should Be 2
            $status.Index.Unmerged.Count | Should Be 0
            $status.Index.Modified[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Modified[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
M  test/Foo.Tests.ps1
M  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 0
            $status.Index.Deleted.Count | Should Be 0
            $status.Index.Modified.Count | Should Be 2
            $status.Index.Unmerged.Count | Should Be 0
            $status.Index.Modified[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Modified[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files for a rename' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
R  README.md -> README2.md
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 0
            $status.Index.Deleted.Count | Should Be 0
            $status.Index.Modified.Count | Should Be 1
            $status.Index.Unmerged.Count | Should Be 0
            $status.Index.Modified[0] | Should Be "README.md"
        }
        It 'Returns the correct number of unmerged index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
U  test/Foo.Tests.ps1
U  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 0
            $status.Index.Deleted.Count | Should Be 0
            $status.Index.Modified.Count | Should Be 0
            $status.Index.Unmerged.Count | Should Be 2
            $status.Index.Unmerged[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Unmerged[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of mixed index files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
A  test/Added.Tests.ps1
D  test/Deleted.Tests.ps1
C  test/Copied.Tests.ps1
R  README.md -> README2.md
M  test/Modified.Tests.ps1
U  test/Unmerged.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Added.Count | Should Be 1
            $status.Index.Deleted.Count | Should Be 1
            $status.Index.Modified.Count | Should Be 3
            $status.Index.Unmerged.Count | Should Be 1
            $status.Index.Added[0] | Should Be "test/Added.Tests.ps1"
            $status.Index.Deleted[0] | Should Be "test/Deleted.Tests.ps1"
            $status.Index.Modified[0] | Should Be "test/Copied.Tests.ps1"
            $status.Index.Modified[1] | Should Be "README.md"
            $status.Index.Modified[2] | Should Be "test/Modified.Tests.ps1"
            $status.Index.Unmerged[0] | Should Be "test/Unmerged.Tests.ps1"
        }

        It 'Returns the correct number of mixed index and working files' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
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
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $true
            $status.HasWorking | Should Be $true
            $status.Working.Added.Count | Should Be 2
            $status.Working.Deleted.Count | Should Be 1
            $status.Working.Modified.Count | Should Be 1
            $status.Working.Unmerged.Count | Should Be 1
            $status.Working.Added[0] | Should Be "test/Untracked.Tests.ps1"
            $status.Working.Added[1] | Should Be "test/Added.Tests.ps1"
            $status.Working.Deleted[0] | Should Be "test/Deleted.Tests.ps1"
            $status.Working.Modified[0] | Should Be "test/Modified.Tests.ps1"
            $status.Working.Unmerged[0] | Should Be "test/Unmerged.Tests.ps1"
            $status.Index.Added.Count | Should Be 1
            $status.Index.Deleted.Count | Should Be 1
            $status.Index.Modified.Count | Should Be 3
            $status.Index.Unmerged.Count | Should Be 1
            $status.Index.Added[0] | Should Be "test/Added.Tests.ps1"
            $status.Index.Deleted[0] | Should Be "test/Deleted.Tests.ps1"
            $status.Index.Modified[0] | Should Be "test/Copied.Tests.ps1"
            $status.Index.Modified[1] | Should Be "README.md"
            $status.Index.Modified[2] | Should Be "test/Modified.Tests.ps1"
            $status.Index.Unmerged[0] | Should Be "test/Unmerged.Tests.ps1"
        }
    }
}
