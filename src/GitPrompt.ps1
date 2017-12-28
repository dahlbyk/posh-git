# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

enum BranchBehindAndAheadDisplayOptions { Full; Compact; Minimal }

class PoshGitCellColor {
    [psobject]$BackgroundColor
    [psobject]$ForegroundColor

    PoshGitCellColor() {
        $this.ForegroundColor = $null
        $this.BackgroundColor = $null
    }

    PoshGitCellColor([psobject]$ForegroundColor) {
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $null
    }

    PoshGitCellColor([psobject]$ForegroundColor, [psobject]$BackgroundColor) {
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $BackgroundColor
    }

    hidden [string] ToString($color) {
        $ansiTerm = "$([char]0x1b)[0m"
        $colorSwatch = "  "

        if (!$color) {
            $str = "<default>"
        }
        elseif (Test-VirtualTerminalSequece $color) {
            $txt = EscapseAnsiString $color
            $str = "${color}${colorSwatch}${ansiTerm} $txt"
        }
        else {
            $str = ""

            if ($global:GitPromptSettings.AnsiConsole) {
                $bg = Get-BackgroundVirtualTerminalSequence $color
                $str += "${bg}${colorSwatch}${ansiTerm} "
            }

            $str += $color.ToString()
        }

        return $str
    }

    [string] ToString() {
        $str = "ForegroundColor: "
        $str += $this.ToString($this.ForegroundColor) + ", "
        $str += "BackgroundColor: "
        $str += $this.ToString($this.BackgroundColor)
        return $str
    }
}

class PoshGitTextSpan {
    [string]$Text
    [psobject]$BackgroundColor
    [psobject]$ForegroundColor
    [string]$CustomAnsi

    PoshGitTextSpan() {
        $this.Text = ""
        $this.ForegroundColor = $null
        $this.BackgroundColor = $null
    }

    PoshGitTextSpan([string]$Text) {
        $this.Text = $Text
        $this.ForegroundColor = $null
        $this.BackgroundColor = $null
    }

    PoshGitTextSpan([string]$Text, [psobject]$ForegroundColor) {
        $this.Text = $Text
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $null
    }

    PoshGitTextSpan([string]$Text, [psobject]$ForegroundColor, [psobject]$BackgroundColor) {
        $this.Text = $Text
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $BackgroundColor
    }

    PoshGitTextSpan([PoshGitTextSpan]$PoshGitTextSpan) {
        $this.Text = $PoshGitTextSpan.Text
        $this.ForegroundColor = $PoshGitTextSpan.ForegroundColor
        $this.BackgroundColor = $PoshGitTextSpan.BackgroundColor
    }

    PoshGitTextSpan([PoshGitCellColor]$PoshGitCellColor) {
        $this.Text = ''
        $this.ForegroundColor = $PoshGitCellColor.ForegroundColor
        $this.BackgroundColor = $PoshGitCellColor.BackgroundColor
    }

    [string] ToString() {
        if ($global:GitPromptSettings.AnsiConsole) {
            if ($this.CustomAnsi) {
                $e = [char]27 + "["
                $ansi = $this.CustomAnsi
                $escAnsi = EscapseAnsiString $this.CustomAnsi
                $txt = $this.RenderAnsi()
                $str = "Text: '$txt',`t CustomAnsi: '${ansi}${escAnsi}${e}0m'"
            }
            else {
                $color = [PoshGitCellColor]::new($this.ForegroundColor, $this.BackgroundColor)
                $txt = $this.RenderAnsi()
                $str = "Text: '$txt',`t $($color.ToString())"
            }
        }
        else {
            $color = [PoshGitCellColor]::new($this.ForegroundColor, $this.BackgroundColor)
            $txt = $this.Text
            $str = "Text: '$txt',`t $($color.ToString())"
        }

        return $str
    }

    [string] RenderAnsi() {
        $e = [char]27 + "["
        $txt = $this.Text

        if ($this.CustomAnsi) {
            $ansi = $this.CustomAnsi
            $str = "${ansi}${txt}${e}0m"
        }
        else {
            $bg = $this.BackgroundColor
            if ($bg -and !(Test-VirtualTerminalSequece $bg)) {
                $bg = Get-BackgroundVirtualTerminalSequence $bg
            }

            $fg = $this.ForegroundColor
            if ($fg -and !(Test-VirtualTerminalSequece $fg)) {
                $fg = Get-ForegroundVirtualTerminalSequence $fg
            }

            $str = "${fg}${bg}${txt}${e}0m"
        }

        return $str
    }
}

$global:GitPromptSettings = [pscustomobject]@{
    DefaultColor                           = [PoshGitCellColor]::new()
    BranchColor                            = [PoshGitCellColor]::new([ConsoleColor]::Cyan)
    IndexColor                             = [PoshGitCellColor]::new([ConsoleColor]::DarkGreen)
    WorkingColor                           = [PoshGitCellColor]::new([ConsoleColor]::DarkRed)
    StashColor                             = [PoshGitCellColor]::new([ConsoleColor]::Red)
    ErrorColor                             = [PoshGitCellColor]::new([ConsoleColor]::Red)

    BeforeText                             = [PoshGitTextSpan]::new(' [', [ConsoleColor]::Yellow)
    DelimText                              = [PoshGitTextSpan]::new(' |', [ConsoleColor]::Yellow)
    AfterText                              = [PoshGitTextSpan]::new(']',  [ConsoleColor]::Yellow)

    LocalDefaultStatusSymbol               = [PoshGitTextSpan]::new('',  [ConsoleColor]::DarkGreen)
    LocalWorkingStatusSymbol               = [PoshGitTextSpan]::new('!', [ConsoleColor]::DarkRed)
    LocalStagedStatusSymbol                = [PoshGitTextSpan]::new('~', [ConsoleColor]::DarkCyan)

    BranchGoneStatusSymbol                 = [PoshGitTextSpan]::new([char]0x00D7, [ConsoleColor]::DarkCyan) # × Multiplication sign
    BranchIdenticalStatusSymbol            = [PoshGitTextSpan]::new([char]0x2261, [ConsoleColor]::Cyan)     # ≡ Three horizontal lines
    BranchAheadStatusSymbol                = [PoshGitTextSpan]::new([char]0x2191, [ConsoleColor]::Green)    # ↑ Up arrow
    BranchBehindStatusSymbol               = [PoshGitTextSpan]::new([char]0x2193, [ConsoleColor]::Red)      # ↓ Down arrow
    BranchBehindAndAheadStatusSymbol       = [PoshGitTextSpan]::new([char]0x2195, [ConsoleColor]::Yellow)   # ↕ Up & Down arrow

    BeforeIndexText                        = [PoshGitTextSpan]::new('',  [ConsoleColor]::DarkGreen)
    BeforeStashText                        = [PoshGitTextSpan]::new(' (', [ConsoleColor]::Red)
    AfterStashText                         = [PoshGitTextSpan]::new(')',  [ConsoleColor]::Red)

    FileAddedText                          = '+'
    FileModifiedText                       = '~'
    FileRemovedText                        = '-'
    FileConflictedText                     = '!'
    BranchUntrackedText                    = ''

    BranchBehindAndAheadDisplay            = [BranchBehindAndAheadDisplayOptions]"Full"

    EnableStashStatus                      = $false
    ShowStatusWhenZero                     = $true
    AutoRefreshIndex                       = $true

    EnablePromptStatus                     = !$global:GitMissing
    EnableFileStatus                       = $true
    EnableFileStatusFromCache              = $null
    RepositoriesInWhichToDisableFileStatus = @() # Array of repository paths
    DescribeStyle                          = ''

    EnableWindowTitle                      = 'posh~git ~ '

    AnsiConsole                            = $Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")

    DefaultPromptPrefix                    = ''
    DefaultPromptSuffix                    = '$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptDebugSuffix               = ' [DBG]$(''>'' * ($nestedPromptLevel + 1)) '
    DefaultPromptEnableTiming              = $false
    DefaultPromptAbbreviateHomeDirectory   = $false

    Debug                                  = $false

    BranchNameLimit                        = 0
    TruncatedBranchSuffix                  = '...'
}

# Override some of the normal colors if the background color is set to the default DarkMagenta.
$s = $global:GitPromptSettings
if ($Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) {
    $s.LocalDefaultStatusSymbol.ForegroundColor = 'Green'
    $s.LocalWorkingStatusSymbol.ForegroundColor = 'Red'
    $s.BeforeIndexText.ForegroundColor          = 'Green'
    $s.IndexColor.ForegroundColor               = 'Green'
    $s.WorkingColor.ForegroundColor             = 'Red'
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
# TODO: Hmm, this is a curious way to detemine window title supported
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt {
    param(
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter()]
        $ForegroundColor = $null,

        [Parameter()]
        $BackgroundColor = $null,

        [Parameter(ValueFromPipeline = $true)]
        [Text.StringBuilder]
        $Builder
    )

    $s = $global:GitPromptSettings
    if ($s) {
        if ($null -eq $ForegroundColor) {
            $ForegroundColor = $s.DefaultColor.ForegroundColor
        }

        if ($null -eq $BackgroundColor) {
            $BackgroundColor = $s.DefaultColor.BackgroundColor
        }
    }

    if ($GitPromptSettings.AnsiConsole) {
        if ($Object -is [PoshGitTextSpan]) {
            $str = $Object.RenderAnsi()
        }
        else {
            $e = [char]27 + "["
            $f = Get-ForegroundVirtualTerminalSequence $ForegroundColor
            $b = Get-BackgroundVirtualTerminalSequence $BackgroundColor
            $str = "${f}${b}${Object}${e}0m"
        }

        if ($Builder) {
            return $Builder.Append($str)
        }

        return $str
    }

    if ($Object -is [PoshGitTextSpan]) {
        $BackgroundColor = $Object.BackgroundColor
        $ForegroundColor = $Object.ForegroundColor
        $Object = $Object.Text
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
    if ($Builder) {
        return $Builder
    }

    return ""
}

function Format-BranchName($branchName){
    $s = $global:GitPromptSettings
    if (($s.BranchNameLimit -gt 0) -and ($branchName.Length -gt $s.BranchNameLimit))
    {
        $branchName = "{0}{1}" -f $branchName.Substring(0,$s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    return $branchName
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    $sb = [System.Text.StringBuilder]::new(150)

    if ($status -and $s) {
        $sb | Write-Prompt $s.BeforeText > $null

        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchColor)

        if (!$status.Upstream) {
            $branchStatusTextSpan.Text = $s.BranchUntrackedText
        }
        elseif ($status.UpstreamGone -eq $true) {
            # Upstream branch is gone
            $branchStatusTextSpan = $s.BranchGoneStatusSymbol
        }
        elseif (($status.BehindBy -eq 0) -and ($status.AheadBy -eq 0)) {
            # We are aligned with remote
            $branchStatusTextSpan = $s.BranchIdenticalStatusSymbol
        }
        elseif (($status.BehindBy -ge 1) -and ($status.AheadBy -ge 1)) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchBehindAndAheadStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchBehindAndAheadStatusSymbol.BackgroundColor

            # We are both behind and ahead of remote
            if ($s.BranchBehindAndAheadDisplay -eq "Full") {
                $branchStatusTextSpan.Text = ("{0}{1} {2}{3}" -f $s.BranchBehindStatusSymbol.Text, $status.BehindBy, $s.BranchAheadStatusSymbol.Text, $status.AheadBy)
            }
            elseif ($s.BranchBehindAndAheadDisplay -eq "Compact") {
                $branchStatusTextSpan.Text = ("{0}{1}{2}" -f $status.BehindBy, $s.BranchBehindAndAheadStatusSymbol.Text, $status.AheadBy)
            }
            else {
                $branchStatusTextSpan.Text = $s.BranchBehindAndAheadStatusSymbol.Text
            }
        }
        elseif ($status.BehindBy -ge 1) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchBehindStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchBehindStatusSymbol.BackgroundColor

            # We are behind remote
            if (($s.BranchBehindAndAheadDisplay -eq "Full") -Or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
                $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchBehindStatusSymbol.Text, $status.BehindBy)
            }
            else {
                $branchStatusTextSpan.Text = $s.BranchBehindStatusSymbol.Text
            }
        }
        elseif ($status.AheadBy -ge 1) {
            $branchStatusTextSpan.ForegroundColor = $s.BranchAheadStatusSymbol.ForegroundColor
            $branchStatusTextSpan.BackgroundColor = $s.BranchAheadStatusSymbol.BackgroundColor

            # We are ahead of remote
            if (($s.BranchBehindAndAheadDisplay -eq "Full") -or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
                $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchAheadStatusSymbol.Text, $status.AheadBy)
            } else {
                $branchStatusTextSpan.Text = $s.BranchAheadStatusSymbol.Text
            }
        }
        else {
            # This condition should not be possible but defaulting the variables to be safe
            $branchStatusTextSpan.Text = "?"
        }

        $branchNameTextSpan = [PoshGitTextSpan]::new($branchStatusTextSpan)
        $branchNameTextSpan.Text = Format-BranchName $status.Branch
        $sb | Write-Prompt $branchNameTextSpan > $null

        if ($branchStatusTextSpan.Text) {
            $textSpan = [PoshGitTextSpan]::new($branchStatusTextSpan)
            $textSpan.Text = " " + $branchStatusTextSpan.Text
            $sb | Write-Prompt $textSpan > $null
        }

        if ($s.EnableFileStatus -and $status.HasIndex) {
            $sb | Write-Prompt $s.BeforeIndexText > $null

            $statusTextSpan = [PoshGitTextSpan]::new($s.IndexColor)
            if ($s.ShowStatusWhenZero -or $status.Index.Added) {
                $statusTextSpan.Text = " $($s.FileAddedText)$($status.Index.Added.Count)"
                $sb | Write-Prompt $statusTextSpan > $null
            }

            if ($s.ShowStatusWhenZero -or $status.Index.Modified) {
                $statusTextSpan.Text = " $($s.FileModifiedText)$($status.Index.Modified.Count)"
                $sb | Write-Prompt $statusTextSpan > $null
            }

            if ($s.ShowStatusWhenZero -or $status.Index.Deleted) {
                $statusTextSpan.Text = " $($s.FileRemovedText)$($status.Index.Deleted.Count)"
                $sb | Write-Prompt $statusTextSpan > $null
            }

            if ($status.Index.Unmerged) {
                $statusTextSpan.Text = " $($s.FileConflictedText)$($status.Index.Unmerged.Count)"
                $sb | Write-Prompt $statusTextSpan > $null
            }

            if($status.HasWorking) {
                $sb | Write-Prompt $s.DelimText > $null
            }
        }

        if ($s.EnableFileStatus -and $status.HasWorking) {
            $workingTextSpan = [PoshGitTextSpan]::new($s.WorkingColor)

            if ($s.ShowStatusWhenZero -or $status.Working.Added) {
                $workingTextSpan.Text = " $($s.FileAddedText)$($status.Working.Added.Count)"
                $sb | Write-Prompt $workingTextSpan > $null
            }

            if ($s.ShowStatusWhenZero -or $status.Working.Modified) {
                $workingTextSpan.Text = " $($s.FileModifiedText)$($status.Working.Modified.Count)"
                $sb | Write-Prompt $workingTextSpan > $null
            }

            if ($s.ShowStatusWhenZero -or $status.Working.Deleted) {
                $workingTextSpan.Text = " $($s.FileRemovedText)$($status.Working.Deleted.Count)"
                $sb | Write-Prompt $workingTextSpan > $null
            }

            if ($status.Working.Unmerged) {
                $workingTextSpan.Text = " $($s.FileConflictedText)$($status.Working.Unmerged.Count)"
                $sb | Write-Prompt $workingTextSpan > $null
            }
        }

        if ($status.HasWorking) {
            # We have un-staged files in the working tree
            $localStatusSymbol = $s.LocalWorkingStatusSymbol
        }
        elseif ($status.HasIndex) {
            # We have staged but uncommited files
            $localStatusSymbol = $s.LocalStagedStatusSymbol
        }
        else {
            # No uncommited changes
            $localStatusSymbol = $s.LocalDefaultStatusSymbol
        }

        if ($localStatusSymbol.Text) {
            $textSpan = [PoshGitTextSpan]::new($localStatusSymbol)
            $textSpan.Text = " " + $localStatusSymbol.Text
            $sb | Write-Prompt $textSpan > $null
        }

        if ($s.EnableStashStatus -and ($status.StashCount -gt 0)) {
            $stashTextSpan = [PoshGitTextSpan]::new($s.StashColor)
            $stashTextSpan.Text = "$($status.StashCount)"

            $sb | Write-Prompt $s.BeforeStashText > $null
            $sb | Write-Prompt $stashTextSpan > $null
            $sb | Write-Prompt $s.AfterStashText > $null
        }

        $sb | Write-Prompt $s.AfterText > $null

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if (!$global:PreviousWindowTitle) {
                $global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }

            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$script:adminHeader$prefix$repoName [$($status.Branch)]"
        }

        return $sb.ToString()
    }
    elseif ($global:PreviousWindowTitle) {
        $Host.UI.RawUI.WindowTitle = $global:PreviousWindowTitle
        return ""
    }
}

if (!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $global:VcsPromptStatuses = @()
}

function Global:Write-VcsStatus {
    Set-ConsoleMode -ANSI
    $global:VcsPromptStatuses | ForEach-Object { & $_ }
}

# Add scriptblock that will execute for Write-VcsStatus
$PoshGitVcsPrompt = {
    try {
        $global:GitStatus = Get-GitStatus
        Write-GitStatus $GitStatus
    }
    catch {
        $s = $global:GitPromptSettings
        if ($s) {
            Write-Prompt $s.BeforeText
            Write-Prompt "Error: $_" -BackgroundColor $s.ErrorColor.BackgroundColor -ForegroundColor $s.ErrorColor.ForegroundColor
            Write-Prompt $s.AfterText
        }
    }
}

$global:VcsPromptStatuses += $PoshGitVcsPrompt
