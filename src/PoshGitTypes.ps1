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

    hidden static [string] ToString($color) {
        $ansiTerm = "$([char]0x1b)[0m"
        $colorSwatch = "  "

        if (!$color) {
            $str = "<default>"
        }
        elseif (Test-VirtualTerminalSequece $color) {
            $txt = EscapeAnsiString $color
            $str = "${color}${colorSwatch}${ansiTerm} $txt"
        }
        else {
            $str = ""

            if ($global:GitPromptSettings.AnsiConsole) {
                $bg = Get-BackgroundVirtualTerminalSequence $color
                $str += "${bg}${colorSwatch}${ansiTerm} "
            }

            if ($color -is [int]) {
                $str += "0x{0:X6}" -f $color
            }
            else {
                $str += $color.ToString()
            }
        }

        return $str
    }

    [string] ToEscapedString() {
        if (!$global:GitPromptSettings.AnsiConsole) {
            return ""
        }

        $str = ""

        if ($this.ForegroundColor) {
            if (Test-VirtualTerminalSequece $this.ForegroundColor) {
                $str += EscapeAnsiString $this.ForegroundColor
            }
            else {
                $seq = Get-ForegroundVirtualTerminalSequence $this.ForegroundColor
                $str += EscapeAnsiString $seq
            }
        }

        if ($this.BackgroundColor) {
            if (Test-VirtualTerminalSequece $this.BackgroundColor) {
                $str += EscapeAnsiString $this.BackgroundColor
            }
            else {
                $seq = Get-BackgroundVirtualTerminalSequence $this.BackgroundColor
                $str += EscapeAnsiString $seq
            }
        }

        return $str
    }

    [string] ToString() {
        $str = "ForegroundColor: "
        $str += [PoshGitCellColor]::ToString($this.ForegroundColor) + ", "
        $str += "BackgroundColor: "
        $str += [PoshGitCellColor]::ToString($this.BackgroundColor)
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

    [string] ToAnsiString() {
        $e = [char]27 + "["
        $txt = $this.Text

        if ($this.CustomAnsi) {
            $ansi = $this.CustomAnsi
            $str = "${ansi}${txt}${e}0m"
        }
        else {
            $bg = $this.BackgroundColor
            if (($null -ne $bg) -and !(Test-VirtualTerminalSequece $bg)) {
                $bg = Get-BackgroundVirtualTerminalSequence $bg
            }

            $fg = $this.ForegroundColor
            if (($null -ne $fg) -and !(Test-VirtualTerminalSequece $fg)) {
                $fg = Get-ForegroundVirtualTerminalSequence $fg
            }

            if (($null -ne $fg) -or ($null -ne $bg)) {
                $str = "${fg}${bg}${txt}${e}0m"
            }
            else {
                $str = $txt
            }
        }

        return $str
    }

    [string] ToEscapedString() {
        if ($global:GitPromptSettings.AnsiConsole) {
            $str = EscapeAnsiString $this.ToAnsiString()
        }
        else {
            $str = $this.Text
        }

        return $str
    }

    [string] ToString() {
        $sep = " "
        if ($this.Text.Length -lt 2) {
            $sep = " " * (3 - $this.Text.Length)
        }

        if ($global:GitPromptSettings.AnsiConsole) {
            if ($this.CustomAnsi) {
                $e = [char]27 + "["
                $ansi = $this.CustomAnsi
                $escAnsi = EscapeAnsiString $this.CustomAnsi
                $txt = $this.ToAnsiString()
                $str = "Text: '$txt',${sep}CustomAnsi: '${ansi}${escAnsi}${e}0m'"
            }
            else {
                $color = [PoshGitCellColor]::new($this.ForegroundColor, $this.BackgroundColor)
                $txt = $this.ToAnsiString()
                $str = "Text: '$txt',${sep}$($color.ToString())"
            }
        }
        else {
            $color = [PoshGitCellColor]::new($this.ForegroundColor, $this.BackgroundColor)
            $txt = $this.Text
            $str = "Text: '$txt',${sep}$($color.ToString())"
        }

        return $str
    }
}

class PoshGitPromptSettings {
    [bool]$AnsiConsole = $Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")

    [PoshGitCellColor]$DefaultColor = [PoshGitCellColor]::new()
    [PoshGitCellColor]$BranchColor  = [PoshGitCellColor]::new([ConsoleColor]::Cyan)

    [PoshGitCellColor]$IndexColor   = [PoshGitCellColor]::new([ConsoleColor]::DarkGreen)
    [PoshGitCellColor]$WorkingColor = [PoshGitCellColor]::new([ConsoleColor]::DarkRed)
    [PoshGitCellColor]$StashColor   = [PoshGitCellColor]::new([ConsoleColor]::Red)
    [PoshGitCellColor]$ErrorColor   = [PoshGitCellColor]::new([ConsoleColor]::Red)

    [PoshGitTextSpan]$PathStatusSeparator      = ' '
    [PoshGitTextSpan]$BeforeStatus             = [PoshGitTextSpan]::new('[', [ConsoleColor]::Yellow)
    [PoshGitTextSpan]$DelimStatus              = [PoshGitTextSpan]::new(' |', [ConsoleColor]::Yellow)
    [PoshGitTextSpan]$AfterStatus              = [PoshGitTextSpan]::new(']', [ConsoleColor]::Yellow)

    [PoshGitTextSpan]$BeforeIndex              = [PoshGitTextSpan]::new('', [ConsoleColor]::DarkGreen)
    [PoshGitTextSpan]$BeforeStash              = [PoshGitTextSpan]::new(' (', [ConsoleColor]::Red)
    [PoshGitTextSpan]$AfterStash               = [PoshGitTextSpan]::new(')', [ConsoleColor]::Red)

    [PoshGitTextSpan]$LocalDefaultStatusSymbol = [PoshGitTextSpan]::new('', [ConsoleColor]::DarkGreen)
    [PoshGitTextSpan]$LocalWorkingStatusSymbol = [PoshGitTextSpan]::new('!', [ConsoleColor]::DarkRed)
    [PoshGitTextSpan]$LocalStagedStatusSymbol  = [PoshGitTextSpan]::new('~', [ConsoleColor]::Cyan)

    [PoshGitTextSpan]$BranchGoneStatusSymbol           = [PoshGitTextSpan]::new([char]0x00D7, [ConsoleColor]::DarkCyan) # × Multiplication sign
    [PoshGitTextSpan]$BranchIdenticalStatusSymbol      = [PoshGitTextSpan]::new([char]0x2261, [ConsoleColor]::Cyan)     # ≡ Three horizontal lines
    [PoshGitTextSpan]$BranchAheadStatusSymbol          = [PoshGitTextSpan]::new([char]0x2191, [ConsoleColor]::Green)    # ↑ Up arrow
    [PoshGitTextSpan]$BranchBehindStatusSymbol         = [PoshGitTextSpan]::new([char]0x2193, [ConsoleColor]::Red)      # ↓ Down arrow
    [PoshGitTextSpan]$BranchBehindAndAheadStatusSymbol = [PoshGitTextSpan]::new([char]0x2195, [ConsoleColor]::Yellow)   # ↕ Up & Down arrow

    [BranchBehindAndAheadDisplayOptions]$BranchBehindAndAheadDisplay = [BranchBehindAndAheadDisplayOptions]::Full

    [string]$FileAddedText       = '+'
    [string]$FileModifiedText    = '~'
    [string]$FileRemovedText     = '-'
    [string]$FileConflictedText  = '!'
    [string]$BranchUntrackedText = ''

    [bool]$EnableStashStatus     = $false
    [bool]$ShowStatusWhenZero    = $true
    [bool]$AutoRefreshIndex      = $true

    [bool]$EnablePromptStatus    = !$global:GitMissing
    [bool]$EnableFileStatus      = $true

    [Nullable[bool]]$EnableFileStatusFromCache        = $null
    [string[]]$RepositoriesInWhichToDisableFileStatus = @()

    [string]$DescribeStyle = ''
    [psobject]$WindowTitle = {param($GitStatus, [bool]$IsAdmin) "$(if ($IsAdmin) {'Administrator: '})$(if ($GitStatus) {"posh~git ~ $($GitStatus.RepoName) [$($GitStatus.Branch)] ~ "})PowerShell $($PSVersionTable.PSVersion) $([IntPtr]::Size * 8)-bit ($PID)"}

    [PoshGitTextSpan]$DefaultPromptPrefix       = ''
    [PoshGitTextSpan]$DefaultPromptPath         = '$(Get-PromptPath)'
    [PoshGitTextSpan]$DefaultPromptMiddle       = ''
    [PoshGitTextSpan]$DefaultPromptDebug        = [PoshGitTextSpan]::new(' [DBG]:', [ConsoleColor]::Magenta)
    [PoshGitTextSpan]$DefaultPromptSuffix       = '$(">" * ($nestedPromptLevel + 1)) '

    [bool]$DefaultPromptAbbreviateHomeDirectory = $true
    [bool]$DefaultPromptWriteStatusFirst        = $false
    [bool]$DefaultPromptEnableTiming            = $false
    [PoshGitTextSpan]$DefaultPromptTimingFormat = ' {0}ms'

    [int]$BranchNameLimit = 0
    [string]$TruncatedBranchSuffix = '...'

    [bool]$Debug = $false
}
