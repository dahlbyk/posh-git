# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

$global:GitTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

$global:ops = @{
    remote = 'add','rename','rm','set-head','show','prune','update'
    stash = 'list','show','drop','pop','apply','branch','save','clear','create'
}

function script:gitCmdOperations($command, $filter) {
    $ops.$command |
        where { $_ -like "$filter*" }
}

function script:gitCommands($filter, $includeAliases) {
    $cmdList = @()
    if (-not $global:GitTabSettings.AllCommands) {
        $cmdList += git help |
            foreach { if($_ -match '^   (\S+) (.*)') { $matches[1] } } |
            where { $_ -like "$filter*" }
    } else {
        $cmdList += git help --all |
            where { $_ -match '^  \S.*' } |
            foreach { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            where { $_ -like "$filter*" }
    }
    
    if ($includeAliases) {
        $cmdList += gitAliases $filter
    }
    $cmdList | sort
}

function script:gitRemotes($filter) {
    git remote |
        where { $_ -like "$filter*" }
}
 
function script:gitLocalBranches($filter) {
    git branch |
        foreach { if($_ -match "^\*?\s*(.*)") { $matches[1] } } |
        where { $_ -like "$filter*" }
}

function script:gitStashes($filter) {
    (git stash list) -replace ':.*','' |
        where { $_ -like "$filter*" } |
        foreach { "'$_'" }
}

function script:gitIndex($filter) {
    if($GitStatus) {
        $GitStatus.Index |
            where { $_ -like "$filter*" } |
            foreach { if($_ -like '* *') { "'$_'" } else { $_ } }
    }
}

function script:gitFiles($filter) {
    if($GitStatus) {
        $GitStatus.Working |
            where { $_ -like "$filter*" } |
            foreach { if($_ -like '* *') { "'$_'" } else { $_ } }
    }
}

function script:gitAliases($filter) {
    $aliasList = @()
    git config --get-regexp alias\..+ | foreach {
        $alias = $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[0].Split(
            '.', [StringSplitOptions]::RemoveEmptyEntries)[1]
            
        if($alias -like "$filter*") {
            $aliasList += $alias.Trim()
        }
    }
    $aliasList | Sort
}

function GitTabExpansion($lastBlock) {
    switch -regex ($lastBlock) {
        # Handles git remote <op>
        # Handles git stash <op>
        'git (remote|stash) (\S*)$' {
            gitCmdOperations $matches[1] $matches[2]
        }

        # Handles git stash (show|apply|drop|pop|branch) <stash>
        'git stash (show|apply|drop|pop|branch) (\S*)$' {
            gitStashes $matches[2]
        }
    
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
            gitCommands $matches[1] $TRUE
        }
        
        # Handles git help <cmd> (commands only)
        'git help (\S*)$' {
            gitCommands $matches[1] $FALSE
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

        # Handles git checkout -- <path>
        'git checkout -- (\S*)$' {
            gitFiles $matches[1]
        }
    }
}
