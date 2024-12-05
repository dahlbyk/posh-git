BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Write-VcsStatus Tests' {
    BeforeAll {
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
    }

    Context 'AnsiConsole disabled' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.AnsiConsole = $false
        }

        It 'Returns no output from Write-VcsStatus' {
            # Verify that we are getting write-host output first
            $OFS = ''
            $res = Write-VcsStatus 6>&1
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            "$res" | Should -BeExactly " [master +1 ~0 -0 ~]"

            # Verify that there is no return value i.e. we get $null
            $res = Write-VcsStatus 6>$null
            $res | Should -BeExactly $null
        }
    }

    Context 'AnsiConsole enabled' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.AnsiConsole = $true
        }

        It 'Returns status output from Write-VcsStatus as string' {
            $res = Write-VcsStatus
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $res | Should -BeExactly " ${csi}93m[${csi}39m${csi}96mmaster${csi}39m${csi}32m +1${csi}39m${csi}32m ~0${csi}39m${csi}32m -0${csi}39m${csi}96m ~${csi}39m${csi}93m]${csi}39m"
        }
    }
}

Describe 'Write-GitRemoteRepositoryLabel Tests' {
    Context 'RemoteNamePlacement having a value of `"Start"` with single segment branch name' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.RemoteNamePlacement = "Start"
            $GitPromptSettings.RemoteNameSymbol = "/"

            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master...origin/master
'@
            }
        }

        It 'Should write repository name followed by seperator' {
            $res = Write-GitRemoteRepositoryLabel (Get-GitStatus)
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $res | Should -BeExactly "origin/"
        }
    }

    Context 'RemoteNamePlacement having a value of `"Start"` with multi segment branch name' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.RemoteNamePlacement = "Start"
            $GitPromptSettings.RemoteNameSymbol = "/"

            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## development/master...origin/development/master
'@
            }
        }

        It 'Should write repository name followed by seperator' {
            $res = Write-GitRemoteRepositoryLabel (Get-GitStatus)
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $res | Should -BeExactly "origin/"
        }
    }

    Context 'RemoteNamePlacement having a value of `"End"` with single segment branch name' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.RemoteNamePlacement = "End"
            $GitPromptSettings.RemoteNameSymbol = " -> "

            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master...origin/master
'@
            }
        }

        It 'Should write seperator followed by repository name' {
            $res = Write-GitRemoteRepositoryLabel (Get-GitStatus)
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $res | Should -BeExactly " -> origin"
        }
    }

    Context 'RemoteNamePlacement having a value of `"None"`' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = New-GitPromptSettings
            $GitPromptSettings.RemoteNamePlacement = "None"
            $GitPromptSettings.RemoteNameSymbol = "/"

            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'
## master...origin/master
'@
            }
        }

        It 'Should not return any sort of truthy' {
            $res = Write-GitRemoteRepositoryLabel (Get-GitStatus)
            Should -Invoke -ModuleName posh-git -CommandName git -Exactly 1
            $res | Should -BeNullOrEmpty
        }
    }
}
