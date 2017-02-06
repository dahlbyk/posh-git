. $PSScriptRoot\Shared.ps1
. $modulePath\Utils.ps1

Describe 'Utils Function Tests' {
    Context 'Add-PoshGitToProfile Tests' {
        BeforeAll {
           $newLine = [System.Environment]::NewLine
        }
        BeforeEach {
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -ErrorAction SilentlyContinue
        }
        It 'Creates profile file if it does not exist that imports absolute path' {
            Mock Get-PSModulePath {
                 return @()
            }
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            Add-PoshGitToProfile $profilePath

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'utf8'
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            @($content)[1] | Should BeExactly "Import-Module '$modulePath\posh-git.psd1'"
        }
        It 'Creates profile file if it does not exist that imports from module path' {
            $parentDir = Split-Path $profilePath -Parent
            Mock Get-PSModulePath {
                return @(
                    'C:\Users\Keith\Documents\WindowsPowerShell\Modules',
                    'C:\Program Files\WindowsPowerShell\Modules',
                    'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\',
                    "$parentDir")
            }

            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            Add-PoshGitToProfile $profilePath $parentDir

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'utf8'
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            @($content)[1] | Should BeExactly "Import-Module posh-git"
        }
        It 'Does not modify profile that already refers to posh-git' {
            $profileContent = @'
Import-Module PSCX
Import-Module posh-git
'@
            Set-Content $profilePath -Value $profileContent -Encoding Ascii

            $output = Add-PoshGitToProfile $profilePath 3>&1

            $output[1] | Should Match 'posh-git appears'
            Get-FileEncoding $profilePath | Should Be 'ascii'
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            $content -join $newLine | Should BeExactly $profileContent
        }
        It 'Adds import from PSModulePath on existing (Unicode) profile file correctly' {
            $profileContent = @'
Import-Module PSCX

New-Alias pscore C:\Users\Keith\GitHub\rkeithhill\PowerShell\src\powershell-win-core\bin\Debug\netcoreapp1.1\win10-x64\powershell.exe
'@
            Set-Content $profilePath -Value $profileContent -Encoding Unicode

            Add-PoshGitToProfile $profilePath (Split-Path $profilePath -Parent)

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'unicode'
            $content = Get-Content $profilePath
            $content.Count | Should Be 5
            $profileContent += "${newLine}${newLine}Import-Module posh-git"
            $content -join $newLine | Should BeExactly $profileContent
        }
    }

    Context 'Test-PoshGitImportedInScript Tests' {
        BeforeEach {
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -ErrorAction SilentlyContinue
        }
        It 'Detects Import-Module posh-git in profile script' {
            $profileContent = "Import-Module posh-git"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $true
        }
        It 'Detects chocolatey installed line in profile script' {
            $profileContent = ". 'C:\tools\poshgit\dahlbyk-posh-git-18d600a\profile.example.ps1"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $true
        }
        It 'Returns false when one-line profile script does not import posh-git' {
            $profileContent = "# Test"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $false
        }
        It 'Returns false when profile script does not import posh-git' {
            $profileContent = "Import-Module Pscx`nImport-Module platyPS`nImport-Module Plaster"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $false
        }
    }

    Context 'Test-InPSModulePath Tests' {
        It 'Returns false for install not under any PSModulePaths' {
            Mock Get-PSModulePath { }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0\"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns true for install under single PSModulePath' {
            Mock Get-PSModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\'
            }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns true for install under multiple PSModulePaths' {
            Mock Get-PSModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0\',
                       'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.6.1.20160330\'
            }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is not under PSModulePaths' {
            Mock Get-PSModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0\',
                       'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.6.1.20160330\'
            }
            $path = "C:\tools\posh-git\dahlbyk-posh-git-18d600a"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is under PSModulePath, but in a src directory' {
            Mock Get-PSModulePath {
                return 'C:\GitHub'
            }
            $path = "C:\GitHub\posh-git\src"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
    }
}
