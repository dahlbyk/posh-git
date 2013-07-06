# For backwards compatibility
$global:HgPromptSettings = $global:PoshHgSettings

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-HgStatus($status = (get-hgStatus $global:PoshHgSettings.GetFileStatus $global:PoshHgSettings.GetBookmarkStatus)) {
    if ($status) {
        $s = $global:PoshHgSettings
       
        $branchFg = $s.BranchForegroundColor
        $branchBg = $s.BranchBackgroundColor
        
        if($status.Behind) {
          $branchFg = $s.Branch2ForegroundColor
          $branchBg = $s.Branch2BackgroundColor
        }

        if ($status.MultipleHeads) {
          $branchFg = $s.Branch3ForegroundColor
          $branchBg = $s.Branch3BackgroundColor
        }
       
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Prompt $status.Branch -BackgroundColor $branchBg -ForegroundColor $branchFg
        
        if($status.Added) {
          Write-Prompt "$($s.AddedStatusPrefix)$($status.Added)" -BackgroundColor $s.AddedBackgroundColor -ForegroundColor $s.AddedForegroundColor
        }
        if($status.Modified) {
          Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Modified)" -BackgroundColor $s.ModifiedBackgroundColor -ForegroundColor $s.ModifiedForegroundColor
        }
        if($status.Deleted) {
          Write-Prompt "$($s.DeletedStatusPrefix)$($status.Deleted)" -BackgroundColor $s.DeletedBackgroundColor -ForegroundColor $s.DeletedForegroundColor
        }
        
        if ($status.Untracked) {
          Write-Prompt "$($s.UntrackedStatusPrefix)$($status.Untracked)" -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }
        
        if($status.Missing) {
           Write-Prompt "$($s.MissingStatusPrefix)$($status.Missing)" -BackgroundColor $s.MissingBackgroundColor -ForegroundColor $s.MissingForegroundColor
        }

        if($status.Renamed) {
           Write-Prompt "$($s.RenamedStatusPrefix)$($status.Renamed)" -BackgroundColor $s.RenamedBackgroundColor -ForegroundColor $s.RenamedForegroundColor
        }

        if($s.ShowTags -and ($status.Tags.Length -or $status.ActiveBookmark.Length)) {
          write-host $s.BeforeTagText -NoNewLine
            
          if($status.ActiveBookmark.Length) {
              Write-Prompt $status.ActiveBookmark -ForegroundColor $s.BranchForegroundColor -BackgroundColor $s.TagBackgroundColor 
              if($status.Tags.Length) {
                Write-Prompt " " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
              }
          }
         
          $tagCounter=0
          $status.Tags | % {
            $color = $s.TagForegroundColor
                
              Write-Prompt $_ -ForegroundColor $color -BackgroundColor $s.TagBackgroundColor 
          
              if($tagCounter -lt ($status.Tags.Length -1)) {
                Write-Prompt ", " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
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
              Write-Prompt $_ -ForegroundColor $s.AppliedPatchForegroundColor -BackgroundColor $s.AppliedPatchBackgroundColor
              if($patchCounter -lt ($patches.All.Length -1)) {
                Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
              }
              $patchCounter++;
            }
            
            $patches.Unapplied | % {
               Write-Prompt $_ -ForegroundColor $s.UnappliedPatchForegroundColor -BackgroundColor $s.UnappliedPatchBackgroundColor
               if($patchCounter -lt ($patches.All.Length -1)) {
                  Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
               }
               $patchCounter++;
            }
          }
        }
        
       Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}

# Should match https://github.com/dahlbyk/posh-git/blob/master/GitPrompt.ps1
if((Get-Variable -Scope Global -Name VcsPromptStatuses -ErrorAction SilentlyContinue) -eq $null) {
    $Global:VcsPromptStatuses = @()
}
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    Write-HgStatus
}
