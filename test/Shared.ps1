Import-Module $PSScriptRoot\..\posh-git.psd1

function MakeNativePath([string]$Path) {
    $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}
