param([switch]$WhatIf = $false)

if(!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning 'Could not find git command. Please create a git alias or add %ProgramFiles%\Git\cmd to PATH.'
}

if(!(Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile...`n$PROFILE"
    New-Item $PROFILE -Force -Type File -ErrorAction Stop -WhatIf:$WhatIf > $null
}

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$profileLine = ". $installDir\profile.example.ps1"
if(!(Select-String -Path $PROFILE -Pattern $profileLine -Quiet -SimpleMatch)) {
    Write-Host "Adding posh-git to profile..."
    "`n`n# Load posh-git example profile`n$profileLine`n" | Out-File $PROFILE -Append -WhatIf:$WhatIf
}

Write-Host 'posh-git sucessfully installed!'
Write-Host 'Please reload your profile for the changes to take effect:'
Write-Host '    . $PROFILE'
