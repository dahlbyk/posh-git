# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

$global:GitTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

$global:ops = @{
    remote = 'add','rename','rm','set-head','show','prune','update'
    stash = 'list','show','drop','pop','apply','branch','save','clear','create'
    svn = 'init', 'fetch', 'clone', 'rebase', 'dcommit', 'branch', 'tag', 'log', 'blame', 'find-rev', 'set-tree', 'create-ignore', 'show-ignore', 'mkdirs', 'commit-diff', 'info', 'proplist', 'propget', 'show-externals', 'gc', 'reset'
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

function script:gitLocalBranches($filter, $includeHEAD = $false) {
    $branches = git branch |
        foreach { if($_ -match "^\*?\s*(.*)") { $matches[1] } }

    @(if ($includeHEAD) { 'HEAD' }) + @($branches) |
        where { $_ -ne '(no branch)' -and $_ -like "$filter*" }
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

function script:gitDeleted($filter) {
    if($GitStatus) {
        @($GitStatus.Working.Deleted) + @($GitStatus.Index.Deleted) |
            where { $_ -like "$filter*" } |
            foreach { if($_ -like '* *') { "'$_'" } else { $_ } }
    }
}

function script:gitAliases($filter) {
    git config --get-regexp ^alias\. | foreach {
        if($_ -match "^alias\.(?<alias>\S+) .*") {
            $alias = $Matches['alias']
            if($alias -like "$filter*") {
                $alias
            }
        }
    } | Sort
}

function script:expandGitAlias($cmd, $rest) {
    if((git config --get-regexp "^alias\.$cmd`$") -match "^alias\.$cmd (?<cmd>[^!].*)`$") {
        return "git $($Matches['cmd'])$rest"
    } else {
        return "git $cmd$rest"
    }
}

function GitTabExpansion($lastBlock) {

    if($lastBlock -match "^$(Get-GitAliasPattern) (?<cmd>\S+)(?<args> .*)$") {
        $lastBlock = expandGitAlias $Matches['cmd'] $Matches['args']
    }

    # Handles tgit <command> (tortoisegit)
    if($lastBlock -match'^tgit (?<cmd>\S*)$') {
            # Need return statement to prevent fall-through.
            return $tortoiseGitCommands | where { $_ -like "$($matches['cmd'])*" }
    }

    switch -regex ($lastBlock -replace "^$(Get-GitAliasPattern) ","") {

        # Handles git remote <op>
        # Handles git stash <op>
        "^(?<cmd>remote|stash|svn) (?<op>\S*)$" {
            gitCmdOperations $matches['cmd'] $matches['op']
        }

        # Handles git remote (rename|rm|set-head|set-branches|set-url|show|prune) <stash>
        "^remote.* (?:rename|rm|set-head|set-branches|set-url|show|prune).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git stash (show|apply|drop|pop|branch) <stash>
        "^stash (?:show|apply|drop|pop|branch).* (?<stash>\S*)$" {
            gitStashes $matches['stash']
        }

        # Handles git branch -d|-D|-m|-M <branch name>
        # Handles git branch <branch name> <start-point>
        "^branch.* (?<branch>\S*)$" {
            gitLocalBranches $matches['branch']
        }

        # Handles git <cmd> (commands & aliases)
        "^(?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $TRUE
        }

        # Handles git help <cmd> (commands only)
        "^help (?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $FALSE
        }

        # Handles git push remote <branch>
        # Handles git pull remote <branch>
        "^(?:push|pull).* (?:\S+) (?<branch>\S*)$" {
            gitLocalBranches $matches['branch']
        }

        # Handles git pull <remote>
        # Handles git push <remote>
        # Handles git fetch <remote>
        "^(?:push|pull|fetch).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git reset HEAD <path>
        # Handles git reset HEAD -- <path>
        "^reset.* HEAD(?:\s+--)? (?<path>\S*)$" {
            gitIndex $matches['path']
        }

        # Handles git cherry-pick <commit>
        # Handles git diff <commit>
        # Handles git difftool <commit>
        # Handles git log <commit>
        # Handles git show <commit>
        "^(?:cherry-pick|diff|difftool|log|show).* (?<commit>\S*)$" {
            gitLocalBranches $matches['commit']
        }

        # Handles git reset <commit>
        "^reset.* (?<commit>\S*)$" {
            gitLocalBranches $matches['commit'] $true
        }

        # Handles git add <path>
        "^add.* (?<files>\S*)$" {
            gitFiles $matches['files']
        }

        # Handles git checkout -- <path>
        "^checkout.* -- (?<files>\S*)$" {
            gitFiles $matches['files']
        }

        # Handles git rm <path>
        "^rm.* (?<index>\S*)$" {
            gitDeleted $matches['index']
        }

        # Handles git checkout <branch name>
        # Handles git merge <branch name>
        # handles git rebase <branch name>
        "^(?:checkout|merge|rebase).* (?<branch>\S*)$" {
            gitLocalBranches $matches['branch']
        }
    }
}
