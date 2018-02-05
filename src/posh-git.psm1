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

    # Construct/write the prompt text
    $prompt = ''

    # Display default prompt prefix if not empty.
    $defaultPromptPrefix = $settings.DefaultPromptPrefix
    if ($defaultPromptPrefix.Text) {
        $promptPrefix = [PoshGitTextSpan]::new($settings.DefaultPromptPrefix)
        $promptPrefix.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($defaultPromptPrefix.Text)
        $prompt += Write-Prompt $promptPrefix
    }

    # Get the current path - formatted correctly
    $promptPath = [PoshGitTextSpan]::new($settings.DefaultPromptPath)
    $promptPath.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($promptPath.Text)

    # Write the path and Git status summary information
    if ($settings.DefaultPromptWriteStatusFirst) {
        $prompt += Write-VcsStatus
        $prompt += Write-Prompt $settings.DefaultPromptBetween
        $prompt += Write-Prompt $promptPath
    }
    else {
        $prompt += Write-Prompt $promptPath
        $prompt += Write-Prompt $settings.DefaultPromptBetween
        $prompt += Write-VcsStatus
    }

    # If stopped in the debugger, the prompt needs to indicate that in some fashion
    $debugMode = (Test-Path Variable:/PSDebugContext) -or [runspace]::DefaultRunspace.Debugger.InBreakpoint
    if ($debugMode) {
        $promptDebug = [PoshGitTextSpan]::new($settings.DefaultPromptDebug)
        $promptDebug.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($promptDebug.Text)
    }

    # Get the prompt suffix text
    $promptSuffix = [PoshGitTextSpan]::new($settings.DefaultPromptSuffix)
    $promptSuffix.Text = $ExecutionContext.SessionState.InvokeCommand.ExpandString($promptSuffix.Text)

    # When using Write-Host, we will append a single space to prevent PowerShell from displaying "PS>"
    # So to avoid two spaces at the end of the suffix, remove one here if it exists
    if (!$settings.AnsiConsole -and $promptSuffix.Text.EndsWith(' ')) {
        $promptSuffix.Text = $promptSuffix.Text.Substring(0, $promptSuffix.Text.Length - 1)
    }

    # Write debug prompt
    if ($debugMode) {
        $prompt += Write-Prompt $promptDebug
    }

    # If prompt timing enabled, write elapsed milliseconds
    if ($settings.DefaultPromptEnableTiming) {
        $sw.Stop()
        $elapsed = $sw.ElapsedMilliseconds
        $timingText = [PoshGitTextSpan]::new(($settings.DefaultPromptTimingFormat.Text -f $elapsed))
        $prompt += Write-Prompt $timingText # " ${elapsed}ms" -Color $settings.DefaultPromptTimingColor
    }

    $prompt += Write-Prompt $promptSuffix

    # When using Write-Host, return at least a space to avoid "PS>" being unexpectedly displayed
    if (!$settings.AnsiConsole) {
        $prompt += " "
    }

    $global:LASTEXITCODE = $origLastExitCode
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
