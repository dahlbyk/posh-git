param([switch]$NoVersionWarn)

if (Get-Module posh-git) { return }

$psv = $PSVersionTable.PSVersion

if ($psv.Major -lt 3 -and !$NoVersionWarn) {
    Write-Warning ("posh-git support for PowerShell 2.0 is deprecated; you have version $($psv).`n" +
    "To download version 5.0, please visit https://www.microsoft.com/en-us/download/details.aspx?id=50395`n" +
    "For more information and to discuss this, please visit https://github.com/dahlbyk/posh-git/issues/163`n" +
    "To suppress this warning, change your profile to include 'Import-Module posh-git -Args `$true'.")
}

& $PSScriptRoot\CheckVersion.ps1 > $null

. $PSScriptRoot\Utils.ps1
. $PSScriptRoot\GitUtils.ps1
. $PSScriptRoot\GitPrompt.ps1
. $PSScriptRoot\GitTabExpansion.ps1
. $PSScriptRoot\TortoiseGit.ps1

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

Get-TempEnv 'SSH_AGENT_PID'
Get-TempEnv 'SSH_AUTH_SOCK'

# Get the default prompt definition.
if ($psv.Major -eq 2) {
    $defaultPromptDef = "`$(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + `$(Get-Location) + `$(if (`$nestedpromptlevel -ge 1) { '>>' }) + '> '"
}
else {
    $defaultPromptDef = [Runspace]::DefaultRunspace.InitialSessionState.Commands['prompt'].Definition
}

# If there is no prompt function or the prompt function is the default, export the posh-git prompt function.
$promptReplaced = $false
$currentPromptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }
if (!$currentPromptDef -or ($currentPromptDef -eq $defaultPromptDef)) {
    Set-Item Function:\prompt -Value {
        $origLastExitCode = $LASTEXITCODE

        # A UNC path has no drive so it's better to use the ProviderPath e.g. "\\server\share".
        # However for any path with a drive defined, it's better to use the Path property.
        # In this case, ProviderPath is "\LocalMachine\My"" whereas Path is "Cert:\LocalMachine\My".
        # The latter is more desirable.
        $pathInfo = $ExecutionContext.SessionState.Path.CurrentLocation
        $curPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }
        if ($curPath -and $curPath.ToLower().StartsWith($Home.ToLower()))
        {
            $curPath = "~" + $curPath.SubString($Home.Length)
        }

        # Write the current path.
        Write-Host $curPath -NoNewline

        # Write the Git status summary information.
        Write-VcsStatus

        # When in debug mode, let user know
        if ((Test-Path Variable:\PSDebugContext) -or [runspace]::DefaultRunspace.Debugger.InBreakpoint) {
            $promptSuffix = "`n[DBG]: PS>> "
        }
        else {
            $promptSuffix = "`nPS> "
        }

        $global:LASTEXITCODE = $origLastExitCode
        $promptSuffix
    }

    $promptReplaced = $true
}

# Install handler for removal/unload of the module
$ExecutionContext.SessionState.Module.OnRemove = {
    $Global:VcsPromptStatuses = $Global:VcsPromptStatuses | Where-Object { $_ -ne $PoshGitVcsPrompt }

    if ($promptReplaced) {
        Set-Item Function:\prompt -Value ([scriptblock]::Create($defaultPromptDef))
    }
}

$exportModuleMemberParams = @{
    Alias = @('??') # TODO: Remove in 1.0.0
    Function = @(
        'Invoke-NullCoalescing',
        'Write-GitStatus',
        'Write-Prompt',
        'Write-VcsStatus',
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
        'tgit'
    )
}

Export-ModuleMember @exportModuleMemberParams
