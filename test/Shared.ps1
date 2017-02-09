$modulePath = Convert-Path $PSScriptRoot\..\src
$moduleManifestPath = "$modulePath\posh-git.psd1"

# We need this or the Git mocks don't work
function global:git {
    $OFS = ' '
    $cmdline = "$args"
    switch ($cmdline) {
        '--version' { 'git version 2.11.0.windows.1' }
        'help'      { Get-Content $PSScriptRoot\git-help.txt  }
        default     {
            $res = Invoke-Expression "git.exe $cmdline"
            $res
        }
    }
}

function MakeNativePath([string]$Path) {
    $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}

function MakeGitPath([string]$Path) {
    $Path -replace '\\', '/'
}

# Force the posh-git prompt to be installed. Could be runnng on dev system where
# user has customized the prompt.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
$module = Import-Module $moduleManifestPath -ArgumentList $true,$true -Force -PassThru
