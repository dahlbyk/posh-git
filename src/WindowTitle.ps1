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
            Write-Debug "HostSupportsSettingWindowTitle: $HostSupportsSettingWindowTitle"
            Write-Debug "OriginalWindowTitle: $OriginalWindowTitle"
        }
        catch {
            $script:OriginalWindowTitle = $null
            $script:HostSupportsSettingWindowTitle = $false
            Write-Debug "HostSupportsSettingWindowTitle error: $_"
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
        Write-Debug "Resetting WindowTitle: '$OriginalWindowTitle'"
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
                # ensure results returned by scriptblock are flattened into a string
                $windowTitleText = "$(& $settings.WindowTitle $GitStatus $IsAdmin)"
            }
            else {
                $windowTitleText = $ExecutionContext.SessionState.InvokeCommand.ExpandString("$($settings.WindowTitle)")
            }

            Write-Debug "Setting WindowTitle: $windowTitleText"
            $Host.UI.RawUI.WindowTitle = "$windowTitleText"
        }
        catch {
            Write-Debug "Error occurred during evaluation of `$GitPromptSettings.WindowTitle: $_"
        }
    }
}

function Set-TabTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param($GitStatus)
    $settings = $global:GitPromptSettings

    if ($settings.TabTitle == $false) {
        return
    }

    # If the user is running Powershell ISE then name the tab
    if($psISE -and $GitStatus){
        $existingTabNames = $psISE.PowerShellTabs | % {$_.DisplayName}
        $currentTabName = $psise.CurrentPowerShellTab.DisplayName
        $tabName = Get-TabTitle $GitStatus $existingTabNames $currentTabName
        $psise.CurrentPowerShellTab.DisplayName = $tabName
    }
}

function Get-TabTitle {
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param($GitStatus, [string[]]$existingTabNames, [string]$currentTabName)

    $repo = $GitStatus.RepoName
    $branch = $GitStatus.Branch
    $tabName = "$repo [$branch]"
    #you can't have 2 tabs with the same name so shove a number on the end
    $tabCount = 0
    foreach($existingTabName in $existingTabNames){
        if($existingTabName.StartsWith($tabName) -and $existingTabName -ne $currentTabName){
            $tabCount++
            $tabNumber = [int]$existingTabName.Replace($tabName, "").Replace("(", "").Replace(")", "").Trim()
            if($tabCount -lt $tabNumber + 1){
                $tabCount = $tabNumber + 1
            }
        }
    }
    if($tabCount -gt 0){
        $tabName= "$tabName ($tabCount)"
    }
    return $tabName
}