# General Utility Functions

function Invoke-NullCoalescing {
    $result = $null
    foreach($arg in $args) {
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

function Invoke-Utf8ConsoleCommand([ScriptBlock]$cmd) {
    $currentEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [Text.Encoding]::UTF8
        & $cmd
    }
    finally {
        [Console]::OutputEncoding = $currentEncoding
    }
}

function Add-ImportModuleToProfile {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProfilePath,

        # This is only required to support PS v2 there $PSScriptRoot only works in a .psm1 file
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleBasePath
    )

    # Check if profile script exists
    if (Test-Path -LiteralPath $profilePath) {
        $profileContent = @(Get-Content -LiteralPath $profilePath)
        $profileContent += [string]::Empty # Empty line between previous profile script and import statement
        $encoding = Get-FileEncoding $profilePath
    }
    else {
        # Doesn't exist, so create it
        New-Item -Path $profilePath -ItemType File
        $profileContent = @()
        $encoding = 'utf8'
    }

    # Check if the location of this module file is in the PSModulePath
    if (Test-InPSModulePath $ModuleBasePath) {
        $profileContent += "Import-Module posh-git"
    }
    else {
        $profileContent += "Import-Module '$ModuleBasePath\posh-git.psd1'"
    }

    Set-Content -LiteralPath $profilePath -Value $profileContent -Encoding $encoding
}

<#
.SYNOPSIS
    Gets the file encoding of the specified file.
.DESCRIPTION
    Gets the file encoding of the specified file.
.PARAMETER Path
    Path to the file to check.  The file must exist.
.EXAMPLE
    PS C:\> Get-FileEncoding $profile
    Get's the file encoding of the profile file.
.INPUTS
    None.
.OUTPUTS
    [System.String]
.NOTES
    Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx
#>
function Get-FileEncoding($Path) {
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if (!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

<#
.SYNOPSIS
    Gets a StringComparison enum value appropriate for comparing paths on the OS platform.
.DESCRIPTION
    Gets a StringComparison enum value appropriate for comparing paths on the OS platform.
.EXAMPLE
    PS C:\> $pathStringComparison = Get-PathStringComparison
.INPUTS
    None
.OUTPUTS
    [System.StringComparison]
#>
function Get-PathStringComparison {
    # File system paths are case-sensitive on Linux and case-insensitive on Windows and macOS
    if (($PSVersionTable.PSVersion.Major -ge 6) -and $IsLinux) {
        [System.StringComparison]::Ordinal
    }
    else {
        [System.StringComparison]::OrdinalIgnoreCase
    }
}

function Get-LocalOrParentPath($path) {
    $checkIn = Get-Item -Force .
    if ($checkIn.PSProvider.Name -ne 'FileSystem') {
        return $null
    }
    while ($null -ne $checkIn) {
        $pathToTest = [System.IO.Path]::Combine($checkIn.fullname, $path)
        if (Test-Path -LiteralPath $pathToTest) {
            return $pathToTest
        }
        else {
            $checkIn = $checkIn.parent
        }
    }
    return $null
}

function Get-PoshGitModulePath {
    Get-Module posh-git -ListAvailable | ForEach-Object { $_.ModuleBase }
}

function Test-InPSModulePath {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Path
    )

    $modulePaths = Get-PoshGitModulePath
    if (!$modulePaths) { return $false }

    $pathStringComparison = Get-PathStringComparison
    $inModulePath = @($modulePaths | Where-Object { $Path.StartsWith($_, $pathStringComparison) }).Count -gt 0
    $inModulePath
}

function Test-PoshGitImportedInScript {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $Path
    )

    if (!$Path -or !(Test-Path -LiteralPath $Path)) {
        return $false
    }

    @((Get-Content $Path -ErrorAction SilentlyContinue) -match 'posh-git').Count -gt 0
}

function dbg($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if ($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
