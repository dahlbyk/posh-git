param([switch]$NoVersionWarn,[switch]$ForcePoshGitPrompt)

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
. $PSScriptRoot\GitParamTabExpansion.ps1
. $PSScriptRoot\GitTabExpansion.ps1
. $PSScriptRoot\TortoiseGit.ps1

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

Get-TempEnv 'SSH_AGENT_PID'
Get-TempEnv 'SSH_AUTH_SOCK'

# Get the default prompt definition.
if (($psv.Major -eq 2) -or ![Runspace]::DefaultRunspace.InitialSessionState.Commands) {
    $defaultPromptDef = "`$(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + `$(Get-Location) + `$(if (`$nestedpromptlevel -ge 1) { '>>' }) + '> '"
}
else {
    $defaultPromptDef = [Runspace]::DefaultRunspace.InitialSessionState.Commands['prompt'].Definition
}

# If there is no prompt function or the prompt function is the default, replace the current prompt function definition
$poshGitPromptScriptBlock = $null

$currentPromptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }

# If prompt matches pre-0.7 posh-git prompt, ignore it
$collapsedLegacyPrompt = '$realLASTEXITCODE = $LASTEXITCODE;Write-Host($pwd.ProviderPath) -nonewline;Write-VcsStatus;$global:LASTEXITCODE = $realLASTEXITCODE;return "> "'
if ($currentPromptDef -and (($currentPromptDef.Trim() -replace '[\r\n\t]+\s*',';') -eq $collapsedLegacyPrompt)) {
    Write-Warning 'Replacing old posh-git prompt. Did you copy profile.example.ps1 into $PROFILE?'
    $currentPromptDef = $null
}

if (!$currentPromptDef) {
    # HACK: If prompt is missing, create a global one we can overwrite with Set-Item
    function global:prompt { ' ' }
}

if ($ForcePoshGitPrompt -or !$currentPromptDef -or ($currentPromptDef -eq $defaultPromptDef)) {
    # Have to use [scriptblock]::Create() to get debugger detection to work in PS v2
    $poshGitPromptScriptBlock = [scriptblock]::Create(@'
        if ($GitPromptSettings.DefaultPromptEnableTiming) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
        }
        $origLastExitCode = $global:LASTEXITCODE

        # A UNC path has no drive so it's better to use the ProviderPath e.g. "\\server\share".
        # However for any path with a drive defined, it's better to use the Path property.
        # In this case, ProviderPath is "\LocalMachine\My"" whereas Path is "Cert:\LocalMachine\My".
        # The latter is more desirable.
        $pathInfo = $ExecutionContext.SessionState.Path.CurrentLocation
        $currentPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }

        # File system paths are case-sensitive on Linux and case-insensitive on Windows and macOS
        if (($PSVersionTable.PSVersion.Major -ge 6) -and $IsLinux) {
            $stringComparison = [System.StringComparison]::Ordinal
        }
        else {
            $stringComparison = [System.StringComparison]::OrdinalIgnoreCase
        }

        # Abbreviate path by replacing beginning of path with ~ *iff* the path is in the user's home dir
        $abbrevHomeDir = $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory
        if ($abbrevHomeDir -and $currentPath -and $currentPath.StartsWith($Home, $stringComparison))
        {
            $currentPath = "~" + $currentPath.SubString($Home.Length)
        }

        # Display default prompt prefix if not empty.
        $defaultPromptPrefix = [string]$GitPromptSettings.DefaultPromptPrefix
        if ($defaultPromptPrefix) {
            $expandedDefaultPromptPrefix = $ExecutionContext.SessionState.InvokeCommand.ExpandString($defaultPromptPrefix)
            Write-Prompt $expandedDefaultPromptPrefix
        }

        # Write the abbreviated current path
        Write-Prompt $currentPath

        # Write the Git status summary information
        Write-VcsStatus

        # If stopped in the debugger, the prompt needs to indicate that in some fashion
        $hasInBreakpoint = [runspace]::DefaultRunspace.Debugger | Get-Member -Name InBreakpoint -MemberType property
        $debugMode = (Test-Path Variable:/PSDebugContext) -or ($hasInBreakpoint -and [runspace]::DefaultRunspace.Debugger.InBreakpoint)
        $promptSuffix = if ($debugMode) { $GitPromptSettings.DefaultPromptDebugSuffix } else { $GitPromptSettings.DefaultPromptSuffix }

        # If user specifies $null or empty string, set to ' ' to avoid "PS>" unexpectedly being displayed
        if (!$promptSuffix) {
            $promptSuffix = ' '
        }

        $expandedPromptSuffix = $ExecutionContext.SessionState.InvokeCommand.ExpandString($promptSuffix)

        # If prompt timing enabled, display elapsed milliseconds
        if ($GitPromptSettings.DefaultPromptEnableTiming) {
            $sw.Stop()
            $elapsed = $sw.ElapsedMilliseconds
            Write-Prompt " ${elapsed}ms"
        }

        $global:LASTEXITCODE = $origLastExitCode
        $expandedPromptSuffix
'@)

    # Set the posh-git prompt as the default prompt
    Set-Item Function:\prompt -Value $poshGitPromptScriptBlock
}

# Install handler for removal/unload of the module
$ExecutionContext.SessionState.Module.OnRemove = {
    $global:VcsPromptStatuses = $global:VcsPromptStatuses | Where-Object { $_ -ne $PoshGitVcsPrompt }

    # Check if the posh-git prompt function itself has been replaced. If so, do not restore the prompt function
    $promptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }
    if ($promptDef -eq $poshGitPromptScriptBlock) {
        Set-Item Function:\prompt -Value ([scriptblock]::Create($defaultPromptDef))
        return
    }

    Write-Warning 'If your prompt function uses any posh-git commands, it will cause posh-git to be re-imported every time your prompt function is invoked.'
}

$exportModuleMemberParams = @{
    Alias = @('??') # TODO: Remove in 1.0.0
    Function = @(
        'Invoke-NullCoalescing',
        'Add-PoshGitToProfile',
        'Write-GitStatus',
        'Write-Prompt',
        'Write-VcsStatus',
        'Get-GitBranch',
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
