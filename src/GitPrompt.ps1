# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$defColor = New-Object PoshGit.Color

$global:GitPromptSettings = [pscustomobject]@{
    DefaultForegroundColor                 = $defColor

    BeforeText                             = New-Object PoshGit.TextSpan -Arg ' [', Yellow, $defColor
    DelimText                              = New-Object PoshGit.TextSpan -Arg ' |', Yellow, $defColor
    AfterText                              = New-Object PoshGit.TextSpan -Arg ']',  Yellow, $defColor

    FileAddedText                          = '+'
    FileModifiedText                       = '~'
    FileRemovedText                        = '-'
    FileConflictedText                     = '!'

    LocalDefaultStatusSymbol               = New-Object PoshGit.TextSpan -Arg '',  DarkGreen, $defColor
    LocalWorkingStatusSymbol               = New-Object PoshGit.TextSpan -Arg '!', DarkRed,   $defColor
    LocalStagedStatusSymbol                = New-Object PoshGit.TextSpan -Arg '~', Cyan,      $defColor

    BranchColor                            = New-Object PoshGit.TextSpan -Arg '',  Cyan,      $defColor
    BranchUntrackedSymbol                  = New-Object PoshGit.TextSpan -Arg '',  $defColor, $defColor

    # × Multiplication sign
    BranchGoneStatusSymbol                 = New-Object PoshGit.TextSpan -Arg ([char]0x00D7), DarkCyan, $defColor
    # ≡ Three horizontal lines
    BranchIdenticalStatusSymbol            = New-Object PoshGit.TextSpan -Arg ([char]0x2261), Cyan,     $defColor
    # ↑ Up arrow
    BranchAheadStatusSymbol                = New-Object PoshGit.TextSpan -Arg ([char]0x2191), Green,    $defColor
    # ↓ Down arrow
    BranchBehindStatusSymbol               = New-Object PoshGit.TextSpan -Arg ([char]0x2193), Red,      $defColor
    # ↕ Up & Down arrow
    BranchBehindAndAheadStatusSymbol       = New-Object PoshGit.TextSpan -Arg ([char]0x2195), Yellow,   $defColor

    BeforeIndexText                        = New-Object PoshGit.TextSpan -Arg '', DarkGreen, $defColor
    IndexColor                             = New-Object PoshGit.TextSpan -Arg '', DarkGreen, $defColor
    WorkingColor                           = New-Object PoshGit.TextSpan -Arg '', DarkRed,   $defColor

    EnableStashStatus                      = $false
    BeforeStashText                        = New-Object PoshGit.TextSpan -Arg ' (', Red, $defColor
    AfterStashText                         = New-Object PoshGit.TextSpan -Arg ')',  Red, $defColor
    StashTextColor                         = New-Object PoshGit.TextSpan -Arg '',   Red, $defColor

    ShowStatusWhenZero                     = $true

    AutoRefreshIndex                       = $true

    # Valid values are "Full", "Compact", and "Minimal"
    BranchBehindAndAheadDisplay            = "Full"

    EnablePromptStatus                     = !$Global:GitMissing
    EnableFileStatus                       = $true
    EnableFileStatusFromCache              = $null
    RepositoriesInWhichToDisableFileStatus = @( ) # Array of repository paths
    DescribeStyle                          = ''

    EnableWindowTitle                      = 'posh~git ~ '

    DefaultPromptPrefix                    = ''
    DefaultPromptSuffix                    = '$(''>'' * ($nestedPromptLevel + 1))'
    DefaultPromptDebugSuffix               = ' [DBG]$(''>'' * ($nestedPromptLevel + 1))'
    DefaultPromptEnableTiming              = $false
    DefaultPromptAbbreviateHomeDirectory   = $false

    Debug                                  = $false

    BranchNameLimit                        = 0
    TruncatedBranchSuffix                  = '...'
}

# Override some of the normal colors if the background color is set to the default DarkMagenta.
$s = $global:GitPromptSettings
if ($true -or $Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) {
    $s.LocalDefaultStatusSymbol.ForegroundColor = New-Object PoshGit.Color -ArgumentList Green
    $s.LocalWorkingStatusSymbol.ForegroundColor = New-Object PoshGit.Color -ArgumentList Red
    $s.BeforeIndexText.ForegroundColor          = New-Object PoshGit.Color -ArgumentList Green
    $s.IndexColor.ForegroundColor               = New-Object PoshGit.Color -ArgumentList Green
    $s.WorkingColor.ForegroundColor             = New-Object PoshGit.Color -ArgumentList Red
}

# Make this a function for mocking and user may not want to use ANSI even on a system that supports ANSI.
function UseAnsi {
    $global:Host.UI.SupportsVirtualTerminal
}

if (UseAnsi) {
    $global:GitPromptSettings.DefaultPromptSuffix      += " "
    $global:GitPromptSettings.DefaultPromptDebugSuffix += " "
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

# TODO: Real tempted to rename this to Write-AnsiHost
function Write-Prompt {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Object]
        $Object,

        [Parameter(Position=1)]
        [PoshGit.ColorTransformAttribute()]
        [PoshGit.Color]
        $ForegroundColor,

        [Parameter(Position=2)]
        [PoshGit.ColorTransformAttribute()]
        [PoshGit.Color]
        $BackgroundColor,

        [Parameter()]
        [System.Text.StringBuilder]$StringBuilder
    )

    process {
        if ($Object -is [PoshGit.TextSpan]) {
            $textSpan = $Object
        }
        else {
            $textSpan = New-Object PoshGit.TextSpan $Object
        }

        if ($ForegroundColor) {
            $textSpan.ForegroundColor = $ForegroundColor
        }

        if ($BackgroundColor) {
            $textSpan.BackgroundColor = $BackgroundColor
        }

        if (UseAnsi) {
            $ansiSeq = [PoshGit.Ansi]::GetAnsiSequence($TextSpan)
            if ($StringBuilder) {
                $StringBuilder.Append($ansiSeq) > $null
            }
            else {
                $ansiSeq
            }
        }
        else {
            $params = @{Object = $textSpan.Text; NoNewLine = $true}
            if ($textSpan.ForegroundColor.ColorMode -eq [PoshGit.ColorMode]::ConsoleColor) {
                $params.ForegroundColor = $textSpan.ForegroundColor.ConsoleColor
            }
            if ($textSpan.BackgroundColor.ColorMode -eq [PoshGit.ColorMode]::ConsoleColor) {
                $params.BackgroundColor = $textSpan.BackgroundColor.ConsoleColor
            }

            Write-Host @params
        }
    }
}

function Format-BranchName($branchName){
    $s = $global:GitPromptSettings

    if ($s.BranchNameLimit -gt 0 -and $branchName.Length -gt $s.BranchNameLimit)
    {
        $branchName = "{0}{1}" -f $branchName.Substring(0, $s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    return $branchName
}

function Write-GitStatus($status, [System.Text.StringBuilder]$StringBuilder) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {

        $strBld = $StringBuilder
        if (!$strBld) {
            $strBld = New-Object System.Text.StringBuilder
        }

        Write-Prompt $s.BeforeText -StringBuilder $strBld

        $branchStatusTextSpan = New-Object PoshGit.TextSpan -ArgumentList $s.BranchColor

        if (!$status.Upstream) {
            $branchStatusTextSpan.Text  = $s.BranchUntrackedSymbol.Text
        }
        elseif ($status.UpstreamGone -eq $true) {
            # Upstream branch is gone
            $branchStatusTextSpan       = $s.BranchGoneStatusSymbol
        }
        elseif ($status.BehindBy -eq 0 -and $status.AheadBy -eq 0) {
            # We are aligned with remote
            $branchStatusTextSpan       = $s.BranchIdenticalStatusSymbol
        }
        elseif ($status.BehindBy -ge 1 -and $status.AheadBy -ge 1) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchBehindAndAheadStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchBehindAndAheadStatusSymbol.BackgroundColor

            # We are both behind and ahead of remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full") {
                $branchStatusTextSpan.Text = "{0}{1} {2}{3}" -f $s.BranchBehindStatusSymbol.Text, $status.BehindBy, $s.BranchAheadStatusSymbol.Text, $status.AheadBy
            }
            elseif ($s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusTextSpan.Text = "{0}{1}{2}" -f $status.BehindBy, $s.BranchBehindAndAheadStatusSymbol.Text, $status.AheadBy
            }
            else {
                $branchStatusTextSpan.Text = $s.BranchBehindAndAheadStatusSymbol.Text
            }
        }
        elseif ($status.BehindBy -ge 1) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchBehindStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchBehindStatusSymbol.BackgroundColor

            # We are behind remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full" -Or $s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusTextSpan.Text = "{0}{1}" -f $s.BranchBehindStatusSymbol.Text, $status.BehindBy
            }
            else {
                $branchStatusTextSpan.Text = $s.BranchBehindStatusSymbol.Text
            }
        }
        elseif ($status.AheadBy -ge 1) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchAheadStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchAheadStatusSymbol.BackgroundColor

            # We are ahead of remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full" -Or $s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusTextSpan.Text = "{0}{1}" -f $s.BranchAheadStatusSymbol.Text, $status.AheadBy
            }
            else {
                $branchStatusTextSpan.Text = $s.BranchAheadStatusSymbol.Text
            }
        }
        else {
            # This condition should not be possible but defaulting the variables to be safe
            $branchStatusTextSpan.Text = "?"
        }

        $branchNameTextSpan = New-Object PoshGit.TextSpan -ArgumentList $branchStatusTextSpan
        $branchNameTextSpan.Text = Format-BranchName $status.Branch
        Write-Prompt $branchNameTextSpan -StringBuilder $strBld

        if ($branchStatusTextSpan.Text) {
            $branchStatusTextSpan.Text = " " + $branchStatusTextSpan.Text
            Write-Prompt $branchStatusTextSpan -StringBuilder $strBld
        }

        if ($s.EnableFileStatus -and $status.HasIndex) {
            Write-Prompt $s.BeforeIndexText -StringBuilder $strBld

            $textSpan = New-Object PoshGit.TextSpan -ArgumentList $s.IndexColor
            if ($s.ShowStatusWhenZero -or $status.Index.Added) {
                $textSpan.Text = " $($s.FileAddedText)$($status.Index.Added.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($s.ShowStatusWhenZero -or $status.Index.Modified) {
                $textSpan.Text = " $($s.FileModifiedText)$($status.Index.Modified.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($s.ShowStatusWhenZero -or $status.Index.Deleted) {
                $textSpan.Text = " $($s.FileRemovedText)$($status.Index.Deleted.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($status.Index.Unmerged) {
                $textSpan.Text = " $($s.FileConflictedText)$($status.Index.Unmerged.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($status.HasWorking) {
                Write-Prompt $s.DelimText -StringBuilder $strBld
            }
        }

        if ($s.EnableFileStatus -and $status.HasWorking) {
            $textSpan = New-Object PoshGit.TextSpan -ArgumentList $s.WorkingColor

            if ($s.ShowStatusWhenZero -or $status.Working.Added) {
                $textSpan.Text = " $($s.FileAddedText)$($status.Working.Added.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($s.ShowStatusWhenZero -or $status.Working.Modified) {
                $textSpan.Text = " $($s.FileModifiedText)$($status.Working.Modified.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($s.ShowStatusWhenZero -or $status.Working.Deleted) {
                $textSpan.Text = " $($s.FileRemovedText)$($status.Working.Deleted.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }

            if ($status.Working.Unmerged) {
                $textSpan.Text = " $($s.FileConflictedText)$($status.Working.Unmerged.Count)"
                Write-Prompt $textSpan -StringBuilder $strBld
            }
        }

        if ($status.HasWorking) {
            $localStatusSymbol = $s.LocalWorkingStatusSymbol # We have un-staged files in the working tree
        }
        elseif ($status.HasIndex) {
            $localStatusSymbol = $s.LocalStagedStatusSymbol # We have staged but uncommited files
        }
        else {
            $localStatusSymbol = $s.LocalDefaultStatusSymbol # No uncommited changes
        }

        if ($localStatusSymbol) {
            Write-Prompt $localStatusSymbol -StringBuilder $strBld
        }

        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
             $stashTextSpan = New-Object PoshGit.TextSpan $s.StashTextColor
             $stashTextSpan.Text = "$($status.StashCount)"

             Write-Prompt $s.BeforeStashText -StringBuilder $strBld
             Write-Prompt $stashTextSpan -StringBuilder $strBld
             Write-Prompt $s.AfterStashText -StringBuilder $strBld
        }

        Write-Prompt $s.AfterText -StringBuilder $strBld

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$script:adminHeader$prefix$repoName [$($status.Branch)]"
        }

        if (!$StringBuilder) {
            return $strBld.ToString()
        }
    }
    elseif ($Global:PreviousWindowTitle) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
        return ""
    }
}

if (!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}

function Global:Write-VcsStatus([System.Text.StringBuilder]$StringBuilder) {
    # Is this the right place for this call?  If someone uses Write-GitStatus (Get-GitStatus) they lose.
    Set-ConsoleMode -ANSI
    $Global:VcsPromptStatuses | ForEach-Object { & $_ $StringBuilder }
}

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    param([System.Text.StringBuilder]$StringBuilder)
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus -StringBuilder $StringBuilder
}

$Global:VcsPromptStatuses += $PoshGitVcsPrompt
