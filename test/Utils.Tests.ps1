. $PSScriptRoot\Shared.ps1
. $modulePath\Utils.ps1

$expectedEncoding = if ($PSVersionTable.PSVersion.Major -le 5) { "utf8" } else { "ascii" }

Describe 'Utils Function Tests' {
    Context 'Add-PoshGitToProfile Tests' {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $newLine = [System.Environment]::NewLine
        }
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -Recurse -ErrorAction SilentlyContinue
        }
        It 'Creates profile file if it does not exist that imports absolute path' {
            Mock Get-PSModulePath {
                 return @()
            }
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            Add-PoshGitToProfile $profilePath

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be $expectedEncoding
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            $nativePath = MakeNativePath $modulePath\posh-git.psd1
            @($content)[1] | Should BeExactly "Import-Module '$nativePath'"
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
            Get-FileEncoding $profilePath | Should Be $expectedEncoding
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            @($content)[1] | Should BeExactly "Import-Module posh-git"
        }
        It 'Creates profile file if the profile dir does not exist' {
            # Use $profilePath as missing parent directory (auto-cleanup)
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            $childProfilePath = Join-Path $profilePath profile.ps1

            Add-PoshGitToProfile $childProfilePath

            Test-Path -LiteralPath $childProfilePath | Should Be $true
            $childProfilePath | Should FileContentMatch "^Import-Module .*posh-git"
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
            $nativeContent = Convert-NativeLineEnding $profileContent
            $content -join $newline | Should BeExactly $nativeContent
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
            $nativeContent = Convert-NativeLineEnding $profileContent
            $nativeContent += "${newLine}${newLine}Import-Module posh-git"
            $content -join $newLine | Should BeExactly $nativeContent
        }
        It 'Adds Start-SshAgent if posh-git is not installed' {
            Add-PoshGitToProfile $profilePath -StartSshAgent

            Test-Path -LiteralPath $profilePath | Should Be $true
            $last = Get-Content $profilePath | Select-Object -Last 1
            $last | Should BeExactly "Start-SshAgent -Quiet"
        }
        It 'Does not add Start-SshAgent if posh-git is installed' {
            $profileContent = 'Import-Module posh-git'
            Set-Content $profilePath -Value $profileContent

            Add-PoshGitToProfile $profilePath -StartSshAgent

            Test-Path -LiteralPath $profilePath | Should Be $true
            $content = Get-Content $profilePath
            $content | Should BeExactly $profileContent
        }
    }

    Context 'Test-PoshGitImportedInScript Tests' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
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
                return MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"
            }
            $path = MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns true for install under multiple PSModulePaths' {
            Mock Get-PSModulePath {
                return (MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"),
                       (MakeNativePath "$HOME\GitHub\dahlbyk\posh-git\0.6.1.20160330\")
            }
            $path = MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is not under PSModulePaths' {
            Mock Get-PSModulePath {
                return (MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"),
                       (MakeNativePath "$HOME\GitHub\dahlbyk\posh-git\0.6.1.20160330\")
            }
            $path = MakeNativePath "\tools\posh-git\dahlbyk-posh-git-18d600a"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is under PSModulePath, but in a src directory' {
            Mock Get-PSModulePath {
                return MakeNativePath '\GitHub'
            }
            $path = MakeNativePath "\GitHub\posh-git\src"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
    }

    Context 'Get-GitRemotes Tests' {
        It 'Returns the remote object with correct name and url' {
            $remotes = Get-GitRemotes
    
            $remotes[0].Name | Should Be "origin"
            $remotes[0].Url | Should BeLike "*github*"
        }
    
        It 'Returns a list of 2 with 2 remotes' {
            Mock -ModuleName posh-git git {
                if ($args -contains 'get-url') {
                    return "git@" + $args[2] + ".url"
                } 
                elseif ($args -contains 'remote') {
                    return @('foo', 'bar')
                }
            }
            $remotes = Get-GitRemotes

            $remotes.Length | Should Be 2
            $remotes[0].Name | Should Be 'foo'
            $remotes[0].Url | Should Be 'git@foo.url'
            $remotes[1].Name | Should Be 'bar'
            $remotes[1].Url | Should Be 'git@bar.url'
        }

        It 'Returns valid objects with weird branch names' {
            Mock -ModuleName posh-git git {
                if ($args -contains 'get-url') {
                    return "git@" + $args[2] + ".url"
                }
                elseif ($args -contains 'remote') {
                    return @('foo/w3ird-br@nch')
                }
            }
            $remotes = Get-GitRemotes

            $remotes.Length | Should Be 1
            $remotes[0].Name | Should Be 'foo/w3ird-br@nch'
            $remotes[0].Url | Should Be 'git@foo/w3ird-br@nch.url'
        }

        It 'Returns empty list when no remotes are present' {
            Mock -ModuleName posh-git git {
                if ($args -contains 'remote') {
                    return $null
                }
            }
            $remotes = Get-GitRemotes

            $remotes.Length | Should Be 0
        }
    }
}
