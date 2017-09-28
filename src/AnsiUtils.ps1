# Color codes from https://msdn.microsoft.com/en-us/library/windows/desktop/mt638032(v=vs.85).aspx
$ConsoleColorToAnsi = @(
    30 # Black
    34 # DarkBlue
    32 # DarkGreen
    36 # DarkCyan
    31 # DarkRed
    35 # DarkMagenta
    33 # DarkYellow
    37 # Gray
    90 # DarkGray
    94 # Blue
    92 # Green
    96 # Cyan
    91 # Red
    95 # Magenta
    93 # Yellow
    97 # White
)
$AnsiDefaultColor = 39
$AnsiEscape = [char]27 + "["

[Reflection.Assembly]::LoadWithPartialName('System.Drawing') > $null
$ColorTranslatorType = 'System.Drawing.ColorTranslator' -as [Type]
$ColorType = 'System.Drawing.Color' -as [Type]

function Get-VirtualTerminalSequence ($color, [int]$offset = 0) {
    if ($color -is [byte]) {
        return "${AnsiEscape}$(38 + $offset);5;${color}m"
    }
    if ($color -is [String]) {
        try {
            if ($ColorTranslatorType) {
                $color = $ColorTranslatorType::FromHtml($color)
            }
            else {
                $color = [ConsoleColor]$color
            }
        }
        catch {
            Write-Debug $_
        }
    }
    if ($ColorType -and ($color -is $ColorType)) {
        return "${AnsiEscape}$(38 + $offset);2;$($color.R);$($color.G);$($color.B)m"
    }
    if (($color -is [ConsoleColor]) -and ($color -ge 0) -and ($color -le 15)) {
        return "${AnsiEscape}$($ConsoleColorToAnsi[$color] + $offset)m"
    }
    return "${AnsiEscape}$($AnsiDefaultColor + $offset)m"
}

function Get-ForegroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color
}

function Get-BackgroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color 10
}
