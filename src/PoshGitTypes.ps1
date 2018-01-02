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
        $this.CustomAnsi = $null
    }

    PoshGitTextSpan([string]$Text) {
        $this.Text = $Text
        $this.ForegroundColor = $null
        $this.BackgroundColor = $null
        $this.CustomAnsi = $null
    }

    PoshGitTextSpan([string]$Text, [psobject]$ForegroundColor) {
        $this.Text = $Text
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $null
        $this.CustomAnsi = $null
    }

    PoshGitTextSpan([string]$Text, [psobject]$ForegroundColor, [psobject]$BackgroundColor) {
        $this.Text = $Text
        $this.ForegroundColor = $ForegroundColor
        $this.BackgroundColor = $BackgroundColor
        $this.CustomAnsi = $null
    }

    PoshGitTextSpan([PoshGitTextSpan]$PoshGitTextSpan) {
        $this.Text = $PoshGitTextSpan.Text
        $this.ForegroundColor = $PoshGitTextSpan.ForegroundColor
        $this.BackgroundColor = $PoshGitTextSpan.BackgroundColor
        $this.CustomAnsi = $PoshGitTextSpan.CustomAnsi
    }

    PoshGitTextSpan([PoshGitCellColor]$PoshGitCellColor) {
        $this.Text = ''
        $this.ForegroundColor = $PoshGitCellColor.ForegroundColor
        $this.BackgroundColor = $PoshGitCellColor.BackgroundColor
        $this.CustomAnsi = $null
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

class GitPromptSettings {
    [bool]$AnsiConsole = $Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")

    [PoshGitCellColor]$DefaultColor = [PoshGitCellColor]::new()
    [PoshGitCellColor]$BranchColor = [PoshGitCellColor]::new([ConsoleColor]::Cyan)

    [PoshGitCellColor]$IndexColor = [PoshGitCellColor]::new([ConsoleColor]::DarkGreen)
    [PoshGitCellColor]$WorkingColor = [PoshGitCellColor]::new([ConsoleColor]::DarkRed)
    [PoshGitCellColor]$StashColor = [PoshGitCellColor]::new([ConsoleColor]::Red)
    [PoshGitCellColor]$ErrorColor = [PoshGitCellColor]::new([ConsoleColor]::Red)

    [PoshGitTextSpan]$BeforeText = [PoshGitTextSpan]::new(' [', [ConsoleColor]::Yellow)
    [PoshGitTextSpan]$DelimText = [PoshGitTextSpan]::new(' |', [ConsoleColor]::Yellow)
    [PoshGitTextSpan]$AfterText = [PoshGitTextSpan]::new(']', [ConsoleColor]::Yellow)

    [PoshGitTextSpan]$BeforeIndexText = [PoshGitTextSpan]::new('', [ConsoleColor]::DarkGreen)
    [PoshGitTextSpan]$BeforeStashText = [PoshGitTextSpan]::new(' (', [ConsoleColor]::Red)
    [PoshGitTextSpan]$AfterStashText = [PoshGitTextSpan]::new(')', [ConsoleColor]::Red)

    [PoshGitTextSpan]$LocalDefaultStatusSymbol = [PoshGitTextSpan]::new('', [ConsoleColor]::DarkGreen)
    [PoshGitTextSpan]$LocalWorkingStatusSymbol = [PoshGitTextSpan]::new('!', [ConsoleColor]::DarkRed)
    [PoshGitTextSpan]$LocalStagedStatusSymbol = [PoshGitTextSpan]::new('~', [ConsoleColor]::DarkCyan)

    [PoshGitTextSpan]$BranchGoneStatusSymbol = [PoshGitTextSpan]::new([char]0x00D7, [ConsoleColor]::DarkCyan) # × Multiplication sign
    [PoshGitTextSpan]$BranchIdenticalStatusSymbol = [PoshGitTextSpan]::new([char]0x2261, [ConsoleColor]::Cyan)     # ≡ Three horizontal lines
    [PoshGitTextSpan]$BranchAheadStatusSymbol = [PoshGitTextSpan]::new([char]0x2191, [ConsoleColor]::Green)    # ↑ Up arrow
    [PoshGitTextSpan]$BranchBehindStatusSymbol = [PoshGitTextSpan]::new([char]0x2193, [ConsoleColor]::Red)      # ↓ Down arrow
    [PoshGitTextSpan]$BranchBehindAndAheadStatusSymbol = [PoshGitTextSpan]::new([char]0x2195, [ConsoleColor]::Yellow)   # ↕ Up & Down arrow

    [BranchBehindAndAheadDisplayOptions]$BranchBehindAndAheadDisplay = [BranchBehindAndAheadDisplayOptions]::Full

    [string]$FileAddedText = '+'
    [string]$FileModifiedText = '~'
    [string]$FileRemovedText = '-'
    [string]$FileConflictedText = '!'
    [string]$BranchUntrackedText = ''

    [bool]$EnableStashStatus = $false
    [bool]$ShowStatusWhenZero = $true
    [bool]$AutoRefreshIndex = $true

    [bool]$EnablePromptStatus = !$global:GitMissing
    [bool]$EnableFileStatus = $true
    [Nullable[bool]]$EnableFileStatusFromCache = $null
    [string[]]$RepositoriesInWhichToDisableFileStatus = @()

    [string]$DescribeStyle = ''
    [psobject]$EnableWindowTitle = 'posh~git ~ '

    [string]$DefaultPromptPrefix = ''
    [string]$DefaultPromptSuffix = '$(''>'' * ($nestedPromptLevel + 1)) '
    [string]$DefaultPromptDebugSuffix = ' [DBG]$(''>'' * ($nestedPromptLevel + 1)) '
    [bool]$DefaultPromptEnableTiming = $false
    [bool]$DefaultPromptAbbreviateHomeDirectory = $false

    [int]$BranchNameLimit = 0
    [string]$TruncatedBranchSuffix = '...'

    [bool]$Debug = $false
}
