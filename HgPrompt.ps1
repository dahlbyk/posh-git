$global:HgPromptSettings = New-Object PSObject -Property @{
    BeforeText                = ' ['
    BeforeForegroundColor     = [ConsoleColor]::Yellow
    BeforeBackgroundColor     = $Host.UI.RawUI.BackgroundColor
    
    AfterText                 = ']'
    AfterForegroundColor      = [ConsoleColor]::Yellow
    AfterBackgroundColor      = $Host.UI.RawUI.BackgroundColor
    
    BranchForegroundColor    = [ConsoleColor]::Cyan
    BranchBackgroundColor    = $Host.UI.RawUI.BackgroundColor
    Branch2ForegroundColor   = [ConsoleColor]::Red
    Branch2BackgroundColor   = $host.UI.RawUI.BackgroundColor
    
    WorkingForegroundColor    = [ConsoleColor]::Yellow
    WorkingBackgroundColor    = $Host.UI.RawUI.BackgroundColor
    
    ShowTags                  = $true
    BeforeTagText             = ' '
    TagForegroundColor        = [ConsoleColor]::DarkGray
    TagBackgroundColor        = $Host.UI.RawUI.BackgroundColor
    TagSeparator              = ", "
    TagSeparatorColor         = [ConsoleColor]::White
    
    ShowPatches                   = $true
    BeforePatchText               = ' patches: '
    UnappliedPatchForegroundColor = [ConsoleColor]::DarkGray
    UnappliedPatchBackgroundColor = $Host.UI.RawUI.BackgroundColor
    AppliedPatchForegroundColor   = [ConsoleColor]::DarkYellow
    AppliedPatchBackgroundColor   = $Host.UI.RawUI.BackgroundColor
    PatchSeparator                = ' › '
    PatchSeparatorColor           = [ConsoleColor]::White
    
    
    
}

function Write-HgStatus($status = (get-hgStatus)) {
    if ($status) {
        $s = $global:HgPromptSettings
       
        $branchFg = $s.BranchForegroundColor
        $branchBg = $s.BranchBackgroundColor
        
        if($status.Behind) {
          $branchFg = $s.Branch2ForegroundColor
          $branchBg = $s.Branch2BackgroundColor
        }
       
        Write-Host $s.BeforeText -NoNewline -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Host $status.Branch -NoNewline -BackgroundColor $branchBg -ForegroundColor $branchFg
        
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

        if($s.ShowTags -and $status.Tags.Length) {
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
        
        if($s.ShowPatches) {
          $patches = Get-MqPatches
          if($patches.All.Length) {
            write-host $s.BeforePatchText -NoNewLine
  
            $patchCounter = 0
            
            $patches.Applied | % {
              write-host $_ -NoNewLine -ForegroundColor $s.AppliedPatchForegroundColor -BackgroundColor $s.AppliedPatchBackgroundColor
              if($patchCounter -lt ($patches.All.Length -1)) {
                write-host $s.PatchSeparator -NoNewLine -ForegroundColor $s.PatchSeparatorColor
              }
              $patchCounter++;
            }
            
            $patches.Unapplied | % {
               write-host $_ -NoNewLine -ForegroundColor $s.UnappliedPatchForegroundColor -BackgroundColor $s.UnappliedPatchBackgroundColor
               if($patchCounter -lt ($patches.All.Length -1)) {
                  write-host $s.PatchSeparator -NoNewLine -ForegroundColor $s.PatchSeparatorColor
               }
               $patchCounter++;
            }
          }
        }
        
       Write-Host $s.AfterText -NoNewline -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}