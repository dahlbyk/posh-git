# General Utility Functions

<#
.SYNOPSIS
    Returns first non-null value from the list of provided arguments.
.DESCRIPTION
    Iterates over the arguments one by one and evaluates them.
    Returns first one that evaluates to non-null value.
    If none of the arguments return a value, this method return null.
#>
function Invoke-NullCoalescing {
    $result = $null
    forEach($arg in $args) {
        if ($arg -is [ScriptBlock]) {
            $result = & $arg
        }
        else {
            $result = $arg
        }

        if ($result) { break }
    }
    $result
}

Set-Alias ?? Invoke-NullCoalescing -Force

function Get-LocalOrParentPath($path, $location) {
    $checkIn = Get-Item -Force (?? $Location .)
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

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
