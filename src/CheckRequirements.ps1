$global:GitMissing = $false
$script:GitCygwin = $false
$script:GitVersion = $requiredVersion = [System.Version]'2.15'

if (!(Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Warning "git command could not be found. Please create an alias or add it to your PATH."
    $global:GitMissing = $true
    return
}

function Test-GitVersion ($version = $([string](git --version 2> $null))) {
    if ($version -notmatch '(?<ver>\d+(?:\.\d+)+)(?<g4w>(?<rc>[-.]rc\d+)?\.windows|\.vfs)?') {
        Write-Warning "posh-git could not parse Git version ($version)"
        $script:GitVersion = $version
        return $false
    }

    # On Windows, check if Git is not "Git for Windows"
    if ((($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) -and !$Matches['g4w']) {
        $script:GitCygwin = $true

        if (!$Env:POSHGIT_CYGWIN_WARNING) {
            Write-Warning 'You appear to have an unsupported Git distribution; setting $GitPromptSettings.AnsiConsole = $false. posh-git recommends Git for Windows.'
        }
    }

    $script:GitVersion = [System.Version]$Matches['ver']

    return $GitVersion -ge $requiredVersion
}

if (!(Test-GitVersion)) {
    Write-Warning "posh-git requires Git $requiredVersion or better. You have $GitVersion."
}
