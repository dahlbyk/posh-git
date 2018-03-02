. $PSScriptRoot\Shared.ps1

Describe 'ANSI Tests' {
    Context 'Returns correct ANSI sequence for specified colors' {
        It 'Setting BackgroundColor to 0x0 results in Black background' {
            $ts = & $module.NewBoundScriptBlock({[PoshGitTextSpan]::new("TEST", 0xFF0000, 0)})
            $ansiStr = $ts.toAnsiString()
            $ansiStr | Should BeExactly "${csi}38;2;255;0;0m${csi}48;2;0;0;0mTEST${csi}0m"
        }
        It 'Setting ForegroundColor to 0x0 results in Black foreground' {
            $ts = & $module.NewBoundScriptBlock({[PoshGitTextSpan]::new("TEST", 0, 0xFFFFFF)})
            $ansiStr = $ts.toAnsiString()
            $ansiStr | Should BeExactly "${csi}38;2;0;0;0m${csi}48;2;255;255;255mTEST${csi}0m"
        }
    }
}
