# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

$enableFileStatus = $false

$global:GitPromptSettings = New-Object PSObject -Property @{
    DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor

    BeforeText                = if ($enableFileStatus) {' ['} else {' '}
    BeforeForegroundColor     = [ConsoleColor]::DarkGray
    BeforeBackgroundColor     = $Host.UI.RawUI.BackgroundColor    
    DelimText                 = ' |'
    DelimForegroundColor      = [ConsoleColor]::DarkGray
    DelimBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    AfterText                 = if ($enableFileStatus) {']'} else {''}
    AfterForegroundColor      = [ConsoleColor]::DarkGray
    AfterBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    BranchForegroundColor       = [ConsoleColor]::DarkGray
    BranchBackgroundColor       = $Host.UI.RawUI.BackgroundColor
    BranchAheadForegroundColor  = [ConsoleColor]::DarkGreen
    BranchAheadBackgroundColor  = $Host.UI.RawUI.BackgroundColor
    BranchBehindForegroundColor  = [ConsoleColor]::DarkRed
    BranchBehindBackgroundColor  = $Host.UI.RawUI.BackgroundColor
    
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
    EnableFileStatus          = $enableFileStatus
    RepositoriesInWhichToDisableFileStatus = @( ) # Array of repository paths

    Debug                     = $false
}

function Write-GitStatus($status) {
    $s = $global:GitPromptSettings
    if ($status -and $s) {
        $currentBranch = $status.Branch
        
        Write-Host $s.BeforeText -NoNewline -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        if ($status.BehindBy -gt 0) {
            # We are behind remote
            Write-Host $currentBranch -NoNewline -BackgroundColor $s.BranchBehindBackgroundColor -ForegroundColor $s.BranchBehindForegroundColor
        } elseif ($status.AheadBy -gt 0) {
            # We are ahead of remote
            Write-Host $currentBranch -NoNewline -BackgroundColor $s.BranchAheadBackgroundColor -ForegroundColor $s.BranchAheadForegroundColor
        } else {
            # We are not ahead of origin
            Write-Host $currentBranch -NoNewline -BackgroundColor $s.BranchBackgroundColor -ForegroundColor $s.BranchForegroundColor
        }
        
        if ($status.BehindBy -eq 0 -and $status.AheadBy -gt 0) {
            Write-Host ' >>' -NoNewLine -ForeGroundColor White
        }
        
        if($s.EnableFileStatus -and $status.HasIndex) {
            write-host $s.BeforeIndexText -NoNewLine -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor
            
            if($s.ShowStatusWhenZero -or $status.Index.Added) {
              Write-Host " +$($status.Index.Added.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
              Write-Host " ~$($status.Index.Modified.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
              Write-Host " -$($status.Index.Deleted.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                Write-Host " !$($status.Index.Unmerged.Count)" -NoNewline -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                Write-Host $s.DelimText -NoNewline -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }
        
        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
              Write-Host " +$($status.Working.Added.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
              Write-Host " ~$($status.Working.Modified.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
              Write-Host " -$($status.Working.Deleted.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Working.Unmerged) {
                Write-Host " !$($status.Working.Unmerged.Count)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
        }
        
        if ($status.HasUntracked) {
            Write-Host $s.UntrackedText -NoNewline -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }
        
        Write-Host $s.AfterText -NoNewline -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}
