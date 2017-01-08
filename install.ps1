param([switch]$WhatIf = $false)

# Dot source for Get-FileEncoding
$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent
. $installDir\Utils.ps1

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

if(!(. (Join-Path $installDir "CheckVersion.ps1"))) {
    return
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
