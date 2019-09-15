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
    }

    Context 'Get-PromptConnectionInfo' {
        BeforeEach {
            if (Test-Path Env:SSH_CONNECTION) {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
                $ssh_connection = $Env:SSH_CONNECTION

                Remove-Item Env:SSH_CONNECTION
            }
        }
        AfterEach {
            if ($ssh_connection) {
                Set-Item Env:SSH_CONNECTION $ssh_connection
            } elseif (Test-Path Env:SSH_CONNECTION) {
                Remove-Item Env:SSH_CONNECTION
            }
        }
        It 'Returns null if Env:SSH_CONNECTION is not set' {
            Get-PromptConnectionInfo | Should BeExactly $null
        }
        It 'Returns null if Env:SSH_CONNECTION is empty' {
            Set-Item Env:SSH_CONNECTION ''

            Get-PromptConnectionInfo | Should BeExactly $null
        }
        It 'Returns "[username@hostname]: " if Env:SSH_CONNECTION is set' {
            Set-Item Env:SSH_CONNECTION 'test'

            Get-PromptConnectionInfo | Should BeExactly "[$([System.Environment]::UserName)@$([System.Environment]::MachineName)]: "
        }
        It 'Returns formatted string if Env:SSH_CONNECTION is set with -Format' {
            Set-Item Env:SSH_CONNECTION 'test'

            Get-PromptConnectionInfo -Format "[{0}]({1}) " | Should BeExactly "[$([System.Environment]::MachineName)]($([System.Environment]::UserName)) "
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
}
