param([switch]$WhatIf = $false)

if($PSVersionTable.PSVersion.Major -lt 2) {
    Write-Warning "posh-git requires PowerShell 2.0 or better; you have version $($Host.Version)."
    return
}

if(!(Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile...`n$PROFILE"
    New-Item $PROFILE -Force -Type File -ErrorAction Stop -WhatIf:$WhatIf > $null
}

if(!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning 'Could not find git command. Please create a git alias or add %ProgramFiles%\Git\cmd to PATH.'
    return
}

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent
if(!(. (Join-Path $installDir "CheckVersion.ps1"))) {
    return
}

$gitpromptfiles = 'GitPromptClient.exe', 'GitPromptCache.exe', 'git2.dll'
taskkill /f /im gitpromptcache.exe >$null 2>$null
$binDir = Join-Path $installDir "bin"
if (!(Test-Path -PathType Container $bindir)) {
    mkdir $binDir >$null
}


foreach ($file in $gitpromptfiles)
{
    $filePath = Join-path $bindir $file
    if (Test-Path $filePath -ErrorAction SilentlyContinue) {
        Remove-Item "$filePath"
    }
    echo "Downloading file: $filePath"
    wget -Uri "https://github.com/fieryorc/gitprompt/releases/download/v0.1-beta.3/$file" -OutFile "$filePath"
}


# Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx
function Get-FileEncoding($Path) {
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if(!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}

$profileLine = ". '$installDir\profile.example.ps1'"
if(Select-String -Path $PROFILE -Pattern $profileLine -Quiet -SimpleMatch) {
    Write-Host "It seems posh-git is already installed..."
    return
}

Write-Host "Adding posh-git to profile..."
@"

# Load posh-git example profile
$profileLine

"@ | Out-File $PROFILE -Append -WhatIf:$WhatIf -Encoding (Get-FileEncoding $PROFILE)

Write-Host 'posh-git sucessfully installed!'
Write-Host 'Please reload your profile for the changes to take effect:'
Write-Host '    . $PROFILE'
