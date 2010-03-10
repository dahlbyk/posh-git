# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

if(-not (Test-Path Function:\DefaultTabExpansion)) {
    Rename-Item Function:\TabExpansion DefaultTabExpansion
}

function script:gitCommands($filter) {
  $cmdList = @()
  $output = git help
  foreach($line in $output) {
    if($line -match '^   (\S+) (.*)') {
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

function script:gitRemotes($filter) {
  if($filter) {
    git remote | where { $_.StartsWith($filter) }
  }
  else {
    git remote
  }
}
 
function script:gitLocalBranches($filter) {
   git branch | foreach { 
      if($_ -match "^\*?\s*(.*)") { 
        if($filter -and $matches[1].StartsWith($filter)) {
          $matches[1]
        }
        elseif(-not $filter) {
          $matches[1]
        }
      } 
   }
}

function script:gitIndex($filter) {
    if($GitStatus) {
        if ($filter) {
            $GitStatus.Index | Where-Object { $_.StartsWith($filter) }
        } else {
            $GitStatus.Index
        }
    }
}

function script:gitFiles($filter) {
    if($GitStatus) {
        if ($filter) {
            $GitStatus.Working | Where-Object { $_.StartsWith($filter) }
        } else {
            $GitStatus.Working
        }
    }
}

function gitTabExpansion($line, $lastWord, $lastBlock) {
     switch -regex ($lastBlock) {
 
        #Handles git branch -x -y -z <branch name>
        'git branch -(d|D) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git checkout <branch name>
        #handles git merge <brancj name>
        'git (checkout|merge) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git <cmd>
        #handles git help <cmd>
        'git (help )?(\S*)$' {      
          gitCommands($matches[2])
        }
 
        #handles git push remote <branch>
        #handles git pull remote <branch>
        'git (push|pull) (\S+) (\S*)$' {
          gitLocalBranches($matches[3])
        }
 
        #handles git pull <remote>
        #handles git push <remote>
        'git (push|pull) (\S*)$' {
          gitRemotes($matches[2])
        }

		#handles git reset HEAD <path>
        'git reset HEAD (\S*)$' {
          gitIndex($matches[1])
        }

		#handles git add <path>
        'git add (\S*)$' {
          gitFiles($matches[1])
        }

        default {
          DefaultTabExpansion $line $lastWord
        }
    }	
}

function TabExpansion($line, $lastWord) {
  switch -regex ($line) {
    '(?:^\s*|[;|]\s*)git (.*)' { gitTabExpansion $line $lastWord $matches[0] }
    default { DefaultTabExpansion $line $lastWord }
  }
}
