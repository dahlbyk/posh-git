# For info on Pester mocking see - http://www.powershellmagazine.com/2014/09/30/pester-mock-and-testdrive/
Describe 'Get-GitStatus Tests' {
    Context 'Get-GitStatus Working Directory Tests' {
        BeforeAll {
            function global:git {
                $cmdline = "$args"
                switch ($cmdline) {
                    '--version' { 'git version 2.11.0.windows.1' }
                    'help'      { Get-Content $PSScriptRoot\git-help.txt  }
                    default     {
                        $res = Invoke-Expression "git.exe $cmdline"
                        $res
                    }
                }
            }

          # Import module after we've overriden git command to return version, etc
          . $PSScriptRoot\Shared.ps1
        }

        It 'Returns the correct branch name' {
            Mock git { return @'
## rkeithill/more-status-tests
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.Branch | Should Be "rkeithill/more-status-tests"
        }
        It 'Returns the correct number of modified working files' {
            Mock git { return @'
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
            $status.Working.Modified.Count | Should Be 2
            $status.Working.Modified[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Modified[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files' {
            Mock git { return @'
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
            $status.Index.Modified.Count | Should Be 2
            $status.Index.Modified[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index.Modified[1] | Should Be "test/Bar.Tests.ps1"
        }
        It 'Returns the correct number of modified index files for a rename' {
            Mock git { return @'
## master
R  README.md -> README2.md
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.HasWorking | Should Be $false
            $status.Index.Modified.Count | Should Be 1
            $status.Index.Modified[0] | Should Be "README.md"
        }
        It 'Returns the correct number of added untracked working files' {
            Mock git { return @'
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
            $status.Working.Added[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working.Added[1] | Should Be "test/Bar.Tests.ps1"
        }
    }
}
