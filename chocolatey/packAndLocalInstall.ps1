param ($Remote = 'origin', [switch]$Force)
Push-Location $PSScriptRoot

$nuspec = [xml](Get-Content poshgit.nuspec)
$version = $nuspec.package.metadata.version
$tag = "v$version"

if ($Force) {
    git tag -f $tag
    git push -f $Remote $tag
}
elseif (!$(git ls-remote $Remote $tag)) {
    Write-Warning "'$Remote/$tag' not found! Use -Force to create tag at HEAD."
    return
}

choco pack poshgit.nuspec
choco install -f -y poshgit -pre --version=$version -s .

Pop-Location
