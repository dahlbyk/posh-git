. $PSScriptRoot\Shared.ps1

Describe 'Default Prompt Tests' {
    BeforeAll {
        $prompt = Get-Item Function:\prompt
        $OFS = ''
    }
    BeforeEach {
        # Ensure these settings start out set to the default values
        $GitPromptSettings.DefaultPromptPrefix = ''
        $GitPromptSettings.DefaultPromptSuffix = '$(''>'' * ($nestedPromptLevel + 1)) '
        $GitPromptSettings.DefaultPromptDebugSuffix = ' [DBG]$(''>'' * ($nestedPromptLevel + 1)) '
        $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $false
        $GitPromptSettings.DefaultPromptEnableTiming = $false
    }

    Context 'Prompt with no Git summary' {
        It 'Returns the expected prompt string' {
            Set-Location $env:windir -ErrorAction Stop
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$env:windir> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix = 'PS '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "PS $Home> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix = '[$(hostname)] '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "[$(hostname)] $Home> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix = '`n> '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$Home`n> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix = ' - $(6*7)> '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$Home - 42> "
        }
        It 'Returns the expected prompt string with DefaultPromptAbbreviateHomeDirectory enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "~> "
        }
        It 'Returns the expected prompt string with prefix, suffix and abbrev home set' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptSuffix = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "[$(hostname)] ~ - 42> "
        }
        It 'Returns the expected prompt string with prompt timing enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptEnableTiming = $true
            $res = [string](&$prompt 6>&1)
            $escapedHome = [regex]::Escape($Home)
            $res | Should Match "$escapedHome \d+ms> "
        }
    }

    Context 'Prompt with Git summary' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the expected prompt string with status' {
            Mock git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "git.exe $args"
                    return $res
                }
                return @'
## master
A  test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
 M test/Baz.Tests.ps1

'@ -split [System.Environment]::NewLine
             } -ModuleName posh-git

            $res = [string](&$prompt 6>&1)
            Assert-MockCalled git -ModuleName posh-git
            $res | Should BeExactly "$PSScriptRoot [master +1 ~0 -0 | +0 ~1 -1 !]> "
        }
    }
}
