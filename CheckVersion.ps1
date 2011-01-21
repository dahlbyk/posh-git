$version = git --version 2> $null
if($version -notlike 'git version 1.7.*.msysgit.*') {
    Write-Warning "posh-git requires msysgit version 1.7. You have $version."
    $false
} else {
    $true
}