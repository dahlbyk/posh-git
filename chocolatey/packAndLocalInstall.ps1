param ($Remote = 'origin', [switch]$Force)
pushd $PSScriptRoot

$nuspec = [xml](Get-Content poshgit.nuspec)
$version = $nuspec.package.metadata.version


if ($Force) {
    git push -f $Remote "HEAD:refs/tags/v$version"
}
elseif (!$(git ls-remote $Remote "v$version")) {
    Write-Warning "'$Remote/v$version' not found! Use -Force to create tag at HEAD."
    return
}

choco pack poshgit.nuspec
choco install -f -y poshgit -pre --version=$version -s .

popd
