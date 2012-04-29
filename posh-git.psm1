if (Get-Module posh-git) { return }

Push-Location $psScriptRoot
.\CheckVersion.ps1 > $null

. ./Utils.ps1
. ./GitUtils.ps1
. ./GitPrompt.ps1
. ./GitTabExpansion.ps1
. ./TortoiseGit.ps1
Pop-Location

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

Export-ModuleMember -Function @(
        'Write-GitStatus',
        'Get-GitStatus', 
        'Enable-GitColors', 
        'Get-GitDirectory',
        'TabExpansion',
        'Get-AliasPattern',
        'Start-SshAgent',
        'Stop-SshAgent',
        'Add-SshKey',
        'tgit')

