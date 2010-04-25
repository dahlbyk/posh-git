function HgTabExpansion($lastBlock) {
  switch -regex ($lastBlock) { 
    
    #handles hg update <branch name>
    #handles hg merge <branch name>
    'hg (update|merge) (\S*)$' {
      hgLocalBranches($matches[2])
    }
    
    #Handles hg push <path>
    #Handles hg pull <path>
    'hg (push|pull) (-\S* )*(\S*)$' {
      hgRemotes($matches[3])
    }
    
    #handles hg help <cmd>
    #handles hg <cmd>
    'hg (help )?(\S*)$' {
      hgCommands($matches[2]);
    }

	#handles hg <cmd> --<option>
	'hg (\S+) (-\S* )*--(\S*)$' {
		hgOptions $matches[1] $matches[3];
	}
    
    #handles hgtk help <cmd>
    #handles hgtk <cmd>
    'hgtk (help )?(\S*)$' {
      hgtkCommands($matches[2]);
    }
  }
}

function hgRemotes($filter) {
  hg paths | foreach {
    $path = $_.Split("=")[0].Trim();
    if($filter -and $path.StartsWith($filter)) {
      $path
    } elseif(-not $filter) {
      $path
    }
  }
}

function hgCommands($filter) {
  $cmdList = @()
  $output = hg help
  foreach($line in $output) {
    if($line -match '^ (\S+) (.*)') {
      $cmd = $matches[1]
      if($filter -and $cmd.StartsWith($filter)) {
        $cmdList += $cmd.Trim()
      }
      elseif(-not $filter) {
        $cmdList += $cmd.Trim()
      }
    }
  }
  
  $cmdList | sort
}

function hgLocalBranches($filter) {
  hg branches | foreach {
    if($_ -match "(\S+) .*") {
      if($filter -and $matches[1].StartsWith($filter)) {
        $matches[1]
      }
      elseif(-not $filter) {
        $matches[1]
      }
    }
  }
}

function hgOptions($cmd, $filter) {
	$optList = @()
	$output = hg help $cmd
	foreach($line in $output) {
		if($line -match '^ ((-\S)|  ) --(\S+) .*$') {
			$opt = $matches[3]
			if($filter -and $opt.StartsWith($filter)) {
				$optList += '--' + $opt.Trim()
			}
			elseif(-not $filter) {
				$optList += '--' + $opt.Trim()
			}
		}
	}

	$optList | sort
}

function hgtkCommands($filter) {
  $cmdList = @()
  $output = hgtk help
  foreach($line in $output) {
    if($line -match '^ (\S+) (.*)') {
      $cmd = $matches[1]
      if($filter -and $cmd.StartsWith($filter)) {
        $cmdList += $cmd.Trim()
      }
      elseif(-not $filter) {
        $cmdList += $cmd.Trim()
      }
    }
  }
  
  $cmdList | sort 
}
