pushd $PSScriptRoot

$nuspec = [xml](Get-Content poshgit.nuspec)
$version = $nuspec.package.metadata.version

$ErrorActionPreference = 'Stop'
git rev-parse "v$version" 2>$null

choco pack poshgit.nuspec
choco install -f -y poshgit -pre --version=$version -s .

popd
