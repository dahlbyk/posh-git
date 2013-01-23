function isHgDirectory() {
  if(test-path ".git") {
    return $false; #short circuit if git repo
  }
  
  if(test-path ".hg") {
    return $true;
  }
  
  
  
  # Test within parent dirs
  $checkIn = (Get-Item .).parent
  while ($checkIn -ne $NULL) {
      $pathToTest = $checkIn.fullname + '/.hg'
      if ((Test-Path $pathToTest) -eq $TRUE) {
          return $true
      } else {
          $checkIn = $checkIn.parent
      }
    }
    
    return $false
}

function Get-HgStatus($getFileStatus=$true, $getBookmarkStatus=$true) {
  if(isHgDirectory) {
    $untracked = 0
    $added = 0
    $modified = 0
    $deleted = 0
    $missing = 0
	$renamed = 0
    $tags = @()
    $commit = ""
    $behind = $false
    $multipleHeads = $false
		
	if ($getFileStatus -eq $false) {
		hg parent | foreach {
		switch -regex ($_) {
			'tag:\s*(.*)' { $tags = $matches[1].Replace("(empty repository)", "").Split(" ", [StringSplitOptions]::RemoveEmptyEntries) }
			'changeset:\s*(\S*)' { $commit = $matches[1]}
			}
		}
		$branch = hg branch
		$behind = $true
		$headCount = 0
		hg heads $branch | foreach {
			switch -regex ($_) {
				'changeset:\s*(\S*)' 
				{ 
					if ($commit -eq $matches[1]) { $behind=$false }
					$headCount++
					if ($headCount -gt 1) { $multipleHeads=$true }
				}
			}
		}
	}
	else
	{
		   hg summary | foreach {   
		  switch -regex ($_) {
			'parent: (\S*) ?(.*)' { $commit = $matches[1]; $tags = $matches[2].Replace("(empty repository)", "").Split(" ", [StringSplitOptions]::RemoveEmptyEntries) } 
			'branch: ([\S ]*)' { $branch = $matches[1] }
			'update: (\d+)' { $behind = $true }
			'pmerge: (\d+) pending' { $behind = $true }
			'commit: (.*)' {
			  $matches[1].Split(",") | foreach {
				switch -regex ($_.Trim()) {
				  '(\d+) modified' { $modified = $matches[1] }
				  '(\d+) added' { $added = $matches[1] }
				  '(\d+) removed' { $deleted = $matches[1] }
				  '(\d+) deleted' { $missing = $matches[1] }
				  '(\d+) unknown' { $untracked = $matches[1] }
				  '(\d+) renamed' { $renamed = $matches[1] }
				}
			  } 
			} 
		  } 
		}
	}
    
    
	if ($getBookmarkStatus)
	{
		$active = ""
		hg bookmarks | ?{$_}  | foreach {
			if($_.Trim().StartsWith("*")) {
			   $split = $_.Split(" ");
			   $active= $split[2]
			}
		}
	}
    return @{"Untracked" = $untracked;
               "Added" = $added;
               "Modified" = $modified;
               "Deleted" = $deleted;
               "Missing" = $missing;
			   "Renamed" = $renamed;
               "Tags" = $tags;
               "Commit" = $commit;
               "Behind" = $behind;
               "MultipleHeads" = $multipleHeads;
               "ActiveBookmark" = $active;
               "Branch" = $branch}
   }
}

function Get-MqPatches($filter) {
  $applied = @()
  $unapplied = @()
  
  hg qseries -v | % {
    $bits = $_.Split(" ")
    $status = $bits[1]
    $name = $bits[2]
    
    if($status -eq "A") {
      $applied += $name
    } else {
      $unapplied += $name
    }
  }
  
  $all = $unapplied + $applied
  
  if($filter) {
    $all = $all | ? { $_.StartsWith($filter) }
  }
  
  return @{
    "All" = $all;
    "Unapplied" = $unapplied;
    "Applied" = $applied
  }
}

function Get-AliasPattern($exe) {
  $aliases = @($exe) + @(Get-Alias | where { $_.Definition -eq $exe } | select -Exp Name)
  "($($aliases -join '|'))"
}