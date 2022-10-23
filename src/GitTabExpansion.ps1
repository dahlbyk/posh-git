# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

$Global:GitTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
    KnownAliases = @{
        '!f() { exec vsts code pr "$@"; }; f' = 'vsts.pr'
    }
    EnableLogging = $false
    LogPath = Join-Path ([System.IO.Path]::GetTempPath()) posh-git_tabexp.log
    RegisteredCommands = ""
}

$subcommands = @{
    bisect = "start bad good skip reset visualize replay log run"
    notes = 'add append copy edit get-ref list merge prune remove show'
    'vsts.pr' = 'create update show list complete abandon reactivate reviewers work-items set-vote policies'
    reflog = "show delete expire"
    remote = "
        add rename remove set-head set-branches
        get-url set-url show prune update
        "
    rerere = "clear forget diff remaining status gc"
    stash = 'push save list show apply clear drop pop create branch'
    submodule = "add status init deinit update summary foreach sync"
    svn = "
        init fetch clone rebase dcommit log find-rev
        set-tree commit-diff info create-ignore propget
        proplist show-ignore show-externals branch tag blame
        migrate mkdirs reset gc
        "
    tfs = "
        list-remote-branches clone quick-clone bootstrap init
        clone fetch pull quick-clone unshelve shelve-list labels
        rcheckin checkin checkintool shelve shelve-delete
        branch
        info cleanup cleanup-workspaces help verify autotag subtree reset-remote checkout
        "
    flow = "init feature bugfix release hotfix support help version"
    worktree = "add list lock move prune remove unlock"
}

$gitflowsubcommands = @{
    init = 'help'
    feature = 'list start finish publish track diff rebase checkout pull help delete'
    bugfix = 'list start finish publish track diff rebase checkout pull help delete'
    release = 'list start finish track publish help delete'
    hotfix = 'list start finish track publish help delete'
    support = 'list start help'
    config = 'list set base'
}

function script:gitCmdOperations($commands, $command, $filter) {
    $commands[$command].Trim() -split '\s+' | Where-Object { $_ -like "$filter*" }
}

$script:someCommands = @('add','am','annotate','archive','bisect','blame','branch','bundle','checkout','cherry',
                         'cherry-pick','citool','clean','clone','commit','config','describe','diff','difftool','fetch',
                         'format-patch','gc','grep','gui','help','init','instaweb','log','merge','mergetool','mv',
                         'notes','prune','pull','push','rebase','reflog','remote','rerere','reset','restore','revert','rm',
                         'shortlog','show','stash','status','submodule','svn','switch','tag','whatchanged', 'worktree')

if ((($PSVersionTable.PSVersion.Major -eq 5) -or $IsWindows) -and ($script:GitVersion -ge [System.Version]'2.16.2')) {
    $script:someCommands += 'update-git-for-windows'
}

$script:gitCommandsWithLongParams = $longGitParams.Keys -join '|'
$script:gitCommandsWithShortParams = $shortGitParams.Keys -join '|'
$script:gitCommandsWithParamValues = $gitParamValues.Keys -join '|'
$script:vstsCommandsWithShortParams = $shortVstsParams.Keys -join '|'
$script:vstsCommandsWithLongParams = $longVstsParams.Keys -join '|'

# The regular expression here is roughly follows this pattern:
#
# <begin anchor><whitespace>*<git>(<whitespace><parameter>)*<whitespace>+<$args><whitespace>*<end anchor>
#
# The delimiters inside the parameter list and between some of the elements are non-newline whitespace characters ([^\S\r\n]).
# In those instances, newlines are only allowed if they preceded by a non-newline whitespace character.
#
# Begin anchor (^|[;`n])
# Whitespace   (\s*)
# Git Command  (?<cmd>$(GetAliasPattern git))
# Parameters   (?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)
# $args Anchor (([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)
# Whitespace   (\s|``\r?\n)*
# End Anchor   ($|[|;`n])
$script:GitProxyFunctionRegex = "(^|[;`n])(\s*)(?<cmd>$(Get-AliasPattern git))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])"

try {
    if ($null -ne (git help -a 2>&1 | Select-String flow)) {
        $script:someCommands += 'flow'
    }
}
catch {
    Write-Debug "Search for 'flow' in 'git help' output failed with error: $_"
}

filter quoteStringWithSpecialChars {
    if ($_ -and ($_ -match '\s+|#|@|\$|;|,|''|\{|\}|\(|\)')) {
        $str = $_ -replace "'", "''"
        "'$str'"
    }
    else {
        $_
    }
}

function script:gitCommands($filter, $includeAliases) {
    $cmdList = @()
    if (-not $global:GitTabSettings.AllCommands) {
        $cmdList += $someCommands -like "$filter*"
    }
    else {
        $cmdList += git help --all |
            Where-Object { $_ -match '^\s{2,}\S.*' } |
            ForEach-Object { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            Where-Object { $_ -like "$filter*" }
    }

    if ($includeAliases) {
        $cmdList += gitAliases $filter
    }

    $cmdList | Sort-Object
}

function script:gitRemotes($filter) {
    git remote |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitBranches($filter, $includeHEAD = $false, $prefix = '') {
    if ($filter -match "^(?<from>\S*\.{2,3})(?<to>.*)") {
        $prefix += $matches['from']
        $filter = $matches['to']
    }

    $branches = @(git branch --no-color | ForEach-Object { if (($_ -notmatch "^\* \(HEAD detached .+\)$") -and ($_ -match "^[\*\+]?\s*(?<ref>\S+)(?: -> .+)?")) { $matches['ref'] } }) +
                @(git branch --no-color -r | ForEach-Object { if ($_ -match "^  (?<ref>\S+)(?: -> .+)?") { $matches['ref'] } }) +
                @(if ($includeHEAD) { 'HEAD','FETCH_HEAD','ORIG_HEAD','MERGE_HEAD' })

    $branches |
        Where-Object { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        ForEach-Object { $prefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitRemoteUniqueBranches($filter) {
    git branch --no-color -r |
        ForEach-Object { if ($_ -match "^  (?<remote>[^/]+)/(?<branch>\S+)(?! -> .+)?$") { $matches['branch'] } } |
        Group-Object -NoElement |
        Where-Object { $_.Count -eq 1 } |
        Select-Object -ExpandProperty Name |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitConfigKeys($section, $filter, $defaultOptions = '') {
    $completions = @($defaultOptions -split ' ')

    git config --name-only --get-regexp ^$section\..* |
        ForEach-Object { $completions += ($_ -replace "$section\.","") }

    return $completions |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        quoteStringWithSpecialChars
}

function script:gitTags($filter, $prefix = '') {
    git tag |
        Where-Object { $_ -like "$filter*" } |
        ForEach-Object { $prefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitFeatures($filter, $command) {
    $featurePrefix = git config --local --get "gitflow.prefix.$command"
    $branches = @(git branch --no-color | ForEach-Object { if ($_ -match "^\*?\s*$featurePrefix(?<ref>.*)") { $matches['ref'] } })
    $branches |
        Where-Object { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        ForEach-Object { $featurePrefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitRemoteBranches($remote, $ref, $filter, $prefix = '') {
    git branch --no-color -r |
        Where-Object { $_ -like "  $remote/$filter*" } |
        ForEach-Object { $prefix + $ref + ($_ -replace "  $remote/","") } |
        quoteStringWithSpecialChars
}

function script:gitStashes($filter) {
    (git stash list) -replace ':.*','' |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitTfsShelvesets($filter) {
    (git tfs shelve-list) |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitFiles($filter, $files) {
    $files | Sort-Object |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitIndex($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Index
}

function script:gitAddFiles($GitStatus, $filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Added))
}

function script:gitCheckoutFiles($GitStatus, $filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Deleted))
}

function script:gitDeleted($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Working.Deleted
}

function script:gitDiffFiles($GitStatus, $filter, $staged) {
    if ($staged) {
        gitFiles $filter $GitStatus.Index.Modified
    }
    else {
        gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Index.Modified))
    }
}

function script:gitMergeFiles($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Working.Unmerged
}

function script:gitRestoreFiles($GitStatus, $filter, $staged) {
    if ($staged) {
        gitFiles $filter (@($GitStatus.Index.Added) + @($GitStatus.Index.Modified) + @($GitStatus.Index.Deleted))
    }
    else {
        gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Deleted))
    }
}

function script:gitAliases($filter) {
    git config --get-regexp ^alias\. | ForEach-Object{
        if ($_ -match "^alias\.(?<alias>\S+) .*") {
            $alias = $Matches['alias']
            if ($alias -like "$filter*") {
                $alias
            }
        }
    } | Sort-Object -Unique
}

function script:expandGitAlias($cmd, $rest) {
    $alias = git config "alias.$cmd"

    if ($alias) {
        $known = $Global:GitTabSettings.KnownAliases[$alias]
        if ($known) {
            return "git $known$rest"
        }

        return "git $alias$rest"
    }
    else {
        return "git $cmd$rest"
    }
}

function script:expandLongParams($hash, $cmd, $filter) {
    $hash[$cmd].Trim() -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("--", $_) }
}

function script:expandShortParams($hash, $cmd, $filter) {
    $hash[$cmd].Trim() -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("-", $_) }
}

function script:expandParamValues($cmd, $param, $filter) {
    $paramValues = $gitParamValues[$cmd][$param]

    $completions = if ($paramValues -is [scriptblock]) {
        & $paramValues $filter
    }
    else {
        $paramValues.Trim() -split ' ' | Where-Object { $_ -like "$filter*" } | Sort-Object
    }

    $completions | ForEach-Object { -join ("--", $param, "=", $_) }
}

function Expand-GitCommand($Command) {
    # Parse all Git output as UTF8, including tab completion output - https://github.com/dahlbyk/posh-git/pull/359
    $res = Invoke-Utf8ConsoleCommand { GitTabExpansionInternal $Command $Global:GitStatus }
    $res
}

function GitTabExpansionInternal($lastBlock, $GitStatus = $null) {
    $ignoreGitParams = '(?<params>\s+-(?:[aA-zZ0-9]+|-[aA-zZ0-9][aA-zZ0-9-]*)(?:=\S+)?)*'

    if ($lastBlock -match "^$(Get-AliasPattern git) (?<cmd>\S+)(?<args> .*)$") {
        $lastBlock = expandGitAlias $Matches['cmd'] $Matches['args']
    }

    # Handles tgit <command> (tortoisegit)
    if ($lastBlock -match "^$(Get-AliasPattern tgit) (?<cmd>\S*)$") {
        # Need return statement to prevent fall-through.
        return $Global:TortoiseGitSettings.TortoiseGitCommands.Keys.GetEnumerator() | Sort-Object | Where-Object { $_ -like "$($matches['cmd'])*" }
    }

    # Handles gitk
    if ($lastBlock -match "^$(Get-AliasPattern gitk).* (?<ref>\S*)$") {
        return gitBranches $matches['ref'] $true
    }

    switch -regex ($lastBlock -replace "^$(Get-AliasPattern git) ","") {

        # Handles git <cmd> <op>
        "^(?<cmd>$($subcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $subcommands $matches['cmd'] $matches['op']
        }

        # Handles git flow <cmd> <op>
        "^flow (?<cmd>$($gitflowsubcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $gitflowsubcommands $matches['cmd'] $matches['op']
        }

        # Handles git flow <command> <op> <name>
        "^flow (?<command>\S*)\s+(?<op>\S*)\s+(?<name>\S*)$" {
            gitFeatures $matches['name'] $matches['command']
        }

        # Handles git remote (rename|rm|set-head|set-branches|set-url|show|prune) <stash>
        "^remote.* (?:rename|rm|set-head|set-branches|set-url|show|prune).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git stash (show|apply|drop|pop|branch) <stash>
        "^stash (?:show|apply|drop|pop|branch).* (?<stash>\S*)$" {
            gitStashes $matches['stash']
        }

        # Handles git bisect (bad|good|reset|skip) <ref>
        "^bisect (?:bad|good|reset|skip).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        # Handles git tfs unshelve <shelveset>
        "^tfs +unshelve.* (?<shelveset>\S*)$" {
            gitTfsShelvesets $matches['shelveset']
        }

        # Handles git branch -d|-D|-m|-M <branch name>
        # Handles git branch <branch name> <start-point>
        "^branch.* (?<branch>\S*)$" {
            gitBranches $matches['branch']
        }

        # Handles git <cmd> (commands & aliases)
        "^(?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $TRUE
        }

        # Handles git help <cmd> (commands only)
        "^help (?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $FALSE
        }

        # Handles git push remote <ref>:<branch>
        # Handles git push remote +<ref>:<branch>
        "^push${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<force>\+?)(?<ref>[^\s\:]*\:)(?<branch>\S*)$" {
            gitRemoteBranches $matches['remote'] $matches['ref'] $matches['branch'] -prefix $matches['force']
        }

        # Handles git push remote <ref>
        # Handles git push remote +<ref>
        # Handles git pull remote <ref>
        "^(?:push|pull)${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<force>\+?)(?<ref>[^\s\:]*)$" {
            gitBranches $matches['ref'] -prefix $matches['force']
            gitTags $matches['ref'] -prefix $matches['force']
        }

        # Handles git pull <remote>
        # Handles git push <remote>
        # Handles git fetch <remote>
        "^(?:push|pull|fetch)${ignoreGitParams}\s+(?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git reset HEAD <path>
        # Handles git reset HEAD -- <path>
        "^reset.* HEAD(?:\s+--)? (?<path>\S*)$" {
            gitIndex $GitStatus $matches['path']
        }

        # Handles git <cmd> <ref>
        "^commit.*-C\s+(?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        # Handles git add <path>
        "^add.* (?<files>\S*)$" {
            gitAddFiles $GitStatus $matches['files']
        }

        # Handles git checkout -- <path>
        "^checkout.* -- (?<files>\S*)$" {
            gitCheckoutFiles $GitStatus $matches['files']
        }

        # Handles git restore -s <ref> / --source=<ref> - must come before the next regex case
        "^restore.* (?-i)(-s\s*|(?<source>--source=))(?<ref>\S*)$" {
            gitBranches $matches['ref'] $true $matches['source']
            gitTags $matches['ref']
            break
        }

        # Handles git restore <path>
        "^restore(?:.* (?<staged>(?:(?-i)-S|--staged))|.*) (?<files>\S*)$" {
            gitRestoreFiles $GitStatus $matches['files'] $matches['staged']
        }

        # Handles git rm <path>
        "^rm.* (?<index>\S*)$" {
            gitDeleted $GitStatus $matches['index']
        }

        # Handles git diff/difftool <path>
        "^(?:diff|difftool)(?:.* (?<staged>(?:--cached|--staged))|.*) (?<files>\S*)$" {
            gitDiffFiles $GitStatus $matches['files'] $matches['staged']
        }

        # Handles git merge/mergetool <path>
        "^(?:merge|mergetool).* (?<files>\S*)$" {
            gitMergeFiles $GitStatus $matches['files']
        }

        # Handles git checkout|switch <ref>
        "^(?:checkout|switch).* (?<ref>\S*)$" {
            & {
                gitBranches $matches['ref'] $true
                gitRemoteUniqueBranches $matches['ref']
                gitTags $matches['ref']
                # Return only unique branches (to eliminate duplicates where the branch exists locally and on the remote)
            } | Select-Object -Unique
        }

        # Handles git worktree add <path> <ref>
        "^worktree add.* (?<files>\S+) (?<ref>\S*)$" {
            gitBranches $matches['ref']
        }

        # Handles git <cmd> <ref>
        "^(?:cherry|cherry-pick|diff|difftool|log|merge|rebase|reflog\s+show|reset|revert|show).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
            gitTags $matches['ref']
        }

        # Handles git <cmd> --<param>=<value>
        "^(?<cmd>$gitCommandsWithParamValues).* --(?<param>[^=]+)=(?<value>\S*)$" {
            expandParamValues $matches['cmd'] $matches['param'] $matches['value']
        }

        # Handles git <cmd> --<param>
        "^(?<cmd>$gitCommandsWithLongParams).* --(?<param>\S*)$" {
            expandLongParams $longGitParams $matches['cmd'] $matches['param']
        }

        # Handles git <cmd> -<shortparam>
        "^(?<cmd>$gitCommandsWithShortParams).* -(?<shortparam>\S*)$" {
            expandShortParams $shortGitParams $matches['cmd'] $matches['shortparam']
        }

        # Handles git pr alias
        "vsts\.pr\s+(?<op>\S*)$" {
            gitCmdOperations $subcommands 'vsts.pr' $matches['op']
        }

        # Handles git pr <cmd> --<param>
        "vsts\.pr\s+(?<cmd>$vstsCommandsWithLongParams).*--(?<param>\S*)$"
        {
            expandLongParams $longVstsParams $matches['cmd'] $matches['param']
        }

        # Handles git pr <cmd> -<shortparam>
        "vsts\.pr\s+(?<cmd>$vstsCommandsWithShortParams).*-(?<shortparam>\S*)$"
        {
            expandShortParams $shortVstsParams $matches['cmd'] $matches['shortparam']
        }
    }
}

function Expand-GitProxyFunction($command) {
    # Make sure the incoming command matches: <Command> <Args>, so we can extract the alias/command
    # name and the arguments being passed in.
    if ($command -notmatch '^(?<command>\S+)([^\S\r\n]|[^\S\r\n]`\r?\n)+(?<args>([^\S\r\n]|[^\S\r\n]`\r?\n|\S)*)$') {
        return $command
    }

    # Store arguments for replacement later
    $arguments = $matches['args']

    # Get the command name; if an alias exists, get the actual command name
    $commandName = $matches['command']
    if (Test-Path -Path Alias:\$commandName) {
        $commandName = Get-Item -Path Alias:\$commandName | Select-Object -ExpandProperty 'ResolvedCommandName'
    }

    # Extract definition of git usage
    if (Test-Path -Path Function:\$commandName) {
        $definition = Get-Item -Path Function:\$commandName | Select-Object -ExpandProperty 'Definition'
        if ($definition -match $script:GitProxyFunctionRegex) {
            # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
            return (("$($matches['cmd'].TrimStart()) $($matches['params']) $arguments") -replace '`\r?\n', ' ' -replace '\s+', ' ')
        }
    }

    return $command
}

function WriteTabExpLog([string] $Message) {
    if (!$global:GitTabSettings.EnableLogging) { return }

    $timestamp = Get-Date -Format HH:mm:ss
    "[$timestamp] $Message" | Out-File -Append $global:GitTabSettings.LogPath
}

if (!$UseLegacyTabExpansion -and ($PSVersionTable.PSVersion.Major -ge 6)) {
    $cmdNames = "git","tgit","gitk"

    # Create regex pattern from $cmdNames: ^(git|git\.exe|tgit|tgit\.exe|gitk|gitk\.exe)$
    $cmdNamesPattern = "^($($cmdNames -join '|'))(\.exe)?$"
    $cmdNames += Get-Alias | Where-Object { $_.Definition -match $cmdNamesPattern } | Foreach-Object Name

    if ($EnableProxyFunctionExpansion) {
        $funcNames += Get-ChildItem -Path Function:\ | Where-Object { $_.Definition -match $script:GitProxyFunctionRegex } | Foreach-Object Name
        $cmdNames += $funcNames

        # Create regex pattern from $funcNames e.g.: ^(Git-Checkout|Git-Switch)$
        $funcNamesPattern = "^($($funcNames -join '|'))$"
        $cmdNames += Get-Alias | Where-Object { $_.Definition -match $funcNamesPattern } | Foreach-Object Name
    }

    $global:GitTabSettings.RegisteredCommands = $cmdNames -join ", "

    Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName $cmdNames -Native -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        # The PowerShell completion has a habit of stripping the trailing space when completing:
        # git checkout <tab>
        # The Expand-GitCommand expects this trailing space, so pad with a space if necessary.
        $padLength = $cursorPosition - $commandAst.Extent.StartOffset
        $textToComplete = $commandAst.ToString().PadRight($padLength, ' ').Substring(0, $padLength)
        if ($EnableProxyFunctionExpansion) {
            $textToComplete = Expand-GitProxyFunction($textToComplete)
        }

        WriteTabExpLog "Expand: command: '$($commandAst.Extent.Text)', padded: '$textToComplete', padlen: $padLength"
        Expand-GitCommand $textToComplete
    }
}
else {
    $PowerTab_RegisterTabExpansion = if (Get-Module -Name powertab) { Get-Command Register-TabExpansion -Module powertab -ErrorAction SilentlyContinue }
    if ($PowerTab_RegisterTabExpansion) {
        & $PowerTab_RegisterTabExpansion git -Type Command {
            param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)

            $line = $Context.Line
            $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
            if ($EnableProxyFunctionExpansion) {
                $lastBlock = Expand-GitProxyFunction($lastBlock)
            }
            $TabExpansionHasOutput.Value = $true
            WriteTabExpLog "PowerTab expand: '$lastBlock'"
            Expand-GitCommand $lastBlock
        }

        return
    }

    function TabExpansion($line, $lastWord) {
        $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
        if ($EnableProxyFunctionExpansion) {
            $lastBlock = Expand-GitProxyFunction($lastBlock)
        }
        $msg = "Legacy expand: '$lastBlock'"

        switch -regex ($lastBlock) {
            # Execute git tab completion for all git-related commands
            "^$(Get-AliasPattern git) (.*)"  { WriteTabExpLog $msg; Expand-GitCommand $lastBlock }
            "^$(Get-AliasPattern tgit) (.*)" { WriteTabExpLog $msg; Expand-GitCommand $lastBlock }
            "^$(Get-AliasPattern gitk) (.*)" { WriteTabExpLog $msg; Expand-GitCommand $lastBlock }
        }
    }
}

# Handles Remove-GitBranch -Name parameter auto-completion using the built-in mechanism for cmdlet parameters
Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName Remove-GitBranch -ParameterName Name -ScriptBlock {
    param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

    gitBranches $WordToComplete $true
}
