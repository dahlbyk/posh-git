function isHgDirectory() {
  if(test-path ".hg") {
    return $true;
  }
  
  if(test-path ".git") {
    return $false; #short circuit if git repo
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

function Get-HgStatus {
  if(isHgDirectory) {
    $untracked = 0
    $added = 0
    $modified = 0
    $deleted = 0
    $missing = 0
    
    hg summary | foreach {   
      switch -regex ($_) {
        'branch: (\S*)' { $branch = $matches[1] }
        'commit: (.*)' {
          $matches[1].Split(",") | foreach {
            switch -regex ($_.Trim()) {
              '(\d+) modified' { $modified = $matches[1] }
              '(\d+) added' { $added = $matches[1] }
              '(\d+) removed' { $deleted = $matches[1] }
              '(\d+) deleted' { $missing = $matches[1] }
              '(\d+) unknown' { $untracked = $matches[1] }
            }
          } 
        } 
      } 
    }
    
    return @{"Untracked" = $untracked;
               "Added" = $added;
               "Modified" = $modified;
               "Deleted" = $deleted;
               "Missing" = $missing;
               "Branch" = $branch}
   }
}