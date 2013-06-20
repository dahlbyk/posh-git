function Write-GitStatusPromptAsync([string]$gitDir = (Get-GitDirectory)) {
    $processStartInfo = New-Object Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = "git"
    $processStartInfo.Arguments = "-c color.status=false status --short --branch"
    $processStartInfo.CreateNoWindow = $true
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.RedirectStandardError = $false
    $processStartInfo.UseShellExecute = $false
    $processStartInfo.WorkingDirectory = $pwd

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $processStartInfo
    
    $processOutputLines = @()
    $positionToWriteStatus = $Host.UI.RawUI.CursorPosition
    
    # Output a placeholder line where the status will be written to.  This makes sure the status line doesn't overwrite the actual prompt
    Write-Host " [...processing...]" 

    $messageData = new-object psobject -property @{
        gitDir = $gitDir
        processOutputLines = $processOutputLines
        positionToWriteStatus = $positionToWriteStatus
    }
    
    Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -MessageData $messageData -action {
        $event.MessageData.processOutputLines += $EventArgs.data
    } | Out-Null
    Register-ObjectEvent -InputObject $process -EventName Exited -MessageData $messageData -action {
        $gitStatusObject = Convert-GitStatusOutput $event.MessageData.processOutputLines $event.MessageData.gitDir
        
        # to maintain behavior compatibility with synchronous prompt, set the global GitStatus variable
        $global:GitStatus = $gitStatusObject
        
        $bufferCells = Get-GitStatusBufferCells $gitStatusObject
        Write-BufferCellsToPosition $bufferCells $event.MessageData.positionToWriteStatus
    } | Out-Null

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
}

function New-BufferCells([string] $content, [consolecolor] $ForegroundColor, [consolecolor] $BackgroundColor) {
    if ($content) {
        $Host.UI.RawUI.NewBufferCellArray($content, $ForegroundColor, $BackgroundColor)
    }
}

function Write-BufferCellsToPosition([System.Management.Automation.Host.BufferCell[]] $bufferCells, [System.Management.Automation.Host.Coordinates] $position) {
    # SetBufferContents needs the cells as a 2-dimensional array (not a jagged array), so we have to create one
    $bufferCells2d = new-object 'System.Management.Automation.Host.BufferCell[,]' 1, $bufferCells.Length
    foreach ($index in 0 .. $($bufferCells.Length - 1)) {
        $bufferCells2d[0,$index] = $bufferCells[$index]
    }
    
    $host.UI.RawUI.SetBufferContents($position, $bufferCells2d)
}

function Get-GitStatusBufferCells([psobject] $status) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        # initial set of buffer cells set here, so don't use +=
        #[System.Management.Automation.Host.BufferCell[,]] 
        $bufferCells = New-BufferCells $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor

        $branchBackgroundColor = $s.BranchBackgroundColor
        $branchForegroundColor = $s.BranchForegroundColor
        if ($status.BehindBy -gt 0 -and $status.AheadBy -gt 0) {
            # We are behind and ahead of remote
            $branchBackgroundColor = $s.BranchBehindAndAheadBackgroundColor
            $branchForegroundColor = $s.BranchBehindAndAheadForegroundColor
        } elseif ($status.BehindBy -gt 0) {
            # We are behind remote
            $branchBackgroundColor = $s.BranchBehindBackgroundColor
            $branchForegroundColor = $s.BranchBehindForegroundColor
        } elseif ($status.AheadBy -gt 0) {
            # We are ahead of remote
            $branchBackgroundColor = $s.BranchAheadBackgroundColor
            $branchForegroundColor = $s.BranchAheadForegroundColor
        }

        $bufferCells += New-BufferCells $status.Branch -BackgroundColor $branchBackgroundColor -ForegroundColor $branchForegroundColor

        if($s.EnableFileStatus -and $status.HasIndex) {
            $bufferCells += New-BufferCells $s.BeforeIndexText -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor

            if($s.ShowStatusWhenZero -or $status.Index.Added) {
              $bufferCells += New-BufferCells " +$($status.Index.Added.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
              $bufferCells += New-BufferCells " ~$($status.Index.Modified.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
              $bufferCells += New-BufferCells " -$($status.Index.Deleted.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                $bufferCells += New-BufferCells " !$($status.Index.Unmerged.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                $bufferCells += New-BufferCells $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
              $bufferCells += New-BufferCells " +$($status.Working.Added.Count)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
              $bufferCells += New-BufferCells " ~$($status.Working.Modified.Count)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
              $bufferCells += New-BufferCells " -$($status.Working.Deleted.Count)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Working.Unmerged) {
                $bufferCells += New-BufferCells " !$($status.Working.Unmerged.Count)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
        }

        if ($status.HasUntracked) {
            $bufferCells += New-BufferCells $s.UntrackedText -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }

        $bufferCells += New-BufferCells $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
        
        # return full set of cells back to caller
        $bufferCells
    }
}

function ShouldRunAsyncGitStatus {
    $shouldRunAsync =
        $Global:GitPromptSettings -and
        $Global:GitPromptSettings.EnablePromptStatus -and
        $Global:GitPromptSettings.EnableFileStatus -and
        $Global:GitPromptSettings.EnableAsyncFileStatus -and
        (Get-GitDirectory) -and
        -not $(InDisabledRepository)
        
    return $shouldRunAsync
}

function Convert-GitStatusOutput([string[]] $status, [string]$gitDir) {
    $branch = $null
    $aheadBy = 0
    $behindBy = 0
    $indexAdded = @()
    $indexModified = @()
    $indexDeleted = @()
    $indexUnmerged = @()
    $filesAdded = @()
    $filesModified = @()
    $filesDeleted = @()
    $filesUnmerged = @()

    $status | foreach {
        if($_) {
            switch -regex ($_) {
                '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {
                    switch ($matches['index']) {
                        'A' { $indexAdded += $matches['path1'] }
                        'M' { $indexModified += $matches['path1'] }
                        'R' { $indexModified += $matches['path1'] }
                        'C' { $indexModified += $matches['path1'] }
                        'D' { $indexDeleted += $matches['path1'] }
                        'U' { $indexUnmerged += $matches['path1'] }
                    }
                    switch ($matches['working']) {
                        '?' { $filesAdded += $matches['path1'] }
                        'A' { $filesAdded += $matches['path1'] }
                        'M' { $filesModified += $matches['path1'] }
                        'D' { $filesDeleted += $matches['path1'] }
                        'U' { $filesUnmerged += $matches['path1'] }
                    }
                }

                '^## (?<branch>\S+)(?:\.\.\.(?<upstream>\S+) \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?\])?$' {
                    $branch = $matches['branch']
                    $upstream = $matches['upstream']
                    $aheadBy = [int]$matches['ahead']
                    $behindBy = [int]$matches['behind']
                }

                '^## Initial commit on (?<branch>\S+)$' {
                    $branch = $matches['branch']
                }
            }
        }
    }

    if(!$branch) { $branch = Get-GitBranch $gitDir $sw }
    $indexPaths = $indexAdded + $indexModified + $indexDeleted + $indexUnmerged
    $workingPaths = $filesAdded + $filesModified + $filesDeleted + $filesUnmerged
    $index = New-Object PSObject @(,@($indexPaths | ?{ $_ } | Select -Unique)) |
        Add-Member -PassThru NoteProperty Added    $indexAdded |
        Add-Member -PassThru NoteProperty Modified $indexModified |
        Add-Member -PassThru NoteProperty Deleted  $indexDeleted |
        Add-Member -PassThru NoteProperty Unmerged $indexUnmerged
    $working = New-Object PSObject @(,@($workingPaths | ?{ $_ } | Select -Unique)) |
        Add-Member -PassThru NoteProperty Added    $filesAdded |
        Add-Member -PassThru NoteProperty Modified $filesModified |
        Add-Member -PassThru NoteProperty Deleted  $filesDeleted |
        Add-Member -PassThru NoteProperty Unmerged $filesUnmerged

    $gitStatusObject = New-Object PSObject -Property @{
        GitDir          = $gitDir
        Branch          = $branch
        AheadBy         = $aheadBy
        BehindBy        = $behindBy
        HasIndex        = [bool]$index
        Index           = $index
        HasWorking      = [bool]$working
        Working         = $working
        HasUntracked    = [bool]$filesAdded
    }

    return $gitStatusObject
}
