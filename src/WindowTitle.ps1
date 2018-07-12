$HostSupportsSettingWindowTitle = $null
$OriginalWindowTitle = $null

function Test-WindowTitleIsWriteable {
    if ($null -eq $HostSupportsSettingWindowTitle) {
        # Probe $Host.UI.RawUI.WindowTitle to see if it can be set without errors
        try {
            $script:OriginalWindowTitle = $Host.UI.RawUI.WindowTitle
            $newTitle = "${OriginalWindowTitle} "
            $Host.UI.RawUI.WindowTitle = $newTitle
            $script:HostSupportsSettingWindowTitle = ($Host.UI.RawUI.WindowTitle -eq $newTitle)
            $Host.UI.RawUI.WindowTitle = $OriginalWindowTitle
        }
        catch {
            $script:OriginalWindowTitle = $null
            $script:HostSupportsSettingWindowTitle = $false
            Write-Debug "Probing for HostSupportsSettingWindowTitle errored: $_"
        }
    }
    return $HostSupportsSettingWindowTitle
}

function Reset-WindowTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()
    $settings = $global:GitPromptSettings

    # Revert to original WindowTitle, but only if posh-git is currently configured to set it
    if ($HostSupportsSettingWindowTitle -and $OriginalWindowTitle -and $settings.WindowTitle) {
        $Host.UI.RawUI.WindowTitle = $OriginalWindowTitle
    }
}

function Set-WindowTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param($GitStatus, $IsAdmin)
    $settings = $global:GitPromptSettings

    # Update the host's WindowTitle if host supports it and user has not disabled $GitPromptSettings.WindowTitle
    if ($settings.WindowTitle -and (Test-WindowTitleIsWriteable)) {
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
