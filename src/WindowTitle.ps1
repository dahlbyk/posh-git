$HostSupportsSettingWindowTitle = $null

function Test-WindowTitleIsWriteable {
    # Probe $Host.UI.RawUI.WindowTitle to see if it can be set without errors
    $script:HostSupportsSettingWindowTitle = $false
    try {
        $global:PoshGitOrigWindowTitle = $Host.UI.RawUI.WindowTitle
        $newTitle = "${global:PoshGitOrigWindowTitle} "
        $Host.UI.RawUI.WindowTitle = $newTitle
        $script:HostSupportsSettingWindowTitle = ($Host.UI.RawUI.WindowTitle -eq $newTitle)
        $Host.UI.RawUI.WindowTitle = $global:PoshGitOrigWindowTitle
    }
    catch {
        $global:PoshGitOrigWindowTitle = $null
        Write-Debug "Probing for HostSupportsSettingWindowTitle errored: $_"
    }
}

function Reset-WindowTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()

    # Revert original WindowTitle but only if posh-git is currently configured to set it
    if ($HostSupportsSettingWindowTitle -and $global:GitPromptSettings.WindowTitle -and $global:PoshGitOrigWindowTitle) {
        $Host.UI.RawUI.WindowTitle = $global:PoshGitOrigWindowTitle
    }
}

function Set-WindowTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param($GitStatus, $IsAdmin)
    $settings = $global:GitPromptSettings

    # Update the host's WindowTitle if host supports it and user has not disabled $GitPromptSettings.WindowTitle
    if ($HostSupportsSettingWindowTitle -and $settings.WindowTitle) {
        try {
            if ($settings.WindowTitle -is [scriptblock]) {
                $windowTitleText = & $settings.WindowTitle $GitStatus $IsAdmin
            }
            else {
                $windowTitleText = $ExecutionContext.SessionState.InvokeCommand.ExpandString("$($settings.WindowTitle)")
            }

            # Put $windowTitleText in a string to ensure results returned by scriptblock are flattened into a string
            $Host.UI.RawUI.WindowTitle = "$windowTitleText"
        }
        catch {
            Write-Debug "Error occurred during evaluation of `$GitPromptSettings.WindowTitle: $_"
        }
    }
}
