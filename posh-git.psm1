if (Get-Module posh-git) { return }

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if ($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose
    }
}

if ($posh_git_import_debug) {
    $posh_git_import_sw = [Diagnostics.Stopwatch]::StartNew()
} else {
    $posh_git_import_sw = $null
}

dbg 'Loading posh-git...' $posh_git_import_sw

Push-Location $psScriptRoot

dbg 'CheckVersion.ps1 ...' $posh_git_import_sw
.\CheckVersion.ps1 > $null

dbg 'Utils.ps1 ...' $posh_git_import_sw
. .\Utils.ps1

dbg 'GitUtils.ps1 ...' $posh_git_import_sw
. .\GitUtils.ps1

dbg 'GitPrompt.ps1 ...' $posh_git_import_sw
. .\GitPrompt.ps1

dbg 'GitTabExpansion.ps1 ...' $posh_git_import_sw
. .\GitTabExpansion.ps1

dbg 'TortoiseGit.ps1 ...' $posh_git_import_sw
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


dbg 'posh-git Loaded!' $posh_git_import_sw
if ($posh_git_import_sw) { $posh_git_import_sw.Stop() }
