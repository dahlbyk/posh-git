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
function Get-ForegroundVirtualTerminalSequence($Color) {
    $e = [char]27 + "["
    switch ($Color) {
      ([ConsoleColor]::Black)       { "${e}30m" }
      ([ConsoleColor]::DarkRed)     { "${e}31m" }
      ([ConsoleColor]::DarkGreen)   { "${e}32m" }
      ([ConsoleColor]::DarkYellow)  { "${e}33m" }
      ([ConsoleColor]::DarkBlue)    { "${e}34m" }
      ([ConsoleColor]::DarkMagenta) { "${e}35m" }
      ([ConsoleColor]::DarkCyan)    { "${e}36m" }
      ([ConsoleColor]::Gray)        { "${e}37m" }
      ([ConsoleColor]::DarkGray)    { "${e}90m" }
      ([ConsoleColor]::Red)         { "${e}91m" }
      ([ConsoleColor]::Green)       { "${e}92m" }
      ([ConsoleColor]::Yellow)      { "${e}93m" }
      ([ConsoleColor]::Blue)        { "${e}94m" }
      ([ConsoleColor]::Magenta)     { "${e}95m" }
      ([ConsoleColor]::Cyan)        { "${e}96m" }
      ([ConsoleColor]::White)       { "${e}97m" }
      default                       { "${e}39m" }
    }
}

function Get-BackgroundVirtualTerminalSequence($Color) {
    $e = [char]27 + "["
    switch ($Color) {
      ([ConsoleColor]::Black)       { "${e}40m" }
      ([ConsoleColor]::DarkRed)     { "${e}41m" }
      ([ConsoleColor]::DarkGreen)   { "${e}42m" }
      ([ConsoleColor]::DarkYellow)  { "${e}43m" }
      ([ConsoleColor]::DarkBlue)    { "${e}44m" }
      ([ConsoleColor]::DarkMagenta) { "${e}45m" }
      ([ConsoleColor]::DarkCyan)    { "${e}46m" }
      ([ConsoleColor]::Gray)        { "${e}47m" }
      ([ConsoleColor]::DarkGray)    { "${e}100m" }
      ([ConsoleColor]::Red)         { "${e}101m" }
      ([ConsoleColor]::Green)       { "${e}102m" }
      ([ConsoleColor]::Yellow)      { "${e}103m" }
      ([ConsoleColor]::Blue)        { "${e}104m" }
      ([ConsoleColor]::Magenta)     { "${e}105m" }
      ([ConsoleColor]::Cyan)        { "${e}106m" }
      ([ConsoleColor]::White)       { "${e}107m" }
      default                       { "${e}49m" }
    }
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
