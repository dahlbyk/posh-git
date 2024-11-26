# For backwards compatibility
$global:HgPromptSettings = $global:PoshHgSettings

function Write-HgStatus($status = (get-hgStatus $global:PoshHgSettings.GetFileStatus $global:PoshHgSettings.GetBookmarkStatus)) {
    if ($status) {
        $s = $global:PoshHgSettings
        $sb = [System.Text.StringBuilder]::new()

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

        $sb | Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        $sb | Write-Prompt $status.Branch -BackgroundColor $branchBg -ForegroundColor $branchFg

        if($status.Added) {
            $sb | Write-Prompt "$($s.AddedStatusPrefix)$($status.Added)" -BackgroundColor $s.AddedBackgroundColor -ForegroundColor $s.AddedForegroundColor
        }
        if($status.Modified) {
            $sb | Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Modified)" -BackgroundColor $s.ModifiedBackgroundColor -ForegroundColor $s.ModifiedForegroundColor
        }
        if($status.Deleted) {
            $sb | Write-Prompt "$($s.DeletedStatusPrefix)$($status.Deleted)" -BackgroundColor $s.DeletedBackgroundColor -ForegroundColor $s.DeletedForegroundColor
        }

        if ($status.Untracked) {
            $sb | Write-Prompt "$($s.UntrackedStatusPrefix)$($status.Untracked)" -BackgroundColor $s.UntrackedBackgroundColor -ForegroundColor $s.UntrackedForegroundColor
        }

        if($status.Missing) {
            $sb | Write-Prompt "$($s.MissingStatusPrefix)$($status.Missing)" -BackgroundColor $s.MissingBackgroundColor -ForegroundColor $s.MissingForegroundColor
        }

        if($status.Renamed) {
            $sb | Write-Prompt "$($s.RenamedStatusPrefix)$($status.Renamed)" -BackgroundColor $s.RenamedBackgroundColor -ForegroundColor $s.RenamedForegroundColor
        }

        if($s.ShowTags -and ($status.Tags.Length -or $status.ActiveBookmark.Length)) {
            $sb | Write-Prompt $s.BeforeTagText -NoNewLine

            if($status.ActiveBookmark.Length) {
                $sb | Write-Prompt $status.ActiveBookmark -ForegroundColor $s.BranchForegroundColor -BackgroundColor $s.TagBackgroundColor
                if($status.Tags.Length) {
                    $sb | Write-Prompt " " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
                }
            }

            $tagCounter=0
            $status.Tags | % {
                $color = $s.TagForegroundColor

                $sb | Write-Prompt $_ -ForegroundColor $color -BackgroundColor $s.TagBackgroundColor

                if($tagCounter -lt ($status.Tags.Length -1)) {
                    $sb | Write-Prompt ", " -ForegroundColor $s.TagSeparatorColor -BackgroundColor $s.TagBackgroundColor
                }
                $tagCounter++;
            }
        }

        if($s.ShowPatches) {
            $patches = Get-MqPatches
            if($patches.All.Length) {
                $sb | Write-Prompt $s.BeforePatchText -NoNewLine

                $patchCounter = 0

                $patches.Applied | % {
                    $sb | Write-Prompt $_ -ForegroundColor $s.AppliedPatchForegroundColor -BackgroundColor $s.AppliedPatchBackgroundColor
                    if($patchCounter -lt ($patches.All.Length -1)) {
                        $sb | Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
                    }
                    $patchCounter++;
                }

                $patches.Unapplied | % {
                    $sb | Write-Prompt $_ -ForegroundColor $s.UnappliedPatchForegroundColor -BackgroundColor $s.UnappliedPatchBackgroundColor
                    if($patchCounter -lt ($patches.All.Length -1)) {
                        $sb | Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
                    }
                    $patchCounter++;
                }
            }
        }

        if($s.ShowRevision -and $status.Revision) {
            $sb | Write-Prompt " <" -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
            $sb | Write-Prompt $status.Revision -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
            $sb | Write-Prompt ">" -BackgroundColor $s.TagBackgroundColor -ForegroundColor $s.TagForegroundColor
        }


        $sb | Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        $sb.ToString()
    }
}

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    Write-HgStatus
}
