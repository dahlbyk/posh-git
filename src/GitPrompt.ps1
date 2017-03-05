# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = [pscustomobject]@{
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

    BranchGoneStatusSymbol                      = [char]0x00D7 # × Multiplication sign
    BranchGoneStatusForegroundColor             = [ConsoleColor]::DarkCyan
    BranchGoneStatusBackgroundColor             = $Host.UI.RawUI.BackgroundColor

    BranchIdenticalStatusToSymbol               = [char]0x2261 # ≡ Three horizontal lines
    BranchIdenticalStatusToForegroundColor      = [ConsoleColor]::Cyan
    BranchIdenticalStatusToBackgroundColor      = $Host.UI.RawUI.BackgroundColor

    BranchAheadStatusSymbol                     = [char]0x2191 # ↑ Up arrow
    BranchAheadStatusForegroundColor            = [ConsoleColor]::Green
    BranchAheadStatusBackgroundColor            = $Host.UI.RawUI.BackgroundColor

    BranchBehindStatusSymbol                    = [char]0x2193 # ↓ Down arrow
    BranchBehindStatusForegroundColor           = [ConsoleColor]::Red
    BranchBehindStatusBackgroundColor           = $Host.UI.RawUI.BackgroundColor

    BranchBehindAndAheadStatusSymbol            = [char]0x2195 # ↕ Up & Down arrow
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
    BeforeStashBackgroundColor                  = $Host.UI.RawUI.BackgroundColor
    BeforeStashForegroundColor                  = [ConsoleColor]::Red
    AfterStashText                              = ')'
    AfterStashBackgroundColor                   = $Host.UI.RawUI.BackgroundColor
    AfterStashForegroundColor                   = [ConsoleColor]::Red
    StashBackgroundColor                        = $Host.UI.RawUI.BackgroundColor
    StashForegroundColor                        = [ConsoleColor]::Red

    ShowStatusWhenZero                          = $true

    AutoRefreshIndex                            = $true

    # Valid values are "Full", "Compact", and "Minimal"
    BranchBehindAndAheadDisplay                 = "Full"

    EnablePromptStatus                          = !$Global:GitMissing
    EnableFileStatus                            = $true
    EnableFileStatusFromCache                   = $null
    RepositoriesInWhichToDisableFileStatus      = @( ) # Array of repository paths
    DescribeStyle                               = ''

    EnableWindowTitle                           = 'posh~git ~ '

    DefaultPromptPrefix                         = ''
    DefaultPromptSuffix                         = '$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptDebugSuffix                    = ' [DBG]$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptEnableTiming                   = $false
    DefaultPromptAbbreviateHomeDirectory        = $false

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

$ansiStrBldStack = New-Object 'System.Collections.Generic.Stack[System.Text.StringBuilder]'

function Get-AnsiStringBuilder() {
    if ($ansiStrBldStack.Count -gt 0) {
        $ansiStrBldStack.Peek();
    }
}

function Push-AnsiStringBuilder([System.Text.StringBuilder]$StringBuilder = (New-Object System.Text.StringBuilder)) {
    $ansiStrBldStack.Push($StringBuilder)
}

function Pop-AnsiStringBuilder() {
    if ($ansiStrBldStack.Count -gt 0) {
        $ansiStrBldStack.Pop();
    }
}

function Write-Prompt {
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="TextSpan")]
        [PoshGit.TextSpan]
        $TextSpan,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName="Object", ValueFromPipeline=$true)]
        [Object]
        $Object,

        [Parameter(Position=1, ParameterSetName="Object")]
        [PoshGit.ColorTransformAttribute()]
        [PoshGit.Color]
        $ForegroundColor = [PoshGit.Color]::new(),

        [Parameter(Position=2, ParameterSetName="Object")]
        [PoshGit.ColorTransformAttribute()]
        [PoshGit.Color]
        $BackgroundColor = [PoshGit.Color]::new(),

        [Parameter()]
        [System.Text.StringBuilder]$StringBuilder
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Object') {
            $TextSpan = [PoshGit.TextSpan]::new($Object, $ForegroundColor, $BackgroundColor)
        }

        if ($global:Host.UI.SupportsVirtualTerminal) {
            $ansiSeq = [PoshGit.Ansi]::GetAnsiSequence($TextSpan)
            if ($StringBuilder) {
                $StringBuilder.Append($ansiSeq) > $null
            }
            elseif ($ansiBuffer = Get-AnsiStringBuilder) {
                $ansiBuffer.Append($ansiSeq) > $null
            }
            else {
                $ansiSeq
            }
        }
        else {
            $params = @{Object = $textSpan.Text; NoNewLine = $true}
            if ($textSpan.ForegroundColor.ColorMode() -eq [ColorMode]::ColorModeConsole) {
                $params.ForegroundColor = $textSpan.ForegroundColor.ConsoleColor()
            }
            if ($textSpan.BackgroundColor.ColorMode() -eq [ColorMode]::ColorModeConsole) {
                $params.BackgroundColor = $textSpan.BackgroundColor.ConsoleColor()
            }

            Write-Host @params
        }
    }
}

function Format-BranchName($branchName){
    $s = $global:GitPromptSettings

    if($s.BranchNameLimit -gt 0 -and $branchName.Length -gt $s.BranchNameLimit)
    {
        $branchName = "{0}{1}" -f $branchName.Substring(0,$s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    return $branchName
}

function Write-GitStatus($status, [System.Text.StringBuilder]$StringBuilder) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        # if ($StringBuilder) {
        #     Push-AnsiStringBuilder $StringBuilder
        # }
        # elseif (!(Get-AnsiStringBuilder)) {
        #     Push-AnsiStringBuilder
        # }

        $strBld = New-Object System.Text.StringBuilder

        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor -StringBuilder $strBld

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

        Write-Prompt (Format-BranchName($status.Branch)) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor -StringBuilder $strBld

        if ($branchStatusText) {
            Write-Prompt  (" {0}" -f $branchStatusText) -BackgroundColor $branchStatusBackgroundColor -ForegroundColor $branchStatusForegroundColor -StringBuilder $strBld
        }

        if($s.EnableFileStatus -and $status.HasIndex) {
            Write-Prompt $s.BeforeIndexText -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor -StringBuilder $strBld

            if($s.ShowStatusWhenZero -or $status.Index.Added) {
                Write-Prompt (" $($s.FileAddedText)$($status.Index.Added.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor -StringBuilder $strBld
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
                Write-Prompt (" $($s.FileModifiedText)$($status.Index.Modified.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor -StringBuilder $strBld
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
                Write-Prompt (" $($s.FileRemovedText)$($status.Index.Deleted.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor -StringBuilder $strBld
            }

            if ($status.Index.Unmerged) {
                Write-Prompt (" $($s.FileConflictedText)$($status.Index.Unmerged.Count)") -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor -StringBuilder $strBld
            }

            if($status.HasWorking) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor -StringBuilder $strBld
            }
        }

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
                Write-Prompt (" $($s.FileAddedText)$($status.Working.Added.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor -StringBuilder $strBld
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
                Write-Prompt (" $($s.FileModifiedText)$($status.Working.Modified.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor  -StringBuilder $strBld
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
                Write-Prompt (" $($s.FileRemovedText)$($status.Working.Deleted.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor  -StringBuilder $strBld
            }

            if ($status.Working.Unmerged) {
                Write-Prompt (" $($s.FileConflictedText)$($status.Working.Unmerged.Count)") -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor  -StringBuilder $strBld
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
            Write-Prompt (" {0}" -f $localStatusSymbol) -BackgroundColor $localStatusBackgroundColor -ForegroundColor $localStatusForegroundColor -StringBuilder $strBld
        }

        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
             Write-Prompt $s.BeforeStashText -BackgroundColor $s.BeforeStashBackgroundColor -ForegroundColor $s.BeforeStashForegroundColor -StringBuilder $strBld
             Write-Prompt $status.StashCount -BackgroundColor $s.StashBackgroundColor -ForegroundColor $s.StashForegroundColor -StringBuilder $strBld
             Write-Prompt $s.AfterStashText -BackgroundColor $s.AfterStashBackgroundColor -ForegroundColor $s.AfterStashForegroundColor -StringBuilder $strBld
        }

        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor -StringBuilder $strBld

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$script:adminHeader$prefix$repoName [$($status.Branch)]"
        }

        return $strBld.ToString()
    }
    elseif ( $Global:PreviousWindowTitle ) {
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
    $Global:VcsPromptStatuses | ForEach-Object { & $_ }
}

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}

$Global:VcsPromptStatuses += $PoshGitVcsPrompt
