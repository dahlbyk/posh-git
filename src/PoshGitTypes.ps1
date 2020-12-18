enum BranchBehindAndAheadDisplayOptions { Full; Compact; Minimal }
enum UntrackedFilesMode { Default; No; Normal; All }

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
        $ansiTerm = "$([char]27)[0m"
        $colorSwatch = "  "
        $str = ""

        if (!$color) {
            $str = "<default>"
        }
        elseif (Test-VirtualTerminalSequece $color -Force) {
            if ($global:GitPromptSettings.AnsiConsole) {
                # Use '#' for FG color swatch since we are just applying the VT seqs as-is and
                # a " " swatch char won't show anything for a FG color.
                if ($color -eq $this.ForegroundColor) {
                    $colorSwatch = "#"
                }

                $str = "${color}$colorSwatch${ansiTerm} "
            }

            $str = "`"$(EscapeAnsiString $color)`""
        }
        else {
            if ($global:GitPromptSettings.AnsiConsole) {
                $bg = Get-BackgroundVirtualTerminalSequence $color
                $str = "${bg}${colorSwatch}${ansiTerm} "
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

    [PoshGitTextSpan] Expand() {
        if (!$this.Text) {
            return $this
        }

        $execContext = Get-Variable ExecutionContext -ValueOnly
        $expandedText = $execContext.SessionState.InvokeCommand.ExpandString($this.Text)
        $newTextSpan = [PoshGitTextSpan]::new($expandedText, $this.ForegroundColor, $this.BackgroundColor)
        return $newTextSpan
    }

    # This method is used by Write-Prompt to render an instance of a PoshGitTextSpan when
    # $GitPromptSettings.AnsiConsole is $true.  It is also used by the default ToString()
    # implementation to display any ANSI seqs when AnsiConsole is $true.
    [string] ToAnsiString() {
        # If we know which colors were changed, we can reset only these and leave others be.
        $reset = [System.Collections.Generic.List[string]]::new()
        $e = [char]27 + "["

        $fg = $this.ForegroundColor
        if (($null -ne $fg) -and !(Test-VirtualTerminalSequece $fg)) {
            $fg = Get-ForegroundVirtualTerminalSequence $fg
            $reset.Add('39')
        }

        $bg = $this.BackgroundColor
        if (($null -ne $bg) -and !(Test-VirtualTerminalSequece $bg)) {
            $bg = Get-BackgroundVirtualTerminalSequence $bg
            $reset.Add('49')
        }

        $txt = $this.Text
        $str = "${fg}${bg}${txt}"

        # ALWAYS terminate a VT sequence in case the host supports VT (regardless of AnsiConsole setting),
        # or the host display can get messed up.
        if (Test-VirtualTerminalSequece $txt -Force) {
            $reset.Clear()
            $reset.Add('0')
        }

        if ($reset.Count -gt 0) {
            $str += "${e}$($reset -join ';')m"
        }

        return $str
    }

    [string] ToEscapedString() {
        $str = EscapeAnsiString $this.ToAnsiString()
        return $str
    }

    # This method is used when displaying the "value" of PoshGitTextSpan e.g. when evaluating $GitPromptSettings
    [string] ToString() {
        $sep = " "
        if ($this.Text.Length -lt 2) {
            $sep = " " * (3 - $this.Text.Length)
        }

        if ($global:GitPromptSettings.AnsiConsole) {
            $txt = $this.ToAnsiString()
            if (Test-VirtualTerminalSequece $txt) {
                $escAnsi = "ANSI: `"$(EscapeAnsiString $txt)`""
                $str = "Text: `"$txt`e[39;49m`",${sep}${escAnsi}"
            }
            else {
                $str = "Text: `"$txt`""
            }
        }
        else {
            $txt = $this.Text
            if (Test-VirtualTerminalSequece $txt -Force) {
                $txt = EscapeAnsiString $txt
            }

            $color = [PoshGitCellColor]::new($this.ForegroundColor, $this.BackgroundColor)
            $str = "Text: `"$txt`",${sep}$($color.ToString())"
        }

        return $str
    }
}

class PoshGitPromptSettings {
    [bool]$AnsiConsole = ($Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")) -and !$script:GitCygwin
    [bool]$SetEnvColumns = $true

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

    [PoshGitTextSpan]$BeforePath               = [PoshGitTextSpan]::new('', [ConsoleColor]::Yellow)
    [PoshGitTextSpan]$AfterPath                = [PoshGitTextSpan]::new('', [ConsoleColor]::Yellow)

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

    [UntrackedFilesMode]$UntrackedFilesMode = [UntrackedFilesMode]::Default

    [bool]$EnablePromptStatus    = !$global:GitMissing
    [bool]$EnableFileStatus      = $true

    [Nullable[bool]]$EnableFileStatusFromCache        = $null
    [string[]]$RepositoriesInWhichToDisableFileStatus = @()

    [string]$DescribeStyle = ''
    [psobject]$WindowTitle = {param($GitStatus, [bool]$IsAdmin) "$(if ($IsAdmin) {'Admin: '})$(if ($GitStatus) {"$($GitStatus.RepoName) [$($GitStatus.Branch)]"} else {Get-PromptPath}) - PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) $(if ([IntPtr]::Size -eq 4) {'32-bit '})($PID)"}

    [PoshGitTextSpan]$DefaultPromptPrefix       = '$(Get-PromptConnectionInfo -Format "[{1}@{0}]: ")'
    [PoshGitTextSpan]$DefaultPromptPath         = '$(Get-PromptPath)'
    [PoshGitTextSpan]$DefaultPromptBeforeSuffix = ''
    [PoshGitTextSpan]$DefaultPromptDebug        = [PoshGitTextSpan]::new(' [DBG]:', [ConsoleColor]::Magenta)
    [PoshGitTextSpan]$DefaultPromptSuffix       = '$(">" * ($nestedPromptLevel + 1)) '

    [bool]$DefaultPromptAbbreviateHomeDirectory = ($PSVersionTable.PSVersion.Major -gt 5) -and !$IsWindows
    [bool]$DefaultPromptAbbreviateGitDirectory  = $false
    [bool]$DefaultPromptWriteStatusFirst        = $false
    [bool]$DefaultPromptEnableTiming            = $false
    [PoshGitTextSpan]$DefaultPromptTimingFormat = ' {0}ms'

    [int]$BranchNameLimit = 0
    [string]$TruncatedBranchSuffix = '...'

    [bool]$Debug = $false
}

class PoshGitPromptValues {
    [int]$LastExitCode
    [bool]$DollarQuestion
    [bool]$IsAdmin
    [string]$LastPrompt
}
