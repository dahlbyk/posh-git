# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = New-Object PSObject -Property @{
    DefaultForegroundColor                      = $Host.UI.RawUI.ForegroundColor

    BeforeText                                  = ' ['
    BeforeForegroundColor                       = [ConsoleColor]::Yellow
    BeforeBackgroundColor                       = $Host.UI.RawUI.BackgroundColor

    DelimText                                   = ' |'
    DelimForegroundColor                        = [ConsoleColor]::Yellow
    DelimBackgroundColor                        = $Host.UI.RawUI.BackgroundColor

    AfterText                                   = ']'
    AfterForegroundColor                        = [ConsoleColor]::Yellow
    AfterBackgroundColor                        = $Host.UI.RawUI.BackgroundColor

    FileAddedText                               = '+'
    FileModifiedText                            = '~'
    FileRemovedText                             = '-'
    FileConflictedText                          = '!'

    LocalDefaultStatusSymbol                    = $null
    LocalDefaultStatusForegroundColor           = [ConsoleColor]::DarkGreen
    LocalDefaultStatusForegroundBrightColor     = [ConsoleColor]::Green
    LocalDefaultStatusBackgroundColor           = $Host.UI.RawUI.BackgroundColor

    LocalWorkingStatusSymbol                    = '!'
    LocalWorkingStatusForegroundColor           = [ConsoleColor]::DarkRed
    LocalWorkingStatusForegroundBrightColor     = [ConsoleColor]::Red
    LocalWorkingStatusBackgroundColor           = $Host.UI.RawUI.BackgroundColor

    LocalStagedStatusSymbol                     = '~'
    LocalStagedStatusForegroundColor            = [ConsoleColor]::Cyan
    LocalStagedStatusBackgroundColor            = $Host.UI.RawUI.BackgroundColor

    BranchUntrackedSymbol                       = $null
    BranchForegroundColor                       = [ConsoleColor]::Cyan
    BranchBackgroundColor                       = $Host.UI.RawUI.BackgroundColor

    BranchIdenticalStatusToSymbol               = [char]0x2261 # Three horizontal lines
    BranchIdenticalStatusToForegroundColor      = [ConsoleColor]::Cyan
    BranchIdenticalStatusToBackgroundColor      = $Host.UI.RawUI.BackgroundColor

    BranchAheadStatusSymbol                     = [char]0x2191 # Up arrow
    BranchAheadStatusForegroundColor            = [ConsoleColor]::Green
    BranchAheadStatusBackgroundColor            = $Host.UI.RawUI.BackgroundColor

    BranchBehindStatusSymbol                    = [char]0x2193 # Down arrow
    BranchBehindStatusForegroundColor           = [ConsoleColor]::Red
    BranchBehindStatusBackgroundColor           = $Host.UI.RawUI.BackgroundColor

    BranchBehindAndAheadStatusSymbol            = [char]0x2195 # Up & Down arrow
    BranchBehindAndAheadStatusForegroundColor   = [ConsoleColor]::Yellow
    BranchBehindAndAheadStatusBackgroundColor   = $Host.UI.RawUI.BackgroundColor

    BeforeIndexText                             = ""
    BeforeIndexForegroundColor                  = [ConsoleColor]::DarkGreen
    BeforeIndexForegroundBrightColor            = [ConsoleColor]::Green
    BeforeIndexBackgroundColor                  = $Host.UI.RawUI.BackgroundColor

    IndexForegroundColor                        = [ConsoleColor]::DarkGreen
    IndexForegroundBrightColor                  = [ConsoleColor]::Green
    IndexBackgroundColor                        = $Host.UI.RawUI.BackgroundColor

    WorkingForegroundColor                      = [ConsoleColor]::DarkRed
    WorkingForegroundBrightColor                = [ConsoleColor]::Red
    WorkingBackgroundColor                      = $Host.UI.RawUI.BackgroundColor

    EnableStashStatus                           = $false
    BeforeStashText                             = ' ('
    BeforeStashBackgroundColor                   = $Host.UI.RawUI.BackgroundColor
    BeforeStashForegroundColor                   = [ConsoleColor]::Red
    AfterStashText                              = ')'
    AfterStashBackgroundColor                   = $Host.UI.RawUI.BackgroundColor
    AfterStashForegroundColor                   = [ConsoleColor]::Red
    StashBackgroundColor                        = $Host.UI.RawUI.BackgroundColor
    StashForegroundColor                        = [ConsoleColor]::Red

    ShowStatusWhenZero                          = $true

    AutoRefreshIndex                            = $true

    EnablePromptStatus                          = !$Global:GitMissing
    EnableFileStatus                            = $true
    RepositoriesInWhichToDisableFileStatus      = @( ) # Array of repository paths
    DescribeStyle                               = ''

    EnableWindowTitle                           = 'posh~git ~ '

    AnsiConsole                                 = $Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")

    Debug                                       = $false

    BranchNameLimit                             = 0
    TruncatedBranchSuffix                       = '...'
}

# PowerShell 5.x only runs on Windows so use .NET types to determine isAdminProcess
# Or if we are on v6 or higher, check the $IsWindows pre-defined variable.
if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
    $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdminProcess = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
else {
    # Must be Linux or OSX, so use the id util. Root has userid of 0.
    $isAdminProcess = 0 -eq (id -u)
}

$adminHeader = if ($isAdminProcess) { 'Administrator: ' } else { '' }

$WindowTitleSupported = $true
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($GitPromptSettings.AnsiConsole) {
      $e = [char]27 + "["
      $f = Get-ForegroundVirtualTerminalSequence $ForegroundColor
      $b = Get-BackgroundVirtualTerminalSequence $BackgroundColor
      return "${f}${b}${Object}${e}0m"
    }
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
    return ""
}

function Format-BranchName($branchName){
    $s = $global:GitPromptSettings

    if($s.BranchNameLimit -gt 0 -and $branchName.Length -gt $s.BranchNameLimit)
    {
        $branchName = "{0}{1}" -f $branchName.Substring(0,$s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    return $branchName
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    $p = ''
    if ($status -and $s) {
        $p += Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor

        $branchStatusSymbol          = $null
        $branchStatusBackgroundColor = $s.BranchBackgroundColor
        $branchStatusForegroundColor = $s.BranchForegroundColor

        if (!$status.Upstream) {
            $branchStatusSymbol          = $s.BranchUntrackedSymbol
        } elseif ($status.BehindBy -eq 0 -and $status.AheadBy -eq 0) {
            # We are aligned with remote
            $branchStatusSymbol          = $s.BranchIdenticalStatusToSymbol
            $branchStatusBackgroundColor = $s.BranchIdenticalStatusToBackgroundColor
            $branchStatusForegroundColor = $s.BranchIdenticalStatusToForegroundColor
        } elseif ($status.BehindBy -ge 1 -and $status.AheadBy -ge 1) {
            # We are both behind and ahead of remote
            $branchStatusSymbol          = $s.BranchBehindAndAheadStatusSymbol
            $branchStatusBackgroundColor = $s.BranchBehindAndAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindAndAheadStatusForegroundColor
        } elseif ($status.BehindBy -ge 1) {
            # We are behind remote
            $branchStatusSymbol          = $s.BranchBehindStatusSymbol
            $branchStatusBackgroundColor = $s.BranchBehindStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindStatusForegroundColor
        } elseif ($status.AheadBy -ge 1) {
            # We are ahead of remote
            $branchStatusSymbol          = $s.BranchAheadStatusSymbol
            $branchStatusBackgroundColor = $s.BranchAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchAheadStatusForegroundColor
        } else {
            # This condition should not be possible but defaulting the variables to be safe
            $branchStatusSymbol          = "?"
        }

        $p += Write-Prompt (Format-BranchName($status.Branch)) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor

        if ($branchStatusSymbol) {
            $p += Write-Prompt  (" {0}" -f $branchStatusSymbol) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor
        }

        if($s.EnableFileStatus -and $status.HasIndex) {
            $p += Write-Prompt $s.BeforeIndexText -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor

            if($s.ShowStatusWhenZero -or $status.Index.Added) {
                $p += Write-Prompt (" $($s.FileAddedText)$($status.Index.Added.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
                $p += Write-Prompt (" $($s.FileModifiedText)$($status.Index.Modified.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
                $p += Write-Prompt (" $($s.FileRemovedText)$($status.Index.Deleted.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                $p += Write-Prompt (" $($s.FileConflictedText)$($status.Index.Unmerged.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                $p += Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
                $p += Write-Prompt (" $($s.FileAddedText)$($status.Working.Added.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
                $p += Write-Prompt (" $($s.FileModifiedText)$($status.Working.Modified.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
                $p += Write-Prompt (" $($s.FileRemovedText)$($status.Working.Deleted.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Working.Unmerged) {
                $p += Write-Prompt (" $($s.FileConflictedText)$($status.Working.Unmerged.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
        }

        if ($status.HasWorking) {
            # We have un-staged files in the working tree
            $localStatusSymbol          = $s.LocalWorkingStatusSymbol
            $localStatusBackgroundColor = $s.LocalWorkingStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalWorkingStatusForegroundColor
        } elseif ($status.HasIndex) {
            # We have staged but uncommited files
            $localStatusSymbol          = $s.LocalStagedStatusSymbol
            $localStatusBackgroundColor = $s.LocalStagedStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalStagedStatusForegroundColor
        } else {
            # No uncommited changes
            $localStatusSymbol          = $s.LocalDefaultStatusSymbol
            $localStatusBackgroundColor = $s.LocalDefaultStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalDefaultStatusForegroundColor
        }

        if ($localStatusSymbol) {
            $p += Write-Prompt (" {0}" -f $localStatusSymbol) -BackgroundColor $localStatusBackgroundColor -ForegroundColor $localStatusForegroundColor
        }

        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
             $p += Write-Prompt $s.BeforeStashText -BackgroundColor $s.BeforeStashBackgroundColor -ForegroundColor $s.BeforeStashForegroundColor
             $p += Write-Prompt $status.StashCount -BackgroundColor $s.StashBackgroundColor -ForegroundColor $s.StashForegroundColor
             $p += Write-Prompt $s.AfterStashText -BackgroundColor $s.AfterStashBackgroundColor -ForegroundColor $s.AfterStashForegroundColor
        }

        $p += Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$script:adminHeader$prefix$repoName [$($status.Branch)]"
        }

	return $p
    } elseif ( $Global:PreviousWindowTitle ) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
	return ""
    }
}

if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}
$s = $global:GitPromptSettings

# Override some of the normal colors if the background color is set to the default DarkMagenta.
if ($Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) {
    $s.LocalDefaultStatusForegroundColor    = $s.LocalDefaultStatusForegroundBrightColor
    $s.LocalWorkingStatusForegroundColor    = $s.LocalWorkingStatusForegroundBrightColor

    $s.BeforeIndexForegroundColor           = $s.BeforeIndexForegroundBrightColor
    $s.IndexForegroundColor                 = $s.IndexForegroundBrightColor

    $s.WorkingForegroundColor               = $s.WorkingForegroundBrightColor
}

function Global:Write-VcsStatus {
  Set-ConsoleMode -ANSI
  $Global:VcsPromptStatuses | foreach { & $_ }
}

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}
$Global:VcsPromptStatuses += $PoshGitVcsPrompt
$ExecutionContext.SessionState.Module.OnRemove = { $Global:VcsPromptStatuses = $Global:VcsPromptStatuses | ? { $_ -ne $PoshGitVcsPrompt} }
