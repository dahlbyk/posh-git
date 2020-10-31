$global:GitMissing = $false

$requiredVersion = [Version]'1.7.2'
$script:GitVersion = $requiredVersion
$script:GitCygwin = $false

if (!(Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Warning "git command could not be found. Please create an alias or add it to your PATH."
    $Global:GitMissing = $true
    return
}

if ([string](git --version 2> $null) -match '(?<ver>\d+(?:\.\d+)+)(?<g4w>\.windows)?') {
    $script:GitVersion = [System.Version]$Matches['ver']

    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        if (!$Matches['g4w']) {
            $script:GitCygwin = $true

            if (!$Env:POSHGIT_CYGWIN_WARNING) {
                Write-Warning 'You appear to have an unsupported Git distribution; setting $GitPromptSettings.AnsiConsole = $false. posh-git recommends Git for Windows.'
            }
        }
    }
}

if ($GitVersion -lt $requiredVersion) {
    Write-Warning "posh-git requires Git $requiredVersion or better. You have $GitVersion."
    $false
}
else {
    $true
}
