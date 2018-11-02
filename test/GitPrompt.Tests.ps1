. $PSScriptRoot\Shared.ps1

Describe 'Write-VcsStatus Tests' {
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

    Context 'AnsiConsole disabled' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
            $GitPromptSettings.AnsiConsole = $false
        }

        It 'Returns no output from Write-VcsStatus' {
            # Verify that we are getting write-host output first
            $OFS = ''
            $res = Write-VcsStatus 6>&1
            "$res" | Should BeExactly " [master +1 ~0 -0 ~]"

            # Verify that there is no return value i.e. we get $null
            $res = Write-VcsStatus 6>$null
            $res | Should BeExactly $null
        }
    }

    Context 'AnsiConsole enabled' {
        BeforeAll {
            # Ensure these settings start out set to the default values
            $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
            $GitPromptSettings.AnsiConsole = $true
        }

        It 'Returns status output from Write-VcsStatus as string' {
            $res = Write-VcsStatus
            $res | Should BeExactly " ${csi}93m[${csi}0m${csi}96mmaster${csi}0m${csi}32m${csi}49m +1${csi}0m${csi}32m${csi}49m ~0${csi}0m${csi}32m${csi}49m -0${csi}0m${csi}96m ~${csi}0m${csi}93m]${csi}0m"
        }
    }
}
