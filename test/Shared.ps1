$modulePath = Convert-Path $PSScriptRoot\..\src
$moduleManifestPath = "$modulePath\posh-git.psd1"

# Remove any user-customized prompt so the default prompt tests work correctly
if (Test-Path Function:\prompt) {
    Remove-Item Function:\prompt -ErrorAction Stop
}

$module = Import-Module $moduleManifestPath -PassThru

function MakeNativePath([string]$Path) {
    $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}
