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
    while ($checkIn -ne $NULL) {
        $pathToTest = Join-Path $checkIn.fullname $path
        if (Test-Path -LiteralPath $pathToTest) {
            return $pathToTest
        } else {
            $checkIn = $checkIn.parent
        }
    }
    return $null
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
