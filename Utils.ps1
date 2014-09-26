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

function Get-CaseSensitivePath{
    param($pathName)

    $pathExists = Test-Path($pathName)
    if (-Not $pathExists){
        return $pathName
    }

    $directoryInfo = New-Object IO.DirectoryInfo($pathName)
    
    if ($directoryInfo.Parent -ne $null){
        $parentPath = Get-CaseSensitivePath($directoryInfo.Parent.FullName)
        $childPath = $directoryInfo.Parent.GetFileSystemInfos($directoryInfo.Name)[0].Name
        return(Join-Path $parentPath $childpath -resolv)
    }else{
        return $directoryInfo.Name
    }
}