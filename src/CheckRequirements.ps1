$global:GitMissing = $false

$requiredVersion = [Version]'1.7.2'
$script:GitVersion = $requiredVersion

if (!(Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Warning "git command could not be found. Please create an alias or add it to your PATH."
    $Global:GitMissing = $true
    return
}

if ([string](git --version 2> $null) -match '(?<ver>\d+(?:\.\d+)+)') {
    $script:GitVersion = [System.Version]$Matches['ver']
}

if ($GitVersion -lt $requiredVersion) {
    Write-Warning "posh-git requires Git $requiredVersion or better. You have $GitVersion."
    $false
}
else {
    $true
}
