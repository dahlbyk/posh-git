# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = [pscustomobject]@{
    DefaultForegroundColor                      = $null

    BeforeText                                  = ' ['
    BeforeForegroundColor                       = [ConsoleColor]::Yellow
    BeforeBackgroundColor                       = $null

    DelimText                                   = ' |'
    DelimForegroundColor                        = [ConsoleColor]::Yellow
    DelimBackgroundColor                        = $null

    AfterText                                   = ']'
    AfterForegroundColor                        = [ConsoleColor]::Yellow
    AfterBackgroundColor                        = $null

    FileAddedText                               = '+'
    FileModifiedText                            = '~'
    FileRemovedText                             = '-'
    FileConflictedText                          = '!'

    LocalDefaultStatusSymbol                    = $null
    LocalDefaultStatusForegroundColor           = [ConsoleColor]::DarkGreen
    LocalDefaultStatusForegroundBrightColor     = [ConsoleColor]::Green
    LocalDefaultStatusBackgroundColor           = $null

    LocalWorkingStatusSymbol                    = '!'
    LocalWorkingStatusForegroundColor           = [ConsoleColor]::DarkRed
    LocalWorkingStatusForegroundBrightColor     = [ConsoleColor]::Red
    LocalWorkingStatusBackgroundColor           = $null

    LocalStagedStatusSymbol                     = '~'
    LocalStagedStatusForegroundColor            = [ConsoleColor]::Cyan
    LocalStagedStatusBackgroundColor            = $null

    BranchUntrackedSymbol                       = $null
    BranchForegroundColor                       = [ConsoleColor]::Cyan
    BranchBackgroundColor                       = $null

    BranchGoneStatusSymbol                      = [char]0x00D7 # × Multiplication sign
    BranchGoneStatusForegroundColor             = [ConsoleColor]::DarkCyan
    BranchGoneStatusBackgroundColor             = $null

    BranchIdenticalStatusToSymbol               = [char]0x2261 # ≡ Three horizontal lines
    BranchIdenticalStatusToForegroundColor      = [ConsoleColor]::Cyan
    BranchIdenticalStatusToBackgroundColor      = $null

    BranchAheadStatusSymbol                     = [char]0x2191 # ↑ Up arrow
    BranchAheadStatusForegroundColor            = [ConsoleColor]::Green
    BranchAheadStatusBackgroundColor            = $null

    BranchBehindStatusSymbol                    = [char]0x2193 # ↓ Down arrow
    BranchBehindStatusForegroundColor           = [ConsoleColor]::Red
    BranchBehindStatusBackgroundColor           = $null

    BranchBehindAndAheadStatusSymbol            = [char]0x2195 # ↕ Up & Down arrow
    BranchBehindAndAheadStatusForegroundColor   = [ConsoleColor]::Yellow
    BranchBehindAndAheadStatusBackgroundColor   = $null

    BeforeIndexText                             = ""
    BeforeIndexForegroundColor                  = [ConsoleColor]::DarkGreen
    BeforeIndexForegroundBrightColor            = [ConsoleColor]::Green
    BeforeIndexBackgroundColor                  = $null

    IndexForegroundColor                        = [ConsoleColor]::DarkGreen
    IndexForegroundBrightColor                  = [ConsoleColor]::Green
    IndexBackgroundColor                        = $null

    WorkingForegroundColor                      = [ConsoleColor]::DarkRed
    WorkingForegroundBrightColor                = [ConsoleColor]::Red
    WorkingBackgroundColor                      = $null

    EnableStashStatus                           = $false
    BeforeStashText                             = ' ('
    BeforeStashBackgroundColor                  = $null
    BeforeStashForegroundColor                  = [ConsoleColor]::Red
    AfterStashText                              = ')'
    AfterStashBackgroundColor                   = $null
    AfterStashForegroundColor                   = [ConsoleColor]::Red
    StashBackgroundColor                        = $null
    StashForegroundColor                        = [ConsoleColor]::Red

    ErrorForegroundColor                        = [ConsoleColor]::Red
    ErrorBackgroundColor                        = $null

    ShowStatusWhenZero                          = $true

    # Valid values are "all", "no", and "normal"
    UntrackedFilesMode                          = $null

    AutoRefreshIndex                            = $true

    # Valid values are "Full", "Compact", and "Minimal"
    BranchBehindAndAheadDisplay                 = "Full"

    EnablePromptStatus                          = !$Global:GitMissing
    EnableFileStatus                            = $true
    EnableFileStatusFromCache                   = $null
    RepositoriesInWhichToDisableFileStatus      = @( ) # Array of repository paths
    DescribeStyle                               = ''

    EnableWindowTitle                           = 'posh~git ~ '
    AdminTitlePrefixText                        = 'Administrator: '

    DefaultPromptPrefix                         = ''
    DefaultPromptSuffix                         = '$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptDebugSuffix                    = ' [DBG]$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptEnableTiming                   = $false

    DefaultPromptPath                           = '$(Get-PromptPath)'
    DefaultPromptAbbreviateHomeDirectory        = $false

    Debug                                       = $false

    BranchNameLimit                             = 0
    TruncatedBranchSuffix                       = '...'
}

$isAdminProcess = Test-Administrator

$WindowTitleSupported = $true
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt($Object, $ForegroundColor = $null, $BackgroundColor = $null) {
    $s = $global:GitPromptSettings
    if ($s -and ($null -eq $ForegroundColor)) {
        $ForegroundColor = $s.DefaultForegroundColor
    }

    if ($BackgroundColor -is [string]) {
        $BackgroundColor = [ConsoleColor]$BackgroundColor
    }
    if ($ForegroundColor -is [string]) {
        $ForegroundColor = [ConsoleColor]$ForegroundColor
    }

    $writeHostParams = @{
        Object = $Object;
        NoNewLine = $true;
    }
    if (($BackgroundColor -ge 0) -and ($BackgroundColor -le 15)) {
        $writeHostParams.BackgroundColor = $BackgroundColor
    }
    if (($ForegroundColor -ge 0) -and ($ForegroundColor -le 15)) {
        $writeHostParams.ForegroundColor = $ForegroundColor
    }
    Write-Host @writeHostParams
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
    if ($status -and $s) {
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor

        $branchStatusText            = $null
        $branchStatusBackgroundColor = $s.BranchBackgroundColor
        $branchStatusForegroundColor = $s.BranchForegroundColor

        if (!$status.Upstream) {
            $branchStatusText            = $s.BranchUntrackedSymbol
        } elseif ($status.UpstreamGone -eq $true) {
            # Upstream branch is gone
            $branchStatusText            = $s.BranchGoneStatusSymbol
            $branchStatusBackgroundColor = $s.BranchGoneStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchGoneStatusForegroundColor
        } elseif ($status.BehindBy -eq 0 -and $status.AheadBy -eq 0) {
            # We are aligned with remote
            $branchStatusText            = $s.BranchIdenticalStatusToSymbol
            $branchStatusBackgroundColor = $s.BranchIdenticalStatusToBackgroundColor
            $branchStatusForegroundColor = $s.BranchIdenticalStatusToForegroundColor
        } elseif ($status.BehindBy -ge 1 -and $status.AheadBy -ge 1) {
            # We are both behind and ahead of remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full") {
                $branchStatusText        = ("{0}{1} {2}{3}" -f $s.BranchBehindStatusSymbol, $status.BehindBy, $s.BranchAheadStatusSymbol, $status.AheadBy)
            } elseif ($s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusText        = ("{0}{1}{2}" -f $status.BehindBy, $s.BranchBehindAndAheadStatusSymbol, $status.AheadBy)
            } else {
                $branchStatusText        = $s.BranchBehindAndAheadStatusSymbol
            }
            $branchStatusBackgroundColor = $s.BranchBehindAndAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindAndAheadStatusForegroundColor
        } elseif ($status.BehindBy -ge 1) {
            # We are behind remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full" -Or $s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusText        = ("{0}{1}" -f $s.BranchBehindStatusSymbol, $status.BehindBy)
            } else {
                $branchStatusText        = $s.BranchBehindStatusSymbol
            }
            $branchStatusBackgroundColor = $s.BranchBehindStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchBehindStatusForegroundColor
        } elseif ($status.AheadBy -ge 1) {
            # We are ahead of remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full" -Or $s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusText        = ("{0}{1}" -f $s.BranchAheadStatusSymbol, $status.AheadBy)
            } else {
                $branchStatusText        = $s.BranchAheadStatusSymbol
            }
            $branchStatusBackgroundColor = $s.BranchAheadStatusBackgroundColor
            $branchStatusForegroundColor = $s.BranchAheadStatusForegroundColor
        } else {
            # This condition should not be possible but defaulting the variables to be safe
            $branchStatusText            = "?"
        }

        Write-Prompt (Format-BranchName($status.Branch)) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor

        if ($branchStatusText) {
            Write-Prompt  (" {0}" -f $branchStatusText) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor
        }

        if($s.EnableFileStatus -and $status.HasIndex) {
            Write-Prompt $s.BeforeIndexText -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor

            if($s.ShowStatusWhenZero -or $status.Index.Added) {
                Write-Prompt (" $($s.FileAddedText)$($status.Index.Added.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
                Write-Prompt (" $($s.FileModifiedText)$($status.Index.Modified.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
                Write-Prompt (" $($s.FileRemovedText)$($status.Index.Deleted.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                Write-Prompt (" $($s.FileConflictedText)$($status.Index.Unmerged.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
                Write-Prompt (" $($s.FileAddedText)$($status.Working.Added.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
                Write-Prompt (" $($s.FileModifiedText)$($status.Working.Modified.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
                Write-Prompt (" $($s.FileRemovedText)$($status.Working.Deleted.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Working.Unmerged) {
                Write-Prompt (" $($s.FileConflictedText)$($status.Working.Unmerged.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
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
            Write-Prompt (" {0}" -f $localStatusSymbol) -BackgroundColor $localStatusBackgroundColor -ForegroundColor $localStatusForegroundColor
        }

        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
             Write-Prompt $s.BeforeStashText -BackgroundColor $s.BeforeStashBackgroundColor -ForegroundColor $s.BeforeStashForegroundColor
             Write-Prompt $status.StashCount -BackgroundColor $s.StashBackgroundColor -ForegroundColor $s.StashForegroundColor
             Write-Prompt $s.AfterStashText -BackgroundColor $s.AfterStashBackgroundColor -ForegroundColor $s.AfterStashForegroundColor
        }

        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $adminHeader = if ($script:isAdminProcess) { $s.AdminTitlePrefixText } else { '' }
            $Host.UI.RawUI.WindowTitle = "$adminHeader$prefix$repoName [$($status.Branch)]"
        }
    } elseif ( $Global:PreviousWindowTitle ) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
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
    $Global:VcsPromptStatuses | ForEach-Object { & $_ }
}

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    try {
        $Global:GitStatus = Get-GitStatus
        Write-GitStatus $GitStatus
    }
    catch {
        $s = $Global:GitPromptSettings
        if ($s) {
            Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
            Write-Prompt "Error: $_" -BackgroundColor $s.ErrorBackgroundColor -ForegroundColor $s.ErrorForegroundColor
            if ($s.Debug) {
                Write-Host
                Write-Verbose "PoshGitVcsPrompt error details: $($_ | Format-List * -Force | Out-String)" -Verbose
            }
            Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
        }
    }
}

$Global:VcsPromptStatuses += $PoshGitVcsPrompt
