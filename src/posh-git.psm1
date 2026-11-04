param([bool]$ForcePoshGitPrompt, [bool]$UseLegacyTabExpansion, [bool]$EnableProxyFunctionExpansion)

if (Test-Path Env:\POSHGIT_ENABLE_STRICTMODE) {
    # Set strict mode to latest to help catch scripting errors in the module. This is done by the Pester tests.
    Set-StrictMode -Version Latest
}

. $PSScriptRoot\CheckRequirements.ps1 > $null

. $PSScriptRoot\ConsoleMode.ps1
. $PSScriptRoot\Utils.ps1
. $PSScriptRoot\AnsiUtils.ps1
. $PSScriptRoot\WindowTitle.ps1
. $PSScriptRoot\PoshGitTypes.ps1
. $PSScriptRoot\GitUtils.ps1
. $PSScriptRoot\GitPrompt.ps1
. $PSScriptRoot\GitParamTabExpansion.ps1
. $PSScriptRoot\GitTabExpansion.ps1
. $PSScriptRoot\TortoiseGit.ps1

$IsAdmin = Test-Administrator

# Get the default prompt definition.
$initialSessionState = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InitialSessionState
if (!$initialSessionState -or !$initialSessionState.PSObject.Properties.Match('Commands') -or !$initialSessionState.Commands['prompt']) {
    $defaultPromptDef = "`$(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + `$(Get-Location) + `$(if (`$nestedpromptlevel -ge 1) { '>>' }) + '> '"
}
else {
    $defaultPromptDef = $initialSessionState.Commands['prompt'].Definition
}

# The built-in posh-git prompt function in ScriptBlock form.

$GitPromptScriptBlock = {
    $origDollarQuestion = $global:?
    $origLastExitCode = $global:LASTEXITCODE
    $settings = $global:GitPromptSettings

    try {
        if (!$global:GitPromptValues) {
            $global:GitPromptValues = [PoshGitPromptValues]::new()
        }

        $global:GitPromptValues.DollarQuestion = $origDollarQuestion
        $global:GitPromptValues.LastExitCode = $origLastExitCode
        $global:GitPromptValues.IsAdmin = $IsAdmin

        if (!$settings) {
            return "<`$GitPromptSettings not found> "
        }

        if ($settings.DefaultPromptEnableTiming) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
        }

        if ($settings.SetEnvColumns) {
            # Set COLUMNS so git knows how wide the terminal is
            $Env:COLUMNS = $Host.UI.RawUI.WindowSize.Width
        }

        # Construct/write the prompt text
        $prompt = ''

        # Write default prompt prefix
        $prompt += Write-Prompt $settings.DefaultPromptPrefix.Expand()

        # Get the current path - formatted correctly
        $promptPath = $settings.DefaultPromptPath.Expand()

        # Write the delimited path and Git status summary information
        if ($settings.DefaultPromptWriteStatusFirst) {
            $prompt += Write-VcsStatus
            $prompt += Write-Prompt $settings.BeforePath.Expand()
            $prompt += Write-Prompt $promptPath
            $prompt += Write-Prompt $settings.AfterPath.Expand()
        }
        else {
            $prompt += Write-Prompt $settings.BeforePath.Expand()
            $prompt += Write-Prompt $promptPath
            $prompt += Write-Prompt $settings.AfterPath.Expand()
            $prompt += Write-VcsStatus
        }

        # Write default prompt before suffix text
        $prompt += Write-Prompt $settings.DefaultPromptBeforeSuffix.Expand()

        # If stopped in the debugger, indicate that in the prompt
        if ((Test-Path Variable:/PSDebugContext) -or [runspace]::DefaultRunspace.Debugger.InBreakpoint) {
            $prompt += Write-Prompt $settings.DefaultPromptDebug.Expand()
        }

        # Get the prompt suffix text
        $promptSuffix = $settings.DefaultPromptSuffix.Expand()

        # When using Write-Host, return a single space to prevent PowerShell
        # from displaying its default PS> prompt.
        if (!$settings.AnsiConsole -and $promptSuffix.Text.EndsWith(' ')) {
            $promptSuffix.Text = $promptSuffix.Text.Substring(0, $promptSuffix.Text.Length - 1)
        }

        # This has to be after Write-VcsStatus, which populates $global:GitStatus
        Set-WindowTitle $global:GitStatus $IsAdmin

        # If prompt timing is enabled, write elapsed milliseconds
        if ($settings.DefaultPromptEnableTiming) {
            $timingInfo = [PoshGitTextSpan]::new($settings.DefaultPromptTimingFormat)
            $sw.Stop()
            $timingInfo.Text = $timingInfo.Text -f $sw.ElapsedMilliseconds
            $prompt += Write-Prompt $timingInfo
        }

        $prompt += Write-Prompt $promptSuffix

        # When using Write-Host, return at least a space
        if (!$settings.AnsiConsole) {
            $prompt += " "
        }
        else {
            # Save the ANSI prompt for debugging
            $global:GitPromptValues.LastPrompt = EscapeAnsiString $prompt
        }

        $prompt
    }
    catch {
        $promptError = $_
        $errorText = "posh-git prompt error: $promptError"

        # Try to display the error using the configured prompt error color
        try {
            if ($settings) {
                $errorPrompt = Write-Prompt $errorText -Color $settings.ErrorColor

                if ($settings.Debug) {
                    if (!$settings.AnsiConsole) {
                        Write-Host
                    }

                    Write-Verbose "posh-git prompt error details: $($promptError | Format-List * -Force | Out-String)" -Verbose
                }

                if ($settings.AnsiConsole) {
                    return "$errorPrompt "
                }

                return " "
            }
        }
        catch {
            # Fall back to a warning if the error cannot be rendered.
        }

        Write-Warning $errorText
        return " "
    }
    finally {
        # Restore the original exit code even if prompt generation fails
        $global:LASTEXITCODE = $origLastExitCode
    }
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

    Reset-WindowTitle

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
        'Expand-GitCommand',
        'Format-GitBranchName',
        'Get-GitBranchStatusColor',
        'Get-GitDirectory',
        'Get-GitStatus',
        'Get-PromptConnectionInfo',
        'Get-PromptPath',
        'New-GitPromptSettings',
        'Remove-GitBranch',
        'Remove-PoshGitFromProfile',
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
        'TabExpansion',
        'tgit'
    )
    Variable = @(
        'GitPromptScriptBlock'
    )
}

Export-ModuleMember @exportModuleMemberParams
