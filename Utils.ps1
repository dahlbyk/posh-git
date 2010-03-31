# General Utility Functions

function Coalesce-Args {
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

Remove-Item alias:/`?`? -Force
Set-Alias ?? Coalesce-Args -Force

function Test-LocalOrParentPath($path) {
    $done = $false
    do {
        if (Test-Path $path) { return $true }
        if (Test-Path ..) { return $false }
        $path = "..\$path"
    } while (!$done)
    return $false
}
