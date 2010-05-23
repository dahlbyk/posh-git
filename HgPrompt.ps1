$global:HgPromptSettings = New-Object PSObject -Property @{
    BeforeText                = ' ['
    BeforeForegroundColor     = [ConsoleColor]::Yellow
    BeforeBackgroundColor     = $Host.UI.RawUI.BackgroundColor
    
    AfterText                 = ']'
    AfterForegroundColor      = [ConsoleColor]::Yellow
    AfterBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    BranchForegroundColor    = [ConsoleColor]::Cyan
    BranchBackgroundColor    = $Host.UI.RawUI.BackgroundColor
    
    WorkingForegroundColor    = [ConsoleColor]::Yellow
    WorkingBackgroundColor    = $Host.UI.RawUI.BackgroundColor
    
    ShowTags                  = $true
    BeforeTagText             = ' '
    TagForegroundColor        = [ConsoleColor]::DarkGray
    TagBackgroundColor        = $Host.UI.RawUI.BackgroundColor
    TagSeparator              = ", "
    TagSeparatorColor         = [ConsoleColor]::White
}

function Write-HgStatus($status = (get-hgStatus)) {
    if ($status) {
        $s = $global:HgPromptSettings
       
        Write-Host $s.BeforeText -NoNewline -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Host $status.Branch -NoNewline -BackgroundColor $s.BranchBackgroundColor -ForegroundColor $s.BranchForegroundColor
        
        if($status.Added) {
          Write-Host " +$($status.Added)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
        }
        if($status.Modified) {
          Write-Host " ~$($status.Modified)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
        }
        if($status.Deleted) {
          Write-Host " -$($status.Deleted)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
        }
        
        if ($status.Untracked) {
          Write-Host " ?$($status.Untracked)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
        }
        
        if($status.Missing) {
           Write-Host " !$($status.Missing)" -NoNewline -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
        }
        
        if($s.ShowTags) {
          write-host $s.BeforeTagText -NoNewLine
          
          $tagCounter=0
          $status.Tags | % {
              write-host $_ -NoNewLine -ForegroundColor $s.TagForegroundColor -BackgroundColor $s.TagBackgroundColor 
              if($tagCounter -lt ($status.Tags.Length -1)) {
                write-host ", " -NoNewLine -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
              }
              $tagCounter++;
          }        
        }
        
       Write-Host $s.AfterText -NoNewline -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}