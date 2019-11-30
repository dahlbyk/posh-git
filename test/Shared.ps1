$modulePath = Convert-Path $PSScriptRoot\..\src
$moduleManifestPath = "$modulePath\posh-git.psd1"

$csi = [char]0x1b + "["

if (!(Get-Variable -Name gitbin -Scope global -ErrorAction SilentlyContinue)) {
    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        # On Windows, we can access the git binary via git.exe
        $global:gitbin = Get-Command -Name git -CommandType Application -TotalCount 1
    }
    else {
        # On Linux/macOS, we can access the git binary via its path /usr/bin/git
        $global:gitbin = (Get-Command -Name git -CommandType Application -TotalCount 1).Path
    }
}

# We need this or the Git mocks don't work
# This must global in order to be accessible in posh-git module scope
function global:git {
    $OFS = ' '
    $cmdline = "$args"
    # Write-Warning "in global git func with: $cmdline"
    switch ($cmdline) {
        '--version' { 'git version 2.16.2.windows.1' }
        'help'      { Get-Content $PSScriptRoot\git-help.txt  }
        default     {
            $res = Invoke-Expression "&$gitbin $cmdline"
            $res
        }
    }
}

# This must global in order to be accessible in posh-git module scope
function global:Convert-NativeLineEnding([string]$content, [switch]$SplitLines) {
    $tmp = $content -split "`n" | ForEach-Object { $_.TrimEnd("`r")}
    if ($SplitLines) {
        $tmp
    }
    else {
        $content = $tmp -join [System.Environment]::NewLine
        $content
    }
}

function GetHomePath() {
    $Home
}

function GetHomeRelPath([string]$Path) {
    if (!$Path.StartsWith($Home)) {
        # Path not under $Home
        return $Path
    }

    if ($GitPromptSettings.DefaultPromptAbbreviateHomeDirectory) {
        "~$($Path.Substring($Home.Length))"
    }
    else {
        $Path
    }
}

function MakeNativePath([string]$Path) {
    $Path -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
}

function MakeGitPath([string]$Path) {
    $Path -replace '\\', '/'
}

function NewGitTempRepo([switch]$MakeInitialCommit) {
    Push-Location
    $temp = [System.IO.Path]::GetTempPath()
    $repoPath = Join-Path $temp ([IO.Path]::GetRandomFileName())
    &$gitbin init $repoPath *>$null
    Set-Location $repoPath

    if ($MakeInitialCommit) {
        &$gitbin config user.email "spaceman.spiff@appveyor.com"
        &$gitbin config user.name "Spaceman Spiff"
        'readme' | Out-File ./README.md -Encoding ascii
        &$gitbin add ./README.md *>$null
        &$gitbin commit -m "initial commit." *>$null
    }

    $repoPath
}

function RemoveGitTempRepo($RepoPath) {
    Pop-Location
    if ($repoPath -and (Test-Path $repoPath)) {
        Remove-Item $repoPath -Recurse -Force
    }
}

function ResetGitTempRepoWorkingDir($RepoPath, $Branch = 'master') {
    Set-Location $repoPath
    &$gitbin checkout -fq $Branch *>$null
    &$gitbin clean -xdfq *>$null
}

Remove-Item Function:\prompt
Remove-Module posh-git -Force *>$null

# Force the posh-git prompt to be installed. Could be runnng on dev system where
# user has customized the prompt.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
$module = Import-Module $moduleManifestPath -ArgumentList $true,$true -Force -PassThru
