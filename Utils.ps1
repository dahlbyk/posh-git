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

Set-Alias ?? Coalesce-Args -Force

function Get-LocalOrParentPath($path) {
    $checkIn = Get-Item .
    while ($checkIn -ne $NULL) {
        $pathToTest = [System.IO.Path]::Combine($checkIn.fullname, $path)
        if (Test-Path $pathToTest) {
            return $pathToTest
        } else {
            $checkIn = $checkIn.parent
        }
    }
    return $null
}

function fixUI($color = 'Gray') {
  # At times via posh-git the GUI color gets out of whach - this function fixes it quickly and easily
  $host.UI.RawUI.ForegroundColor = $color
}
