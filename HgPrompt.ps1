# For backwards compatibility
$global:HgPromptSettings = $global:PoshHgSettings

function Write-HgStatus($status = (get-hgStatus)) {
    if ($status) {
        $s = $global:PoshHgSettings
       
        $branchFg = $s.BranchForegroundColor
        $branchBg = $s.BranchBackgroundColor
        
        if($status.Behind) {
          $branchFg = $s.Branch2ForegroundColor
          $branchBg = $s.Branch2BackgroundColor
        }
       
        Write-Host $s.BeforeText -NoNewline -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Host $status.Branch -NoNewline -BackgroundColor $branchBg -ForegroundColor $branchFg
        
        if($status.Added) {
          Write-Host " +$($status.Added)" -NoNewline -BackgroundColor $s.AddedBackgroundColor -ForegroundColor $s.AddedForegroundColor
        }
        if($status.Modified) {
          Write-Host " ~$($status.Modified)" -NoNewline -BackgroundColor $s.ModifiedBackgroundColor -ForegroundColor $s.ModifiedForegroundColor
        }
        if($status.Deleted) {
          Write-Host " -$($status.Deleted)" -NoNewline -BackgroundColor $s.DeletedBackgroundColor -ForegroundColor $s.DeletedForegroundColor
        }
        
        if ($status.Untracked) {
          Write-Host " ?$($status.Untracked)" -NoNewline -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }
        
        if($status.Missing) {
           Write-Host " !$($status.Missing)" -NoNewline -BackgroundColor $s.MissingBackgroundColor -ForegroundColor $s.MissingForegroundColor
        }

        if($status.Renamed) {
           Write-Host " ^$($status.Renamed)" -NoNewline -BackgroundColor $s.RenamedBackgroundColor -ForegroundColor $s.RenamedForegroundColor
        }

        if($s.ShowTags -and ($status.Tags.Length -or $status.ActiveBookmark.Length)) {
          write-host $s.BeforeTagText -NoNewLine
            
          if($status.ActiveBookmark.Length) {
              write-host $status.ActiveBookmark -NoNewLine -ForegroundColor $s.BranchForegroundColor -BackgroundColor $s.TagBackgroundColor 
              if($status.Tags.Length) {
                write-host " " -NoNewLine -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
              }
          }
         
          $tagCounter=0
          $status.Tags | % {
            $color = $s.TagForegroundColor
                
              write-host $_ -NoNewLine -ForegroundColor $color -BackgroundColor $s.TagBackgroundColor 
          
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

# Should match https://github.com/dahlbyk/posh-git/blob/master/GitPrompt.ps1
if (!$Global:VcsPromptStatuses) { $Global:VcsPromptStatuses = @() }
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    $Global:HgStatus = Get-HgStatus
    Write-HgStatus $HgStatus
}
