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

function EscapeAnsiString([string]$AnsiString) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $res = $AnsiString -replace "$([char]27)", '`e'
    }
    else {
        $res = $AnsiString -replace "$([char]27)", '$([char]27)'
    }

    $res
}

function Test-VirtualTerminalSequece([psobject[]]$Object, [switch]$Force) {
    foreach ($obj in $Object) {
        if (($Force -or $global:GitPromptSettings.AnsiConsole) -and ($obj -is [string])) {
            $obj.Contains($AnsiEscape)
        }
        else {
            $false
        }
    }
}

function Get-VirtualTerminalSequence ($color, [int]$offset = 0) {
    # Don't output ANSI escape sequences if the `$color` parameter is `$null`,
    # they would be broken anyway
    if ($null -eq $color) {
        return $null;
    }

    if ($color -is [byte]) {
        return "${AnsiEscape}$(38 + $offset);5;${color}m"
    }

    if ($color -is [int]) {
        $r = ($color -shr 16) -band 0xff
        $g = ($color -shr 8) -band 0xff
        $b = $color -band 0xff
        return "${AnsiEscape}$(38 + $offset);2;${r};${g};${b}m"
    }

    # Force 'DarkYellow' to ConsoleColor, since it is not an HTML color
    if ($color -eq [System.ConsoleColor]::DarkYellow) {
        $color = [System.ConsoleColor]::DarkYellow
    }
    elseif ($color -is [String]) {
        try {
            if ($ColorTranslatorType) {
                $color = $ColorTranslatorType::FromHtml($color)
            }
        }
        catch {
            Write-Debug $_
        }
    }

    if ($ColorType -and ($color -is $ColorType)) {
        return "${AnsiEscape}$(38 + $offset);2;$($color.R);$($color.G);$($color.B)m"
    }

    if (($color -is [System.ConsoleColor]) -and ($color -ge 0) -and ($color -le 15)) {
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
