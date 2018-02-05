. $PSScriptRoot\Shared.ps1

Describe 'Default Prompt Tests - NO ANSI' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $prompt = Get-Item Function:\prompt
        $OFS = ''
    }
    BeforeEach {
        # Ensure these settings start out set to the default values
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
        $GitPromptSettings.AnsiConsole = $false
    }

    Context 'Prompt with no Git summary' {
        It 'Returns the expected prompt string' {
            Set-Location $env:HOME -ErrorAction Stop
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${env:HOME}> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = 'PS '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "PS ${Home}> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "[$(hostname)] $Home> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = '`n> '
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$Home`n> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
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
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
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
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
A  test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
 M test/Baz.Tests.ps1

'@
            }

            $res = [string](&$prompt 6>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $res | Should BeExactly "$PSScriptRoot [master +1 ~0 -0 | +0 ~1 -1 !]> "
        }
    }
}

Describe 'Default Prompt Tests - ANSI' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $prompt = Get-Item Function:\prompt
        $OFS = ''
    }
    BeforeEach {
        # Ensure these settings start out set to the default values
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
        $GitPromptSettings.AnsiConsole = $true
    }

    Context 'Prompt with no Git summary' {
        It 'Returns the expected prompt string' {
            Set-Location $env:HOME -ErrorAction Stop
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${env:HOME}> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = '`n> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptSuffix.BackgroundColor = 0xFF6000 # Orange
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$Home${csi}34m${csi}48;2;255;96;0m`n> ${csi}0m"
        }
        It 'Returns the expected prompt string with expanded DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptSuffix.BackgroundColor = 0xFF6000 # Orange
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "$Home${csi}34m${csi}48;2;255;96;0m - 42> ${csi}0m"
        }
        It 'Returns the expected prompt string with changed DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = 'PS '
            $GitPromptSettings.DefaultPromptPrefix.BackgroundColor = [ConsoleColor]::White
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${csi}107mPS ${csi}0m${Home}> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptPrefix.BackgroundColor = 0xF5F5F5
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${csi}48;2;245;245;245m[$(hostname)] ${csi}0m$Home> "
        }
        It 'Returns the expected prompt path colors' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::DarkCyan
            $GitPromptSettings.DefaultPromptPath.BackgroundColor = [ConsoleColor]::DarkRed
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${csi}36m${csi}41m~${csi}0m> "
        }
        It 'Returns the expected prompt string with prefix, suffix and abbrev home set' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = 0xF5F5F5
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = [string](&$prompt 6>&1)
            $res | Should BeExactly "${csi}38;2;245;245;245m[$(hostname)] ${csi}0m~${csi}34m - 42> ${csi}0m"
        }
        It 'Returns the expected prompt string with prompt timing enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptEnableTiming = $true
            $GitPromptSettings.DefaultPromptTimingColor.ForegroundColor = [System.ConsoleColor]::Magenta
            $res = [string](&$prompt 6>&1)
            $escapedHome = [regex]::Escape($Home)
            $rexcsi = [regex]::Escape($csi)
            $res | Should Match "$escapedHome${rexcsi}95m${rexcsi}49m \d+ms${rexcsi}0m> "
        }
    }

    Context 'Prompt with Git summary' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the expected prompt string with status' {
            Mock -ModuleName posh-git git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master
A  test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
 M test/Baz.Tests.ps1

'@
            }

            $res = [string](&$prompt 6>&1)
            Assert-MockCalled git -ModuleName posh-git
            $res | Should BeExactly "$PSScriptRoot${csi}93m [${csi}0m${csi}96mmaster${csi}0m${csi}32m${csi}0m${csi}32m${csi}49m +1${csi}0m${csi}32m${csi}49m ~0${csi}0m${csi}32m${csi}49m -0${csi}0m${csi}93m |${csi}0m${csi}31m${csi}49m +0${csi}0m${csi}31m${csi}49m ~1${csi}0m${csi}31m${csi}49m -1${csi}0m${csi}31m !${csi}0m${csi}93m]${csi}0m> "
        }
    }
}

Describe 'Default Prompt WindowTitle Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if (!(& $module {$WindowTitleSupported})) {
            Write-Warning "Current PowerShell Host does not support changing its WindowTitle."
            $PSDefaultParameterValues["it:skip"] = $true
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $repoAdminRegex = '^Administrator: posh~git ~ posh-git \[master\] ~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $repoRegex = '^posh~git ~ posh-git \[master\] ~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $nonRepoAdminRegex = '^Administrator: PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $nonRepoRegex = '^PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \(\d+\)$'
    }
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
    BeforeEach {
        # Ensure these settings start out set to the default values as the module only grabs
        # $global:PreviousWindowTitle once when the module and that happens just once for this whole test file.
        $defaultTitle = if ($IsWindows) { "Windows PowerShell" } else { "PowerShell-$($PSVersionTable.PSVersion)" }
        $Host.UI.RawUI.WindowTitle = $defaultTitle
        $global:PreviousWindowTitle = $defaultTitle
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
    }

    Context 'In a Git repo' {
        Mock -ModuleName posh-git -CommandName git {
            $OFS = " "
            if ($args -contains 'rev-parse') {
                $res = Invoke-Expression "&$gitbin $args"
                return $res
            }
            Convert-NativeLineEnding -SplitLines @'
## master
A  test/Foo.Tests.ps1
D test/Bar.Tests.ps1
M test/Baz.Tests.ps1

'@
        }

        It 'Default GitPromptSettings.WindowTitle sets the expected Window title text' {
            Set-Location $PSScriptRoot
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $repoAdminRegex
            }
            else {
                $title | Should Match $repoRegex
            }
        }

        It 'Custom GitPromptSettings.WindowTitle scriptblock sets the expected Window title text' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = {
                param($s, $admin)
                "$(if ($admin) {'daboss:'} else {'loser:'}) poshgit == $($s.RepoName) / $($s.Branch)"
            }
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match '^daboss: poshgit == posh-git / master$'
            }
            else {
                $title | Should Match '^loser: poshgit == posh-git / master$'
            }
        }

        It 'Custom GitPromptSettings.WindowTitle single quoted string sets the expected Window title text' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = '$(if ($IsAdmin) {"daboss:"} else {"loser:"}) poshgit == $($GitStatus.RepoName) / $($GitStatus.Branch)'
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match '^daboss: poshgit == posh-git / master$'
            }
            else {
                $title | Should Match '^loser: poshgit == posh-git / master$'
            }
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is $null' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = $null
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is $false' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = $false
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is ""' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = ''
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }
    }

    Context 'Not in a Git repo' {
        It 'Does not display posh-git status info in Window title when not in a Git repo' {
            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }
        }
    }

    Context 'Moving in and out of a Git repo' {
        Mock -ModuleName posh-git -CommandName git {
            $OFS = " "
            if ($args -contains 'rev-parse') {
                $res = Invoke-Expression "&$gitbin $args"
                return $res
            }
            Convert-NativeLineEnding -SplitLines @'
## master
A  test/Foo.Tests.ps1
D test/Bar.Tests.ps1
M test/Baz.Tests.ps1

'@
        }

        It 'Displays the correct Window title as we move in and out of a Git repo' {
            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }

            Set-Location $PSScriptRoot
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $repoAdminRegex
            }
            else {
                $title | Should Match $repoRegex
            }

            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }
        }

        # This test must be the last test in this file
        Context 'Removing the posh-git module' {
            It 'Correctly reverts the Window Title back to original state' {
                Set-Item function:\prompt -Value ([Runspace]::DefaultRunspace.InitialSessionState.Commands['prompt']).Definition
                Remove-Module posh-git -Force *>$null
                $title = $Host.UI.RawUI.WindowTitle
                $title | Should Match '^(Windows )?PowerShell'
            }
        }
    }
}
