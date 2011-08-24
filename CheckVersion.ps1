if (!(Get-Command git -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Warning "git command could not be found. Please create an alias or add it to your PATH."
    $Global:GitMissing = $true
    return
}
$version = git --version 2> $null
if($version -notlike 'git version 1.7.*') {
    Write-Warning "posh-git requires git version 1.7.x You have $version."
    $false
} else {
    $true
}
