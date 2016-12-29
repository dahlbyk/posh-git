# General Utility Functions

function Invoke-NullCoalescing {
    $result = $null
    foreach($arg in $args) {
        if ($arg -is [ScriptBlock]) {
            $result = & $arg
        } else {
            $result = $arg
        }
        if ($result) { break }
    }
    $result
}

Set-Alias ?? Invoke-NullCoalescing -Force

function Get-LocalOrParentPath($path) {
    $checkIn = Get-Item -Force .
    if ($checkIn.PSProvider.Name -ne 'FileSystem') {
        return $null
    }
    while ($checkIn -ne $NULL) {
        $pathToTest = [System.IO.Path]::Combine($checkIn.fullname, $path)
        if (Test-Path -LiteralPath $pathToTest) {
            return $pathToTest
        } else {
            $checkIn = $checkIn.parent
        }
    }
    return $null
}

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

function Get-VirtualTerminalSequence ([ConsoleColor]$color, [int]$offset = 0) {
    if (($color -lt 0) -or ($color -gt 15)) {
        return "${AnsiEscape}$($AnsiDefaultColor + $offset)m"
    }
    return "${AnsiEscape}$($ConsoleColorToAnsi[$color] + $offset)m"
}

function Get-ForegroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color
}

function Get-BackgroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color 10
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
