param([switch]$WhatIf = $false)

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent

Import-Module $installDir\posh-git.psd1
Add-PoshGitToProfile -WhatIf:$WhatIf
