$ErrorActionPreference = 'Stop'

$moduleName = 'posh-git'     # this could be different from package name
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue