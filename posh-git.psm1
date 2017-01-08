param([switch]$NoVersionWarn, [switch]$NoProfileCheck)

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

# If there is no prompt function or the prompt function is the default, replace the current prompt function definition
$poshGitPromptScriptBlock = $null

$currentPromptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }

# HACK: If prompt is missing, create a global one we can overwrite with Set-Item
if (!$currentPromptDef) {
    function global:prompt { ' ' }
}

if (!$currentPromptDef -or ($currentPromptDef -eq $defaultPromptDef)) {
    # Have to use [scriptblock]::Create() to get debugger detection to work in PS v2
    $poshGitPromptScriptBlock = [scriptblock]::Create(@'
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
        if ($currentPath -and $currentPath.StartsWith($Home, $stringComparison))
        {
            $currentPath = "~" + $currentPath.SubString($Home.Length)
        }

        # Write the abbreviated current path
        Write-Host $currentPath -NoNewline

        # Write the Git status summary information
        Write-VcsStatus

        # If stopped in the debugger, the prompt needs to indicate that in some fashion
        $debugMode = (Test-Path Variable:/PSDebugContext) -or [runspace]::DefaultRunspace.Debugger.InBreakpoint
        $promptSuffix = if ($debugMode) { $GitPromptSettings.PromptDebugSuffix } else { $GitPromptSettings.PromptSuffix }

        # If user specifies $null or empty string, set to ' ' to avoid "PS>" unexpectedly being displayed
        if (!$promptSuffix) {
            $promptSuffix = ' '
        }

        $global:LASTEXITCODE = $origLastExitCode
        $promptSuffix
'@)

    # Set the posh-git prompt as the default prompt
    Set-Item Function:\prompt -Value $poshGitPromptScriptBlock
}

# IFF running interactive, check if user wants their profile script to be modified to import the module
if (!$NoProfileCheck -and ($MyInvocation.ScriptName.Length -eq 0)) {
    # Search the user's profiles to see if any are using posh-git already
    $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserCurrentHost
    if (!$importedInProfile) {
        $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserAllHosts
    }
    if (!$importedInProfile) {
        $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersCurrentHost
    }
    if (!$importedInProfile) {
        $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersAllHosts
    }

    # If we haven't detected that a profile script is using posh-git, ask if they want their profile modified to import posh-git
    if (!$importedInProfile) {
        $yesCurrent = New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList @(
            "&Yes, for the current PowerShell host",
            "Modify the profile for $($Host.Name) to automatically import posh-git."
        )

        $yesAll = New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList @(
            "Yes, for &all PowerShell hosts",
            "Modify the profile for all hosts to automatically import posh-git."
        )

        $no = New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList @(
            "&No",
            "Do not modify my profile. To suppress this prompt in the future, execute: Import-Module posh-git -Arg `$false, `$true"
        )

        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yesCurrent, $yesAll, $no)

        $title = "Modify Profile"
        $message = "Do you want posh-git to modify your profile to automatically import this module whenever your start PowerShell?"
        $result = $host.UI.PromptForChoice($title, $message, $options, 0)
        switch ($result) {
            0 { Add-ImportModuleToProfile $PROFILE.CurrentUserCurrentHost $PSScriptRoot }
            1 { Add-ImportModuleToProfile $PROFILE.CurrentUserAllHosts $PSScriptRoot }
            2 { } # Nothing to do if user picks 'No'
            default { throw "Unexpected choice result: $result" }
        }
    }
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
