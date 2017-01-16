# Need this variable as long as we support PS v2
$ModuleBasePath = Split-Path $MyInvocation.MyCommand.Path -Parent

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

<#
.SYNOPSIS
    Configures your PowerShell profile (startup) script to import the posh-git
    module when PowerShell starts.
.DESCRIPTION
    Checks if your PowerShell profile script is not already importing posh-git
    and if not, adds a command to import the posh-git module. This will cause
    PowerShell to load posh-git whenever PowerShell starts.
    imprt
.PARAMETER AllHosts
    By default, this command modifies the CurrentUserCurrentHost profile
    script.  By specifying the AllHosts switch, the command updates the
    CurrentUserAllHosts profile.
.PARAMETER Force
    Do not check if the specified profile script is already importing
    posh-git. Just add Import-Module posh-git command.
.EXAMPLE
    PS C:\> Add-PoshGitToProfile
    Updates your profile script for the current PowerShell host to import the
    posh-git module when the current PowerShell host starts.
.EXAMPLE
    PS C:\> Add-PoshGitToProfile -AllHost
    Updates your profile script for all PowerShell hosts to import the posh-git
    module whenever any PowerShell host starts.
.INPUTS
    None.
.OUTPUTS
    None.
#>
function Add-PoshGitToProfile([switch]$AllHosts, [switch]$Force) {
    $underTest = $false

    $profilePath = if ($AllHosts) { $PROFILE.CurrentUserAllHosts } else { $PROFILE.CurrentUserCurrentHost }

    # Under test, we override some variables using $args as a backdoor.
    if ($args.Count -gt 0) {
        $profilePath = [string]$args[0]
        $underTest = $true
        if ($args.Count -gt 1) {
            $ModuleBasePath = [string]$args[1]
        }
    }

    if (!$Force) {
        # Search the user's profiles to see if any are using posh-git already, there is an extra search
        # ($profilePath) taking place to accomodate the Pester tests.
        $importedInProfile = Test-PoshGitImportedInScript $profilePath
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserCurrentHost
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserAllHosts
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersCurrentHost
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersAllHosts
        }

        if ($importedInProfile) {
            Write-Warning "Skipping add of posh-git import to file '$profilePath'."
            Write-Warning "posh-git appears to already be imported in one of your profile scripts."
            Write-Warning "If you want to force the add, use the -Force parameter."
            return
        }
    }

    # Check if the location of this module file is in the PSModulePath
    if (Test-InPSModulePath $ModuleBasePath) {
        $profileContent = "`nImport-Module posh-git"
    }
    else {
        $profileContent = "`nImport-Module '$ModuleBasePath\posh-git.psd1'"
    }

    Add-Content -LiteralPath $profilePath -Value $profileContent -Encoding UTF8
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

function Get-PSModulePath {
    $modulePaths = $Env:PSModulePath -split ';'
    $modulePaths
}

function Test-InPSModulePath {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Path
    )

    $modulePaths = Get-PSModulePath
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
