pushd $PSScriptRoot
choco pack poshgit.nuspec
choco install -f -y poshgit -pre -s .
popd
