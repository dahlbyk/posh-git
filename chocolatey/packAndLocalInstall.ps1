pushd $PSScriptRoot

$nuspec = [xml](Get-Content poshgit.nuspec)
$version = $nuspec.package.metadata.version

choco pack poshgit.nuspec
choco install -f -y poshgit -pre --version=$version -s .

popd
