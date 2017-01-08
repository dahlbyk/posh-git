. $PSScriptRoot\..\Utils.ps1

Describe 'Utils Function Tests' {
    Context 'Add-ImportModuleToProfile Tests' {
        BeforeAll {
           $newLine = [System.Environment]::NewLine
        }
        It 'Creates profile file if it does not exist' {
            $profilePath = [System.IO.Path]::GetTempFileName()
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false
            try {
                $scriptRoot = Split-Path $profilePath -Parent
                Add-ImportModuleToProfile $profilePath $scriptRoot
                Test-Path -LiteralPath $profilePath | Should Be $true
                Get-FileEncoding $profilePath | Should Be 'ascii'
                $content = Get-Content $profilePath
                $content.Count | Should Be 1
                @($content)[0] | Should BeExactly "Import-Module '$scriptRoot\posh-git.psd1'"
            }
            finally {
                Remove-Item $profilePath -ErrorAction SilentlyContinue
            }
        }
        It 'Modifies existing (Unicode) profile file correctly' {
            $profilePath = [System.IO.Path]::GetTempFileName()
            $profileContent = @'
Import-Module PSCX

New-Alias pscore C:\Users\Keith\GitHub\rkeithhill\PowerShell\src\powershell-win-core\bin\Debug\netcoreapp1.1\win10-x64\powershell.exe
'@
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            try {
                $scriptRoot = Split-Path $profilePath -Parent
                Add-ImportModuleToProfile $profilePath $scriptRoot
                Test-Path -LiteralPath $profilePath | Should Be $true
                Get-FileEncoding $profilePath | Should Be 'unicode'
                $content = Get-Content $profilePath
                $content.Count | Should Be 5
                $profileContent += "${newLine}${newLine}Import-Module '$scriptRoot\posh-git.psd1'"
                $content -join $newLine | Should BeExactly $profileContent
            }
            finally {
                Remove-Item $profilePath -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Test-PoshGitImportedInScript Tests' {
        It 'Detects Import-Module posh-git in profile script' {
            $profilePath = [System.IO.Path]::GetTempFileName()
            $profileContent = "Import-Module posh-git"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            try {
                Test-PoshGitImportedInScript $profilePath | Should Be $true
            }
            finally {
                Remove-Item $profilePath -ErrorAction SilentlyContinue
            }
        }
        It 'Detects chocolatey installed line in profile script' {
            $profilePath = [System.IO.Path]::GetTempFileName()
            $profileContent = ". 'C:\tools\poshgit\dahlbyk-posh-git-18d600a\profile.example.ps1"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            try {
                Test-PoshGitImportedInScript $profilePath | Should Be $true
            }
            finally {
                Remove-Item $profilePath -ErrorAction SilentlyContinue
            }
        }
        It 'Returns false when profile script does not import posh-git' {
            $profilePath = [System.IO.Path]::GetTempFileName()
            $profileContent = "Import-Module Pscx`nImport-Module platyPS`nImport-Module Plaster"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            try {
                Test-PoshGitImportedInScript $profilePath | Should Be $false
            }
            finally {
                Remove-Item $profilePath -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Test-InModulePath Tests' {
        BeforeAll {
            $standardPSModulePath = "C:\Users\Keith\Documents\WindowsPowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\"
        }
        BeforeEach {
            $origPSModulePath = $env:PSModulePath
        }
        AfterEach {
            $env:PSModulePath = $origPSModulePath
        }
        It 'Works for install from PSGallery to current user modules location' {
            $env:PSModulePath = $standardPSModulePath
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InModulePath $path | Should Be $true
        }
        It 'Works for install from Chocolatey not in any modules path' {
            $env:PSModulePath = $standardPSModulePath
            $path = "C:\tools\posh-git\dahlbyk-posh-git-18d600a"
            Test-InModulePath $path | Should Be $false
        }
        It 'Works for running from posh-git Git repo and location not in modules path' {
            $env:PSModulePath = $standardPSModulePath
            $path = "C:\Users\Keith\GitHub\posh-git"
            Test-InModulePath $path | Should Be $false
        }
        It 'Returns false when PSModulePath is empty' {
            $env:PSModulePath = ''
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InModulePath $path | Should Be $false
        }
        It 'Returns false when PSModulePath is missing' {
            Remove-Item Env:\PSModulePath
            Test-Path Env:\PSModulePath | Should Be $false
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InModulePath $path | Should Be $false
        }
    }
}
