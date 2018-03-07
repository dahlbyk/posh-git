param([switch]$NoVersionWarn, [switch]$ForcePoshGitPrompt)

& $PSScriptRoot\CheckRequirements.ps1 > $null

. $PSScriptRoot\ConsoleMode.ps1
. $PSScriptRoot\Utils.ps1
. $PSScriptRoot\AnsiUtils.ps1
. $PSScriptRoot\PoshGitTypes.ps1
. $PSScriptRoot\GitUtils.ps1
. $PSScriptRoot\GitPrompt.ps1
. $PSScriptRoot\GitParamTabExpansion.ps1
. $PSScriptRoot\GitTabExpansion.ps1
. $PSScriptRoot\TortoiseGit.ps1
. $PSScriptRoot\SshUtils.ps1

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

$IsAdmin = Test-Administrator

# Probe $Host.UI.RawUI.WindowTitle to see if it can be set without errors
$WindowTitleSupported = $false
try {
    $global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
    $newTitle = "${global:PreviousWindowTitle} "
    $Host.UI.RawUI.WindowTitle = $newTitle
    $WindowTitleSupported = ($Host.UI.RawUI.WindowTitle -eq $newTitle)
    $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
}
catch {
    Write-Debug "Probing for WindowTitleSupported errored: $_"
}

# Get the default prompt definition.
$initialSessionState = [Runspace]::DefaultRunspace.InitialSessionState
if (!$initialSessionState.Commands -or !$initialSessionState.Commands['prompt']) {
    $defaultPromptDef = "`$(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + `$(Get-Location) + `$(if (`$nestedpromptlevel -ge 1) { '>>' }) + '> '"
}
else {
    $defaultPromptDef = $initialSessionState.Commands['prompt'].Definition
}

# The built-in posh-git prompt function in ScriptBlock form.
$GitPromptScriptBlock = {
    $settings = $global:GitPromptSettings
    if (!$settings) {
        if ($WindowTitleSupported -and $global:PreviousWindowTitle) {
            $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
        }

        return "<`$GitPromptSettings not found> "
    }

    if ($settings.DefaultPromptEnableTiming) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
    }

    $origLastExitCode = $global:LASTEXITCODE

    $prompt = ''

    # Display default prompt prefix if not empty.
    $defaultPromptPrefix = $settings.DefaultPromptPrefix
    if ($defaultPromptPrefix.Text) {
        $promptPrefix = [PoshGitTextSpan]::new($settings.DefaultPromptPrefix)
        $promptPrefix.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($defaultPromptPrefix.Text)
        $prompt += Write-Prompt $promptPrefix
    }

    # Write the abbreviated current path
    $promptPath = [PoshGitTextSpan]::new($settings.DefaultPromptPath)
    $promptPath.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($promptPath.Text)
    $prompt += Write-Prompt $promptPath

    # Write the Git status summary information
    $prompt += Write-VcsStatus

    # If stopped in the debugger, the prompt needs to indicate that in some fashion
    $hasInBreakpoint = [runspace]::DefaultRunspace.Debugger | Get-Member -Name InBreakpoint -MemberType property
    $debugMode = (Test-Path Variable:/PSDebugContext) -or ($hasInBreakpoint -and [runspace]::DefaultRunspace.Debugger.InBreakpoint)
    $defaultPromptSuffix = if ($debugMode) { $settings.DefaultPromptDebugSuffix } else { $settings.DefaultPromptSuffix }

    $promptSuffix = [PoshGitTextSpan]::new($defaultPromptSuffix)
    if ($defaultPromptSuffix.Text) {
        $promptSuffix.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($defaultPromptSuffix.Text)
    }
    # If user specifies $null or empty string, set to ' ' to avoid "PS>" unexpectedly being displayed
    else {
        $promptSuffix.Text = ' '
    }

    # Update the host's WindowTitle is host supports it and user has not disabled $GitPromptSettings.WindowTitle
    if ($WindowTitleSupported) {
        $windowTitle = $settings.WindowTitle
        if (!$windowTitle) {
            if ($global:PreviousWindowTitle) {
                $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
            }
        }
        else {
            try {
                if ($windowTitle -is [scriptblock]) {
                    $windowTitleText = & $windowTitle $global:GitStatus $IsAdmin
                }
                else {
                    $windowTitleText = $ExecutionContext.SessionState.InvokeCommand.ExpandString("$windowTitle")
                }

                # Put $windowTitleText in a string to ensure results returned by scriptblock are flattened to a string
                $Host.UI.RawUI.WindowTitle = "$windowTitleText"
            }
            catch {
                if ($global:PreviousWindowTitle) {
                    $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
                }

                Write-Debug "Error occurred during evaluation of `$GitPromptSettings.WindowTitle: $_"
            }
        }
    }

    # If prompt timing enabled, display elapsed milliseconds
    if ($settings.DefaultPromptEnableTiming) {
        $sw.Stop()
        $elapsed = $sw.ElapsedMilliseconds
        $prompt += Write-Prompt " ${elapsed}ms" -Color $settings.DefaultPromptTimingColor
    }

    $global:LASTEXITCODE = $origLastExitCode
    $prompt += Write-Prompt $promptSuffix
    $prompt
}

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

# If there is no prompt function or the prompt function is the default, replace the current prompt function definition
if ($ForcePoshGitPrompt -or !$currentPromptDef -or ($currentPromptDef -eq $defaultPromptDef)) {
    # Set the posh-git prompt as the default prompt
    Set-Item Function:\prompt -Value $GitPromptScriptBlock
}

# Install handler for removal/unload of the module
$ExecutionContext.SessionState.Module.OnRemove = {
    $global:VcsPromptStatuses = $global:VcsPromptStatuses | Where-Object { $_ -ne $PoshGitVcsPrompt }

    # Revert original WindowTitle
    if ($WindowTitleSupported -and $global:PreviousWindowTitle) {
        $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
    }

    # Check if the posh-git prompt function itself has been replaced. If so, do not restore the prompt function
    $promptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }
    if ($promptDef -eq $GitPromptScriptBlock) {
        Set-Item Function:\prompt -Value ([scriptblock]::Create($defaultPromptDef))
        return
    }

    Write-Warning 'If your prompt function uses any posh-git commands, it will cause posh-git to be re-imported every time your prompt function is invoked.'
}

$exportModuleMemberParams = @{
    Function = @(
        'Add-PoshGitToProfile',
        'Format-GitBranchName',
        'Get-GitBranchStatusColor',
        'Get-GitDirectory',
        'Get-GitStatus',
        'Get-PromptPath',
        'Update-AllBranches',
        'Get-GitRemotes',
        'Write-GitStatus',
        'Write-GitBranchName',
        'Write-GitBranchStatus',
        'Write-GitIndexStatus',
        'Write-GitStashCount',
        'Write-GitWorkingDirStatus',
        'Write-GitWorkingDirStatusSummary',
        'Write-Prompt',
        'Write-VcsStatus',
        'Get-SshAgent',
        'Start-SshAgent',
        'Stop-SshAgent',
        'Add-SshKey',
        'Get-SshPath',
        'TabExpansion',
        'tgit'
    )
    Variable = @(
        'GitPromptScriptBlock'
    )
}

Export-ModuleMember @exportModuleMemberParams
