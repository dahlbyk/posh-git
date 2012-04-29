# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$global:GitPromptSettings = New-Object PSObject -Property @{
    DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor

    BeforeText                = ' ['
    BeforeForegroundColor     = [ConsoleColor]::Yellow
    BeforeBackgroundColor     = $Host.UI.RawUI.BackgroundColor    
    DelimText                 = ' |'
    DelimForegroundColor      = [ConsoleColor]::Yellow
    DelimBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    AfterText                 = ']'
    AfterForegroundColor      = [ConsoleColor]::Yellow
    AfterBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    BranchForegroundColor       = [ConsoleColor]::Cyan
    BranchBackgroundColor       = $Host.UI.RawUI.BackgroundColor
    BranchAheadForegroundColor  = [ConsoleColor]::Green
    BranchAheadBackgroundColor  = $Host.UI.RawUI.BackgroundColor
    BranchBehindForegroundColor = [ConsoleColor]::Red
    BranchBehindBackgroundColor = $Host.UI.RawUI.BackgroundColor
    BranchBehindAndAheadForegroundColor = [ConsoleColor]::Yellow
    BranchBehindAndAheadBackgroundColor = $Host.UI.RawUI.BackgroundColor
    
    BeforeIndexText           = ""
    BeforeIndexForegroundColor= [ConsoleColor]::DarkGreen
    BeforeIndexBackgroundColor= $Host.UI.RawUI.BackgroundColor
    
    IndexForegroundColor      = [ConsoleColor]::DarkGreen
    IndexBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    WorkingForegroundColor    = [ConsoleColor]::DarkRed
    WorkingBackgroundColor    = $Host.UI.RawUI.BackgroundColor
    
    UntrackedText             = ' !'
    UntrackedForegroundColor  = [ConsoleColor]::DarkRed
    UntrackedBackgroundColor  = $Host.UI.RawUI.BackgroundColor
    
    ShowStatusWhenZero        = $true
    
    AutoRefreshIndex          = $true

    EnablePromptStatus        = !$GitMissing
    EnableFileStatus          = $true
    RepositoriesInWhichToDisableFileStatus = @( ) # Array of repository paths

    Debug                     = $false
}

function Write-Prompt($Object, [switch]$NoNewline, $ForegroundColor, $BackgroundColor) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewline:$NoNewline -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewline:$NoNewline -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        $currentBranch = $status.Branch
        
        Write-Prompt $s.BeforeText -NoNewline -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        if ($status.BehindBy -gt 0 -and $status.AheadBy -gt 0) {
            # We are behind and ahead of remote
            Write-Prompt $currentBranch -NoNewline -BackgroundColor $s.BranchBehindAndAheadBackgroundColor -ForegroundColor $s.BranchBehindAndAheadForegroundColor
        } elseif ($status.BehindBy -gt 0) {
            # We are behind remote
            Write-Prompt $currentBranch -NoNewline -BackgroundColor $s.BranchBehindBackgroundColor -ForegroundColor $s.BranchBehindForegroundColor
        } elseif ($status.AheadBy -gt 0) {
            # We are ahead of remote
            Write-Prompt $currentBranch -NoNewline -BackgroundColor $s.BranchAheadBackgroundColor -ForegroundColor $s.BranchAheadForegroundColor
        } else {
            # We are not ahead of origin
            Write-Prompt $currentBranch -NoNewline -BackgroundColor $s.BranchBackgroundColor -ForegroundColor $s.BranchForegroundColor
        }
        
        if($s.EnableFileStatus -and $status.HasIndex) {
            Write-Prompt $s.BeforeIndexText -NoNewLine -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor
            
            if($s.ShowStatusWhenZero -or $status.Index.Added) {
              Write-Prompt " +$($status.Index.Added.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
              Write-Prompt " ~$($status.Index.Modified.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
              Write-Prompt " -$($status.Index.Deleted.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                Write-Prompt " !$($status.Index.Unmerged.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                Write-Prompt $s.DelimText -NoNewline -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }
        
        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
              Write-Prompt " +$($status.Working.Added.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
              Write-Prompt " ~$($status.Working.Modified.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
              Write-Prompt " -$($status.Working.Deleted.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Working.Unmerged) {
                Write-Prompt " !$($status.Working.Unmerged.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
        }
        
        if ($status.HasUntracked) {
            Write-Prompt $s.UntrackedText -NoNewline -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }
        
        Write-Prompt $s.AfterText -NoNewline -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}

if (!$Global:VcsPromptStatuses) { $Global:VcsPromptStatuses = @() }
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}
