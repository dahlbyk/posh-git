$HostSupportsSettingTabTitle = $null
$OriginalTabTitle = $null
$GetCurrentTab = $null
$SetCurrentTab = $null
$GetExistingTabs = $null

#for support of other MDI IDEs we might add new blocks below.
#note that the MDI IDEs need to maintain a seperate powershell instance in each document interface
#for example powergui has tabs for scripts but not tabs for powershell instances (AFAIK)
$MdiIdeSupportConfig = @(
    #each block should contain a test to ensure it's only run for the appropriate IDE
    [scriptblock] {
        Write-Debug "Testing for PowerShell ISE tab support"
        if ($psISE) {
            Write-Debug "PowerShell ISE environment detected setting delegates"
            $script:GetCurrentTab = [scriptblock]{$psise.CurrentPowerShellTab.DisplayName}
            $script:SetCurrentTab = [scriptblock]{param($tabName)$psise.CurrentPowerShellTab.DisplayName=$tabName}
            $script:GetExistingTabs = [scriptblock]{$psISE.PowerShellTabs | Select-Object -ExpandProperty DisplayName}
            Write-Debug "Setting HostSupportsSettingTabTitle to true"
            $script:HostSupportsSettingTabTitle = $true
        }
    }
)

function Test-TabTitleIsWriteable {
    if ($null -eq $script:HostSupportsSettingTabTitle) {
        # check to see if we're in a tabbed IDE and test to see if we can set tab names
        try {
            #run the config blocks to set up delegate calls to IDE tab naming methods
            foreach ($item in $script:MdiIdeSupportConfig) {
                Invoke-Command $item
            }

            #if HostSupportsSettingTabTitle is still null then we must not be in an MDI IDE
            if ($null -eq $script:HostSupportsSettingTabTitle) {
                $script:HostSupportsSettingTabTitle = $false
            } else {
                Write-Debug "HostSupportsSettingTabTitle: $script:HostSupportsSettingTabTitle"
                Write-Debug "Testing tab renaming actually works"
                #cache the original tab name and test naming works
                $script:OriginalTabTitle = & $script:GetCurrentTab
                $testTitle = [System.Guid]::NewGuid().ToString()
                Write-Debug "Setting tab title from $($script:OriginalTabTitle) to $testTitle"
                & $script:SetCurrentTab $testTitle
                Write-Debug "Setting tab title back to $($script:OriginalTabTitle)"
                & $script:SetCurrentTab $script:OriginalTabTitle
                Write-Debug "It works"
            }
            Write-Debug "HostSupportsSettingTabTitle: $script:HostSupportsSettingTabTitle"
            Write-Debug "OriginalTabTitle: $script:OriginalTabTitle"
        }
        catch {
            $script:OriginalTabTitle = $null
            $script:HostSupportsSettingTabTitle = $false
            Write-Debug "HostSupportsSettingTabTitle error: $_"
        }
    }
    return $script:HostSupportsSettingTabTitle
}

function Reset-TabTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()
    $settings = $global:GitPromptSettings

    # Revert to original TabTitle, but only if posh-git is currently configured to set it
    if ($HostSupportsSettingTabTitle -and $OriginalTabTitle -and $settings.TabTitle) {
        Write-Debug "Resetting TabTitle: '$OriginalTabTitle'"
        & $script:SetCurrentTab $OriginalTabTitle
    }
}

function Set-TabTitle {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param($GitStatus, $IsAdmin)
    $settings = $global:GitPromptSettings

    # Update the host's TabTitle if
    #  host supports it
    #  user has not disabled $GitPromptSettings.TabTitle
    #  we are in a git repo
    if ($settings.TabTitle -and (Test-TabTitleIsWriteable) -and $settings.TabTitle -is [scriptblock]) {
        try {
            if ($GitStatus) {
                # ensure results returned by scriptblock are flattened into a string
                $tabTitleText = "$(& $settings.TabTitle $GitStatus $IsAdmin)"
                Write-Debug "Setting TabTitle: $tabTitleText"
                & $script:SetCurrentTab "$tabTitleText"
            } else {
                Reset-TabTitle
            }
        }
        catch {
            Write-Debug "Error occurred during evaluation of `$GitPromptSettings.TabTitle: $_"
        }
    }
}

function Get-UniqueTabTitle {
    param($tabNameRoot, $Format="{0} {1}")
    $tabNumber = 1
    $existingTabNames = & $script:GetExistingTabs
    $uniqueTabName = $tabNameRoot
    while ($existingTabNames -contains $uniqueTabName) {
      $uniqueTabName = $Format -f $tabNameRoot,$tabNumber++
    }
    return $uniqueTabName
}
