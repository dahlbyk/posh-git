# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

function script:gitCommands($filter, $includeAliases, $advanced = $FALSE) {
    $cmdList = @()
    if (-not $advanced) {
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
    } else {
        $output = git help --all
        foreach ($line in $output) {
            if ($line -match '  (.+)') {
                $lineCmds = $line.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
                foreach ($cmd in $lineCmds) {
                    if($filter) {
                        if($filter -and $cmd.StartsWith($filter)) {
                            $cmdList += $cmd.Trim();
                        }
                    }
                    else {
                        $cmdList += $cmd.Trim();
                    }
                }
            }
        }
    }
    
    if ($includeAliases) {
        $cmdList += gitAliases $filter
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

function script:gitAliases($filter) {
    $aliasList = @()
    git config --get-regexp alias\..+ | foreach {
        $alias = $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[0].Split(
            '.', [StringSplitOptions]::RemoveEmptyEntries)[1]
            
        if($filter -and $alias.StartsWith($filter)) {
            $aliasList += $alias.Trim()
        }
    }
    $aliasList | Sort
}

function GitTabExpansion($lastBlock, $advanced = $FALSE) {
    switch -regex ($lastBlock) {
        # Handles git branch -d|-D <branch name>
        'git branch -(d|D) (\S*)$' {
            gitLocalBranches $matches[2]
        }
         
        # Handles git checkout <branch name>
        # Handles git merge <branch name>
        'git (checkout|merge) (\S*)$' {
            gitLocalBranches $matches[2]
        }
         
        # Handles git <cmd> (commands & aliases)
        'git (\S*)$' {
            gitCommands $matches[1] $TRUE $advanced
        }
        
        # Handles git help <cmd> (commands only)
        'git help (\S*)$' {
            gitCommands $matches[1] $FALSE $advanced
        }
         
        # Handles git push remote <branch>
        # Handles git pull remote <branch>
        'git (push|pull) (\S+) (\S*)$' {
            gitLocalBranches $matches[3]
        }
         
        # Handles git pull <remote>
        # Handles git push <remote>
        'git (push|pull) (\S*)$' {
            gitRemotes $matches[2]
        }

        # Handles git reset HEAD <path>
        'git reset HEAD (\S*)$' {
            gitIndex $matches[1]
        }

        # Handles git add <path>
        'git add (\S*)$' {
            gitFiles $matches[1]
        }
    }	
}