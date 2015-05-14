param([switch]$NoVersionWarn = $false)

if (Get-Module posh-git) { return }

$psv = $PSVersionTable.PSVersion

if ($psv.Major -lt 3 -and !$NoVersionWarn) {
    Write-Warning ("posh-git support for PowerShell 2.0 is deprecated; you have version $($psv).`n" +
    "To download version 3.0, please visit https://www.microsoft.com/en-us/download/details.aspx?id=34595`n" +
    "For more information and to discuss this, please visit https://github.com/dahlbyk/posh-git/issues/163`n" +
    "To suppress this warning, change your profile to include 'Import-Module posh-git -Args `$true'.")
}

Push-Location $psScriptRoot
.\CheckVersion.ps1 > $null

. .\Utils.ps1
. .\GitUtils.ps1
. .\GitPrompt.ps1
. .\GitTabExpansion.ps1
. .\TortoiseGit.ps1
Pop-Location

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

Get-TempEnv 'SSH_AGENT_PID'
Get-TempEnv 'SSH_AUTH_SOCK'

Export-ModuleMember `
    -Alias @(
        '??') `
    -Function @(
        'Invoke-NullCoalescing',
        'Write-GitStatus',
        'Write-Prompt',
        'Get-GitStatus',
        'Enable-GitColors',
        'Get-GitDirectory',
        'TabExpansion',
        'Get-AliasPattern',
        'Get-SshAgent',
        'Start-SshAgent',
        'Stop-SshAgent',
        'Add-SshKey',
        'Get-SshPath',
        'Update-AllBranches',
        'tgit')


