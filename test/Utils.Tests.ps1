. $PSScriptRoot\..\Utils.ps1

Describe 'Utils Function Tests' {
    Context 'Add-ImportModuleToProfile Tests' {
        BeforeAll {
           $newLine = [System.Environment]::NewLine
        }
        BeforeEach {
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -ErrorAction SilentlyContinue
        }
        It 'Creates profile file if it does not exist' {
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false
            $scriptRoot = Split-Path $profilePath -Parent
            Add-ImportModuleToProfile $profilePath $scriptRoot
            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'utf8'
            $content = Get-Content $profilePath
            $content.Count | Should Be 1
            @($content)[0] | Should BeExactly "Import-Module '$scriptRoot\posh-git.psd1'"
        }
        It 'Modifies existing (Unicode) profile file correctly' {
            $profileContent = @'
Import-Module PSCX

New-Alias pscore C:\Users\Keith\GitHub\rkeithhill\PowerShell\src\powershell-win-core\bin\Debug\netcoreapp1.1\win10-x64\powershell.exe
'@
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            $scriptRoot = Split-Path $profilePath -Parent
            Add-ImportModuleToProfile $profilePath $scriptRoot
            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'unicode'
            $content = Get-Content $profilePath
            $content.Count | Should Be 5
            $profileContent += "${newLine}${newLine}Import-Module '$scriptRoot\posh-git.psd1'"
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
        It 'Returns false when profile script does not import posh-git' {
            $profileContent = "Import-Module Pscx`nImport-Module platyPS`nImport-Module Plaster"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $false
        }
    }

    Context 'Test-InPSModulePath Tests' {
        It 'Returns false for install not under any PSModulePaths' {
            Mock Get-PoshGitModulePath { }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PoshGitModulePath
        }
        It 'Returns true for install under single PSModulePath' {
            Mock Get-PoshGitModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0'
            }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PoshGitModulePath
        }
        It 'Returns true for install under multiple PSModulePaths' {
            Mock Get-PoshGitModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0',
                       'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.6.1.20160330'
            }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PoshGitModulePath
        }
        It 'Returns false when current posh-git module location is not under PSModulePaths' {
            Mock Get-PoshGitModulePath {
                return 'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0',
                       'C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.6.1.20160330'
            }
            $path = "C:\tools\posh-git\dahlbyk-posh-git-18d600a"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PoshGitModulePath
        }
    }
}
