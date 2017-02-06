param([switch]$WhatIf = $false, [switch]$Force = $false)

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent

Import-Module $installDir\src\posh-git.psd1
Add-PoshGitToProfile -WhatIf:$WhatIf -Force:$Force
