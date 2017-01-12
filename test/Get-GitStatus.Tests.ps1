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

        It 'Returns the correct number of modified working files' {
            Mock git { return @'
## rkeithill/improve-pester-tests
 M test/Foo.Tests.ps1
 M test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.Branch | Should Be "rkeithill/improve-pester-tests"
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $false
            $status.Index.Count | Should Be 0
            $status.Working.Count | Should Be 2
            $status.Working[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working[1] | Should Be "test/Bar.Tests.ps1"
            $status.AheadBy  | Should Be 0
            $status.BehindBy | Should Be 0
            $status.StashCount | Should Be 0
            $status.Upstream -eq $null | Should Be $true
        }
        It 'Returns the correct number of modified index files' {
            Mock git { return @'
## rkeithill/improve-pester-tests
M  test/Foo.Tests.ps1
M  test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.Branch | Should Be "rkeithill/improve-pester-tests"
            $status.HasIndex | Should Be $true
            $status.HasUntracked | Should Be $false
            $status.Index.Count | Should Be 2
            $status.Index[0] | Should Be "test/Foo.Tests.ps1"
            $status.Index[1] | Should Be "test/Bar.Tests.ps1"
            $status.Working.Count | Should Be 0
            $status.AheadBy  | Should Be 0
            $status.BehindBy | Should Be 0
            $status.StashCount | Should Be 0
            $status.Upstream -eq $null | Should Be $true
        }
        It 'Returns the correct number of untracked working files' {
            Mock git { return @'
## rkeithill/improve-pester-tests
?? test/Foo.Tests.ps1
?? test/Bar.Tests.ps1
'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $status = Get-GitStatus
            Assert-MockCalled git -ModuleName posh-git #-Exactly 1
            $status.Branch | Should Be "rkeithill/improve-pester-tests"
            $status.HasIndex | Should Be $false
            $status.HasUntracked | Should Be $true
            $status.Index.Count | Should Be 0
            $status.Working.Count | Should Be 2
            $status.Working[0] | Should Be "test/Foo.Tests.ps1"
            $status.Working[1] | Should Be "test/Bar.Tests.ps1"
            $status.AheadBy  | Should Be 0
            $status.BehindBy | Should Be 0
            $status.StashCount | Should Be 0
            $status.Upstream -eq $null | Should Be $true
        }
    }
}
