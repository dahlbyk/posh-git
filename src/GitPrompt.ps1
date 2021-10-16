# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = [PoshGitPromptSettings]::new()
$global:GitPromptValues = [PoshGitPromptValues]::new()

# Override some of the normal colors if the background color is set to the default DarkMagenta.
$s = $global:GitPromptSettings
if ($Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) {
    $s.LocalDefaultStatusSymbol.ForegroundColor = 'Green'
    $s.LocalWorkingStatusSymbol.ForegroundColor = 'Red'
    $s.BeforeIndex.ForegroundColor              = 'Green'
    $s.IndexColor.ForegroundColor               = 'Green'
    $s.WorkingColor.ForegroundColor             = 'Red'
}

<#
.SYNOPSIS
    Creates a new instance of a PoshGitPromptSettings object that can be assigned to $GitPromptSettings.
.DESCRIPTION
    Creates a new instance of a PoshGitPromptSettings object that can be used to reset the
    $GitPromptSettings back to its default.
.INPUTS
    None
.OUTPUTS
    PoshGitPromptSettings
.EXAMPLE
    PS> $GitPromptSettings = New-GitPromptSettings
    This will reset the current $GitPromptSettings back to its default.
#>
function New-GitPromptSettings {
    [PoshGitPromptSettings]::new()
}

<#
.SYNOPSIS
    Writes the object to the display or renders it as a string using ANSI/VT sequences.
.DESCRIPTION
    Writes the specified object to the display unless $GitPromptSettings.AnsiConsole
    is enabled.  In this case, the Object is rendered, along with the specified
    colors, as a string with the appropriate ANSI/VT sequences for colors embedded
    in the string.  If a StringBuilder is provided, the string is appended to the
    StringBuilder.
.EXAMPLE
    PS C:\> Write-Prompt "PS > " -ForegroundColor Cyan -BackgroundColor Black
    On a system where $GitPromptSettings.AnsiConsole is set to $false, this
    will write the above to the display using the Write-Host command.
    If AnsiConsole is set to $true, this will return a string of the form:
    "`e[96m`e[40mPS > `e[0m".
.EXAMPLE
    PS C:\> $sb = [System.Text.StringBuilder]::new()
    PS C:\> $sb | Write-Prompt "PS > " -ForegroundColor Cyan -BackgroundColor Black
    On a system where $GitPromptSettings.AnsiConsole is set to $false, this
    will write the above to the display using the Write-Host command.
    If AnsiConsole is set to $true, this will append the following string to the
    StringBuilder object piped into the command:
    "`e[96m`e[40mPS > `e[0m".
#>
function Write-Prompt {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        # Specifies objects to display in the console or render as a string if
        # $GitPromptSettings.AnsiConsole is enabled. If the Object is of type
        # [PoshGitTextSpan] the other color parameters are ignored since a
        # [PoshGitTextSpan] provides the colors.
        [Parameter(Mandatory, Position=0)]
        $Object,

        # Specifies the foreground color.
        [Parameter(ParameterSetName="Default")]
        $ForegroundColor = $null,

        # Specifies the background color.
        [Parameter(ParameterSetName="Default")]
        $BackgroundColor = $null,

        # Specifies both the background and foreground colors via [PoshGitCellColor] object.
        [Parameter(ParameterSetName="CellColor")]
        [ValidateNotNull()]
        [PoshGitCellColor]
        $Color,

        # When specified and $GitPromptSettings.AnsiConsole is enabled, the Object parameter
        # is written to the StringBuilder along with the appropriate ANSI/VT sequences for
        # the specified foreground and background colors.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder
    )

    if (!$Object -or (($Object -is [PoshGitTextSpan]) -and !$Object.Text)) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    if ($PSCmdlet.ParameterSetName -eq "CellColor") {
        $bgColor = $Color.BackgroundColor
        $fgColor = $Color.ForegroundColor
    }
    else {
        $bgColor = $BackgroundColor
        $fgColor = $ForegroundColor
    }

    $s = $global:GitPromptSettings
    if ($s) {
        if ($null -eq $fgColor) {
            $fgColor = $s.DefaultColor.ForegroundColor
        }

        if ($null -eq $bgColor) {
            $bgColor = $s.DefaultColor.BackgroundColor
        }

        if ($s.AnsiConsole) {
            if ($Object -is [PoshGitTextSpan]) {
                $str = $Object.ToAnsiString()
            }
            else {
                # If we know which colors were changed, we can reset only these and leave others be.
                $reset = [System.Collections.Generic.List[string]]::new()
                $e = [char]27 + "["

                $fg = $fgColor
                if (($null -ne $fg) -and !(Test-VirtualTerminalSequece $fg)) {
                    $fg = Get-ForegroundVirtualTerminalSequence $fg
                    $reset.Add('39')
                }

                $bg = $bgColor
                if (($null -ne $bg) -and !(Test-VirtualTerminalSequece $bg)) {
                    $bg = Get-BackgroundVirtualTerminalSequence $bg
                    $reset.Add('49')
                }

                $str = "${Object}"
                if (Test-VirtualTerminalSequece $str -Force) {
                    $reset.Clear()
                    $reset.Add('0')
                }

                $str = "${fg}${bg}" + $str
                if ($reset.Count -gt 0) {
                    $str += "${e}$($reset -join ';')m"
                }
            }

            return $(if ($StringBuilder) { $StringBuilder.Append($str) } else { $str })
        }
    }

    if ($Object -is [PoshGitTextSpan]) {
        $bgColor = $Object.BackgroundColor
        $fgColor = $Object.ForegroundColor
        $Object = $Object.Text
    }

    $writeHostParams = @{
        Object = $Object;
        NoNewLine = $true;
    }

    if ($bgColor -and ($bgColor -ge 0) -and ($bgColor -le 15)) {
        $writeHostParams.BackgroundColor = $bgColor
    }

    if ($fgColor -and ($fgColor -ge 0) -and ($fgColor -le 15)) {
        $writeHostParams.ForegroundColor = $fgColor
    }

    Write-Host @writeHostParams
    return $(if ($StringBuilder) { $StringBuilder } else { "" })
}

<#
.SYNOPSIS
    Writes the Git status for repo.  Typically, you use Write-VcsStatus
    function instead of this one.
.DESCRIPTION
    Writes the Git status for repo. This includes the branch name, branch
    status with respect to its remote (if exists), index status, working
    dir status, working dir local status and stash count (optional).
    Various settings from GitPromptSettngs are used to format and color
    the Git status.

    On systems that support ANSI terminal sequences, this method will
    return a string containing ANSI sequences to color various parts of
    the Git status string.  This string can be written to the host and
    the ANSI sequences will be interpreted and converted to the specified
    behaviors which is typically setting the foreground and/or background
    color of text.
.EXAMPLE
    PS C:\> Write-GitStatus (Get-GitStatus)

    Writes the Git status for the current repo.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String
        This command returns a System.String object.
#>
function Write-GitStatus {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return
    }

    $sb = [System.Text.StringBuilder]::new(150)

    # When prompt is first (default), place the separator before the status summary
    if (!$s.DefaultPromptWriteStatusFirst) {
        $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
    }

    $sb | Write-Prompt $s.BeforeStatus > $null
    $sb | Write-GitBranchName $Status -NoLeadingSpace > $null
    $sb | Write-GitBranchStatus $Status > $null

    $sb | Write-Prompt $s.BeforeIndex > $null

    if ($s.EnableFileStatus -and $Status.HasIndex) {
        $sb | Write-GitIndexStatus $Status > $null

        if ($Status.HasWorking) {
            $sb | Write-Prompt $s.DelimStatus > $null
        }
    }

    if ($s.EnableFileStatus -and $Status.HasWorking) {
        $sb | Write-GitWorkingDirStatus $Status > $null
    }

    $sb | Write-GitWorkingDirStatusSummary $Status > $null

    if ($s.EnableStashStatus -and ($Status.StashCount -gt 0)) {
        $sb | Write-GitStashCount $Status > $null
    }

    $sb | Write-Prompt $s.AfterStatus > $null

    # When status is first, place the separator after the status summary
    if ($s.DefaultPromptWriteStatusFirst) {
        $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
    }

    if ($sb.Length -gt 0) {
        $sb.ToString()
    }
}

<#
.SYNOPSIS
    Formats the branch name text according to $GitPromptSettings.
.DESCRIPTION
    Formats the branch name text according the $GitPromptSettings:
    BranchNameLimit and TruncatedBranchSuffix.
.EXAMPLE
    PS C:\> $branchName = Format-GitBranchName (Get-GitStatus).Branch

    Gets the branch name formatted as specified by the user's $GitPromptSettings.
.INPUTS
    System.String
        This is the branch name as a string.
.OUTPUTS
    System.String
        This command returns a System.String object.
#>
function Format-GitBranchName {
    param(
        # The branch name to format according to the GitPromptSettings:
        # BranchNameLimit and TruncatedBranchSuffix.
        [Parameter(Position=0)]
        [string]
        $BranchName
    )

    $s = $global:GitPromptSettings
    if (!$s -or !$BranchName) {
        return "$BranchName"
    }

    $res = $BranchName
    if (($s.BranchNameLimit -gt 0) -and ($BranchName.Length -gt $s.BranchNameLimit))
    {
        $res = "{0}{1}" -f $BranchName.Substring(0, $s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    $res
}

<#
.SYNOPSIS
    Gets the colors to use for the branch status.
.DESCRIPTION
    Gets the colors to use for the branch status. This color is typically
    used for the branch name as well.  The default color is specified by
    $GitPromptSettins.BranchColor.  But depending on the Git status object
    passed in, the colors could be changed to match that of one these
    other $GitPromptSettings: BranchBehindAndAheadStatusSymbol,
    BranchBehindStatusSymbol or BranchAheadStatusSymbol.
.EXAMPLE
    PS C:\> $branchStatusColor = Get-GitBranchStatusColor (Get-GitStatus)

    Returns a PoshGitTextSpan with the foreground and background colors
    for the branch status.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    PoshGitTextSpan
        A PoshGitTextSpan with colors reflecting those to be used by
        branch status symbols.
#>
function Get-GitBranchStatusColor {
    param(
        # The Git status object that provides branch status information.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status
    )

    $s = $global:GitPromptSettings
    if (!$s) {
        return [PoshGitTextSpan]::new()
    }

    $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchColor)

    if (($Status.BehindBy -ge 1) -and ($Status.AheadBy -ge 1)) {
        # We are both behind and ahead of remote
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchBehindAndAheadStatusSymbol)
    }
    elseif ($Status.BehindBy -ge 1) {
        # We are behind remote
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchBehindStatusSymbol)
    }
    elseif ($Status.AheadBy -ge 1) {
        # We are ahead of remote
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchAheadStatusSymbol)
    }

    $branchStatusTextSpan.Text = ''
    $branchStatusTextSpan
}

<#
.SYNOPSIS
    Writes the branch name given the current Git status.
.DESCRIPTION
    Writes the branch name given the current Git status which can retrieved
    via the Get-GitStatus command. Branch name can be affected by the
    $GitPromptSettings: BranchColor, BranchNameLimit, TruncatedBranchSuffix
    and Branch*StatusSymbol colors.
.EXAMPLE
    PS C:\> Write-GitBranchName (Get-GitStatus)

    Writes the name of the current branch.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitBranchName {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the branch name is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # If specified, suppresses the output of the leading space character.
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    # Use the branch status colors (or CustomAnsi) to display the branch name
    $branchNameTextSpan = Get-GitBranchStatusColor $Status
    $branchNameTextSpan.Text = Format-GitBranchName $Status.Branch
    if (!$NoLeadingSpace) {
        $branchNameTextSpan.Text = " " + $branchNameTextSpan.Text
    }

    if ($StringBuilder) {
        $StringBuilder | Write-Prompt $branchNameTextSpan > $null
    }
    else {
        $str = Write-Prompt $branchNameTextSpan
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

<#
.SYNOPSIS
    Writes the branch status text given the current Git status.
.DESCRIPTION
    Writes the branch status text given the current Git status which can retrieved
    via the Get-GitStatus command. Branch status includes information about the
    upstream branch, how far behind and/or ahead the local branch is from the remote.
.EXAMPLE
    PS C:\> Write-GitBranchStatus (Get-GitStatus)

    Writes the status of the current branch to the host.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitBranchStatus {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the branch status is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # If specified, suppresses the output of the leading space character.
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $branchStatusTextSpan = Get-GitBranchStatusColor $Status

    if (!$Status.Upstream) {
        $branchStatusTextSpan.Text = $s.BranchUntrackedText
    }
    elseif ($Status.UpstreamGone -eq $true) {
        # Upstream branch is gone
        $branchStatusTextSpan.Text = $s.BranchGoneStatusSymbol.Text
    }
    elseif (($Status.BehindBy -eq 0) -and ($Status.AheadBy -eq 0)) {
        # We are aligned with remote
        $branchStatusTextSpan.Text = $s.BranchIdenticalStatusSymbol.Text
    }
    elseif (($Status.BehindBy -ge 1) -and ($Status.AheadBy -ge 1)) {
        # We are both behind and ahead of remote
        if ($s.BranchBehindAndAheadDisplay -eq "Full") {
            $branchStatusTextSpan.Text = ("{0}{1} {2}{3}" -f $s.BranchBehindStatusSymbol.Text, $Status.BehindBy, $s.BranchAheadStatusSymbol.Text, $status.AheadBy)
        }
        elseif ($s.BranchBehindAndAheadDisplay -eq "Compact") {
            $branchStatusTextSpan.Text = ("{0}{1}{2}" -f $Status.BehindBy, $s.BranchBehindAndAheadStatusSymbol.Text, $Status.AheadBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchBehindAndAheadStatusSymbol.Text
        }
    }
    elseif ($Status.BehindBy -ge 1) {
        # We are behind remote
        if (($s.BranchBehindAndAheadDisplay -eq "Full") -Or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
            $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchBehindStatusSymbol.Text, $Status.BehindBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchBehindStatusSymbol.Text
        }
    }
    elseif ($Status.AheadBy -ge 1) {
        # We are ahead of remote
        if (($s.BranchBehindAndAheadDisplay -eq "Full") -or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
            $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchAheadStatusSymbol.Text, $Status.AheadBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchAheadStatusSymbol.Text
        }
    }
    else {
        # This condition should not be possible but defaulting the variables to be safe
        $branchStatusTextSpan.Text = "?"
    }

    $str = ""
    if ($branchStatusTextSpan.Text) {
        $textSpan = [PoshGitTextSpan]::new($branchStatusTextSpan)
        if (!$NoLeadingSpace) {
            $textSpan.Text = " " + $branchStatusTextSpan.Text
        }

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $textSpan > $null
        }
        else {
            $str = Write-Prompt $textSpan
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

<#
.SYNOPSIS
    Writes the index status text given the current Git status.
.DESCRIPTION
    Writes the index status text given the current Git status.
.EXAMPLE
    PS C:\> Write-GitIndexStatus (Get-GitStatus)

    Writes the Git index status to the host.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitIndexStatus {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the index status is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # If specified, suppresses the output of the leading space character.
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.HasIndex) {
        if ($s.ShowStatusWhenZero -or $Status.Index.Added) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileAddedText)$($Status.Index.Added.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($s.ShowStatusWhenZero -or $status.Index.Modified) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileModifiedText)$($status.Index.Modified.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Index.Deleted) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileRemovedText)$($Status.Index.Deleted.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($Status.Index.Unmerged) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileConflictedText)$($Status.Index.Unmerged.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

<#
.SYNOPSIS
    Writes the working directory status text given the current Git status.
.DESCRIPTION
    Writes the working directory status text given the current Git status.
.EXAMPLE
    PS C:\> Write-GitWorkingDirStatus (Get-GitStatus)

    Writes the Git working directory status to the host.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitWorkingDirStatus {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the working dir status is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # If specified, suppresses the output of the leading space character.
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.HasWorking) {
        if ($s.ShowStatusWhenZero -or $Status.Working.Added) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileAddedText)$($Status.Working.Added.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Working.Modified) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileModifiedText)$($Status.Working.Modified.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Working.Deleted) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileRemovedText)$($Status.Working.Deleted.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($Status.Working.Unmerged) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileConflictedText)$($Status.Working.Unmerged.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

<#
.SYNOPSIS
    Writes the working directory status summary text given the current Git status.
.DESCRIPTION
    Writes the working directory status summary text given the current Git status.
    If there are any unstaged commits, the $GitPromptSettings.LocalWorkingStatusSymbol
    will be output.  If not, then if are any staged but uncommmited changes, the
    $GitPromptSettings.LocalStagedStatusSymbol will be output.  If not, then
    $GitPromptSettings.LocalDefaultStatusSymbol will be output.
.EXAMPLE
    PS C:\> Write-GitWorkingDirStatusSummary (Get-GitStatus)

    Outputs the Git working directory status summary text.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitWorkingDirStatusSummary {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the working dir local status is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # If specified, suppresses the output of the leading space character.
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    # No uncommited changes
    $localStatusSymbol = $s.LocalDefaultStatusSymbol

    if ($Status.HasWorking) {
        # We have un-staged files in the working tree
        $localStatusSymbol = $s.LocalWorkingStatusSymbol
    }
    elseif ($Status.HasIndex) {
        # We have staged but uncommited files
        $localStatusSymbol = $s.LocalStagedStatusSymbol
    }

    if ($localStatusSymbol.Text) {
        $textSpan = [PoshGitTextSpan]::new($localStatusSymbol)
        if (!$NoLeadingSpace) {
            $textSpan.Text = " " + $localStatusSymbol.Text
        }

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $textSpan > $null
        }
        else {
            $str += Write-Prompt $textSpan
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

<#
.SYNOPSIS
    Writes the stash count given the current Git status.
.DESCRIPTION
    Writes the stash count given the current Git status.
.EXAMPLE
    PS C:\> Write-GitStashCount (Get-GitStatus)

    Writes the Git stash count to the host.
.INPUTS
    System.Management.Automation.PSCustomObject
        This is PSCustomObject returned by Get-GitStatus
.OUTPUTS
    System.String, System.Text.StringBuilder
        This command returns a System.String object unless the -StringBuilder parameter
        is supplied. In this case, it returns a System.Text.StringBuilder.
#>
function Write-GitStashCount {
    param(
        # The Git status object that provides the status information to be written.
        # This object is retrieved via the Get-GitStatus command.
        [Parameter(Position = 0)]
        $Status,

        # If specified the working dir local status is written into the provided StringBuilder object.
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.StashCount -gt 0) {
        $stashText = "$($Status.StashCount)"

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $s.BeforeStash > $null
            $StringBuilder | Write-Prompt $stashText -Color $s.StashColor > $null
            $StringBuilder | Write-Prompt $s.AfterStash > $null
        }
        else {
            $str += Write-Prompt $s.BeforeStash
            $str += Write-Prompt $stashText -Color $s.StashColor
            $str += Write-Prompt $s.AfterStash
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

if (!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $global:VcsPromptStatuses = @()
}

<#
.SYNOPSIS
    Writes all version control prompt statuses configured in $global:VscPromptStatuses.
.DESCRIPTION
    Writes all version control prompt statuses configured in $global:VscPromptStatuses.
    By default, this includes the PoshGit prompt status.
.EXAMPLE
    PS C:\> Write-VcsStatus

    Writes all version control prompt statuses that have been configured
    with the global variable $VscPromptStatuses
#>
function Global:Write-VcsStatus {
    Set-ConsoleMode -ANSI

    $OFS = ""
    $sb = [System.Text.StringBuilder]::new(256)

    foreach ($promptStatus in $global:VcsPromptStatuses) {
        [void]$sb.Append("$(& $promptStatus)")
    }

    if ($sb.Length -gt 0) {
        $sb.ToString()
    }
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
            $errorText = "PoshGitVcsPrompt error: $_"
            $sb = [System.Text.StringBuilder]::new()

            # When prompt is first (default), place the separator before the status summary
            if (!$s.DefaultPromptWriteStatusFirst) {
                $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
            }
            $sb | Write-Prompt $s.BeforeStatus > $null

            $sb | Write-Prompt $errorText -Color $s.ErrorColor > $null
            if ($s.Debug) {
                if (!$s.AnsiConsole) { Write-Host }
                Write-Verbose "PoshGitVcsPrompt error details: $($_ | Format-List * -Force | Out-String)" -Verbose
            }
            $sb | Write-Prompt $s.AfterStatus > $null

            if ($sb.Length -gt 0) {
                $sb.ToString()
            }
        }
    }
}

$global:VcsPromptStatuses += $PoshGitVcsPrompt
