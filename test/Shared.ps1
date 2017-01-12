$module = Import-Module $PSScriptRoot\..\posh-git.psd1 -PassThru

function MakeNativePath([string]$Path) {
    $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}
