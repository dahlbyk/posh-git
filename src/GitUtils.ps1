# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

<#
.SYNOPSIS
    Gets the path to the current repository's .git dir.
.DESCRIPTION
    Gets the path to the current repository's .git dir.  Or if the repository
    is a bare repository, the root directory of the bare repository.
.EXAMPLE
    PS C:\GitHub\posh-git\tests> Get-GitDirectory
    Returns C:\GitHub\posh-git\.git
.INPUTS
    None.
.OUTPUTS
    System.String
#>
function Get-GitDirectory {
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
        $null
    }
    elseif ($Env:GIT_DIR) {
        $Env:GIT_DIR -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
    }
    else {
        $currentDir = Get-Item -LiteralPath $pathInfo -Force
        while ($currentDir) {
            $gitDirPath = Join-Path $currentDir.FullName .git
            if (Test-Path -LiteralPath $gitDirPath -PathType Container) {
                return $gitDirPath
            }

            # Handle the worktree case where .git is a file
            if (Test-Path -LiteralPath $gitDirPath -PathType Leaf) {
                $gitDirPath = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                if ($gitDirPath) {
                    return $gitDirPath
                }
            }

            $headPath = Join-Path $currentDir.FullName HEAD
            if (Test-Path -LiteralPath $headPath -PathType Leaf) {
                $refsPath = Join-Path $currentDir.FullName refs
                $objsPath = Join-Path $currentDir.FullName objects
                if ((Test-Path -LiteralPath $refsPath -PathType Container) -and
                    (Test-Path -LiteralPath $objsPath -PathType Container)) {

                    $bareDir = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                    if ($bareDir -and (Test-Path -LiteralPath $bareDir -PathType Container)) {
                        $resolvedBareDir = (Resolve-Path $bareDir).Path
                        return $resolvedBareDir
                    }
                }
            }

            $currentDir = $currentDir.Parent
        }
    }
}

function Get-GitBranch($gitDir = $(Get-GitDirectory), [Diagnostics.Stopwatch]$sw) {
    if (!$gitDir) { return }

    Invoke-Utf8ConsoleCommand {
        dbg 'Finding branch' $sw
        $r = ''; $b = ''; $c = ''
        $step = ''; $total = ''
        if (Test-Path $gitDir/rebase-merge) {
            dbg 'Found rebase-merge' $sw
            if (Test-Path $gitDir/rebase-merge/interactive) {
                dbg 'Found rebase-merge/interactive' $sw
                $r = '|REBASE-i'
            }
            else {
                $r = '|REBASE-m'
            }
            $b = "$(Get-Content $gitDir/rebase-merge/head-name)"
            $step = "$(Get-Content $gitDir/rebase-merge/msgnum)"
            $total = "$(Get-Content $gitDir/rebase-merge/end)"
        }
        else {
            if (Test-Path $gitDir/rebase-apply) {
                dbg 'Found rebase-apply' $sw
                $step = "$(Get-Content $gitDir/rebase-merge/next)"
                $total = "$(Get-Content $gitDir/rebase-merge/last)"

                if (Test-Path $gitDir/rebase-apply/rebasing) {
                    dbg 'Found rebase-apply/rebasing' $sw
                    $r = '|REBASE'
                }
                elseif (Test-Path $gitDir/rebase-apply/applying) {
                    dbg 'Found rebase-apply/applying' $sw
                    $r = '|AM'
                }
                else {
                    $r = '|AM/REBASE'
                }
            }
            elseif (Test-Path $gitDir/MERGE_HEAD) {
                dbg 'Found MERGE_HEAD' $sw
                $r = '|MERGING'
            }
            elseif (Test-Path $gitDir/CHERRY_PICK_HEAD) {
                dbg 'Found CHERRY_PICK_HEAD' $sw
                $r = '|CHERRY-PICKING'
            }
            elseif (Test-Path $gitDir/REVERT_HEAD) {
                dbg 'Found REVERT_HEAD' $sw
                $r = '|REVERTING'
            }
            elseif (Test-Path $gitDir/BISECT_LOG) {
                dbg 'Found BISECT_LOG' $sw
                $r = '|BISECTING'
            }

            $b = Invoke-NullCoalescing `
                { dbg 'Trying symbolic-ref' $sw; git symbolic-ref HEAD -q 2>$null } `
                { '({0})' -f (Invoke-NullCoalescing `
                    {
                        dbg 'Trying describe' $sw
                        switch ($Global:GitPromptSettings.DescribeStyle) {
                            'contains' { git describe --contains HEAD 2>$null }
                            'branch' { git describe --contains --all HEAD 2>$null }
                            'describe' { git describe HEAD 2>$null }
                            default { git tag --points-at HEAD 2>$null }
                        }
                    } `
                    {
                        dbg 'Falling back on parsing HEAD' $sw
                        $ref = $null

                        if (Test-Path $gitDir/HEAD) {
                            dbg 'Reading from .git/HEAD' $sw
                            $ref = Get-Content $gitDir/HEAD 2>$null
                        }
                        else {
                            dbg 'Trying rev-parse' $sw
                            $ref = git rev-parse HEAD 2>$null
                        }

                        if ($ref -match 'ref: (?<ref>.+)') {
                            return $Matches['ref']
                        }
                        elseif ($ref -and $ref.Length -ge 7) {
                            return $ref.Substring(0,7)+'...'
                        }
                        else {
                            return 'unknown'
                        }
                    }
                ) }
        }

        dbg 'Inside git directory?' $sw
        if ('true' -eq $(git rev-parse --is-inside-git-dir 2>$null)) {
            dbg 'Inside git directory' $sw
            if ('true' -eq $(git rev-parse --is-bare-repository 2>$null)) {
                $c = 'BARE:'
            }
            else {
                $b = 'GIT_DIR!'
            }
        }

        if ($step -and $total) {
            $r += " $step/$total"
        }

        "$c$($b -replace 'refs/heads/','')$r"
    }
}

function GetUniquePaths($pathCollections) {
    $hash = New-Object System.Collections.Specialized.OrderedDictionary

    foreach ($pathCollection in $pathCollections) {
        foreach ($path in $pathCollection) {
            $hash[$path] = 1
        }
    }

    $hash.Keys
}

$castStringSeq = [Linq.Enumerable].GetMethod("Cast").MakeGenericMethod([string])

<#
.SYNOPSIS
    Gets a Git status object that is used by Write-GitStatus.
.DESCRIPTION
    Gets a Git status object that is used by Write-GitStatus.
    The status object provides the information to be displayed in the various
    sections of the posh-git prompt.
.EXAMPLE
    PS C:\> $s = Get-GitStatus; Write-GitStatus $s
    Gets a Git status object. Then passes the object to Write-GitStatus which
    writes out a posh-git prompt (or returns a string in ANSI mode) with the
    information contained in the status object.
.INPUTS
    None
.OUTPUTS
    System.Management.Automation.PSObject
.LINK
    Write-GitStatus
#>
function Get-GitStatus {
    param(
        # The path of a directory within a Git repository that you want to get
        # the Git status.
        [Parameter(Position=0)]
        $GitDir = (Get-GitDirectory),

        # If specified, overrides $GitPromptSettings.EnablePromptStatus when it
        # is set to $false.
        [Parameter()]
        [switch]
        $Force
    )

    $settings = $Global:GitPromptSettings
    $enabled = $Force -or !$settings -or $settings.EnablePromptStatus
    if ($enabled -and $GitDir) {
        if ($settings.Debug) {
            $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
        }
        else {
            $sw = $null
        }

        $branch = $null
        $aheadBy = 0
        $behindBy = 0
        $gone = $false
        $indexAdded = New-Object System.Collections.Generic.List[string]
        $indexModified = New-Object System.Collections.Generic.List[string]
        $indexDeleted = New-Object System.Collections.Generic.List[string]
        $indexUnmerged = New-Object System.Collections.Generic.List[string]
        $filesAdded = New-Object System.Collections.Generic.List[string]
        $filesModified = New-Object System.Collections.Generic.List[string]
        $filesDeleted = New-Object System.Collections.Generic.List[string]
        $filesUnmerged = New-Object System.Collections.Generic.List[string]
        $stashCount = 0

        if ($settings.EnableFileStatus -and !$(InDotGitOrBareRepoDir $GitDir) -and !$(InDisabledRepository)) {
            if ($null -eq $settings.EnableFileStatusFromCache) {
                $settings.EnableFileStatusFromCache = $null -ne (Get-Module GitStatusCachePoshClient)
            }

            if ($settings.EnableFileStatusFromCache) {
                dbg 'Getting status from cache' $sw
                $cacheResponse = Get-GitStatusFromCache
                dbg 'Parsing status' $sw

                $indexAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexAdded))))
                $indexModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexModified))))
                foreach ($indexRenamed in $cacheResponse.IndexRenamed) {
                    $indexModified.Add($indexRenamed.Old)
                }
                $indexDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexDeleted))))
                $indexUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $filesAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingAdded))))
                $filesModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingModified))))
                foreach ($workingRenamed in $cacheResponse.WorkingRenamed) {
                    $filesModified.Add($workingRenamed.Old)
                }
                $filesDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingDeleted))))
                $filesUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $branch = $cacheResponse.Branch
                $upstream = $cacheResponse.Upstream
                $gone = $cacheResponse.UpstreamGone
                $aheadBy = $cacheResponse.AheadBy
                $behindBy = $cacheResponse.BehindBy

                if ($cacheResponse.Stashes) { $stashCount = $cacheResponse.Stashes.Length }
                if ($cacheResponse.State) { $branch += "|" + $cacheResponse.State }
            }
            else {
                dbg 'Getting status' $sw
                switch ($settings.UntrackedFilesMode) {
                    "No"      { $untrackedFilesOption = "-uno" }
                    "All"     { $untrackedFilesOption = "-uall" }
                    "Normal"  { $untrackedFilesOption = "-unormal" }
                }
                $status = Invoke-Utf8ConsoleCommand { git -c core.quotepath=false -c color.status=false status $untrackedFilesOption --short --branch 2>$null }
                if ($settings.EnableStashStatus) {
                    dbg 'Getting stash count' $sw
                    $stashCount = $null | git stash list 2>$null | measure-object | Select-Object -expand Count
                }

                dbg 'Parsing status' $sw
                switch -regex ($status) {
                    '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {
                        if ($sw) { dbg "Status: $_" $sw }

                        switch ($matches['index']) {
                            'A' { $null = $indexAdded.Add($matches['path1']); break }
                            'M' { $null = $indexModified.Add($matches['path1']); break }
                            'R' { $null = $indexModified.Add($matches['path1']); break }
                            'C' { $null = $indexModified.Add($matches['path1']); break }
                            'D' { $null = $indexDeleted.Add($matches['path1']); break }
                            'U' { $null = $indexUnmerged.Add($matches['path1']); break }
                        }
                        switch ($matches['working']) {
                            '?' { $null = $filesAdded.Add($matches['path1']); break }
                            'A' { $null = $filesAdded.Add($matches['path1']); break }
                            'M' { $null = $filesModified.Add($matches['path1']); break }
                            'D' { $null = $filesDeleted.Add($matches['path1']); break }
                            'U' { $null = $filesUnmerged.Add($matches['path1']); break }
                        }
                        continue
                    }

                    '^## (?<branch>\S+?)(?:\.\.\.(?<upstream>\S+))?(?: \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?(?<gone>gone)?\])?$' {
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        $upstream = $matches['upstream']
                        $aheadBy = [int]$matches['ahead']
                        $behindBy = [int]$matches['behind']
                        $gone = [string]$matches['gone'] -eq 'gone'
                        continue
                    }

                    '^## Initial commit on (?<branch>\S+)$' {
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        continue
                    }

                    default { if ($sw) { dbg "Status: $_" $sw } }
                }
            }
        }

        if (!$branch) { $branch = Get-GitBranch $GitDir $sw }

        dbg 'Building status object' $sw

        # This collection is used twice, so create the array just once
        $filesAdded = $filesAdded.ToArray()

        $indexPaths = @(GetUniquePaths $indexAdded,$indexModified,$indexDeleted,$indexUnmerged)
        $workingPaths = @(GetUniquePaths $filesAdded,$filesModified,$filesDeleted,$filesUnmerged)
        $index = (,$indexPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $indexAdded.ToArray() |
            Add-Member -Force -PassThru NoteProperty Modified $indexModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $indexDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $indexUnmerged.ToArray()

        $working = (,$workingPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $filesAdded |
            Add-Member -Force -PassThru NoteProperty Modified $filesModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $filesDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $filesUnmerged.ToArray()

        $result = New-Object PSObject -Property @{
            GitDir          = $GitDir
            RepoName        = Split-Path (Split-Path $GitDir -Parent) -Leaf
            Branch          = $branch
            AheadBy         = $aheadBy
            BehindBy        = $behindBy
            UpstreamGone    = $gone
            Upstream        = $upstream
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
            StashCount      = $stashCount
        }

        dbg 'Finished' $sw
        if ($sw) { $sw.Stop() }
        return $result
    }
}

function InDisabledRepository {
    $currentLocation = Get-Location

    foreach ($repo in $Global:GitPromptSettings.RepositoriesInWhichToDisableFileStatus) {
        if ($currentLocation -like "$repo*") {
            return $true
        }
    }

    return $false
}

function InDotGitOrBareRepoDir([string][ValidateNotNullOrEmpty()]$GitDir) {
    # A UNC path has no drive so it's better to use the ProviderPath e.g. "\\server\share".
    # However for any path with a drive defined, it's better to use the Path property.
    # In this case, ProviderPath is "\LocalMachine\My"" whereas Path is "Cert:\LocalMachine\My".
    # The latter is more desirable.
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    $currentPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }
    $res = $currentPath.StartsWith($GitDir, (Get-PathStringComparison))
    $res
}

function Get-AliasPattern($exe) {
   $aliases = @($exe) + @(Get-Alias | Where-Object { $_.Definition -eq $exe } | Select-Object -Exp Name)
   "($($aliases -join '|'))"
}

<#
.SYNOPSIS
    Removes the specified Git branch or branches if a wildcard pattern is used.
.DESCRIPTION
    Removes the specified Git branches REGARDLESS of their merge status.
    You must either specify a branch name via the Name parameter, which
    accepts wildard characters, or via the Pattern parameter, which accepts
    a regular expression.

    By default, the following branches are always excluded from removal:
    the current branch and the develop and master branches.

    IMPORTANT: BE VERY CAREFUL using this command.  As a consequence of the
    downside potential of deleting unmerged branches, this command requires
    confirmation for each branch it deletes by default. You can suppress
    confirmation prompting by using the Force parameter.  In order to get
    this command to "delete with force" unmerged branches, you have to
    separately specify the DeleteForce parameter.

    If you only want to remove *merged branches*, please use the
    Remove-MergedGitBranch command instead. The Remove-MergedGitBranch command
    limits branch candidates to only those that have been merged. Consequently
    Remove-MergedGitBranch does not prompt for confirmation.

    The following Git commands are executed by this command:

    git branch | Where-Object {$_ -notmatch $ExcludePattern} |
        Where-Object {$_.Trim() -like $Name} |
        Foreach-Object {git branch --delete $_.Trim()}

    If the DeleteForce parameter is specified, this command executes:

    git branch | Where-Object {$_ -notmatch $ExcludePattern} |
        Where-Object {$_.Trim() -like $Name} |
        Foreach-Object {git branch --delete --force $_.Trim()}

    If the Pattern parameter is used instead of the Name parameter, the second
    Where-Object changes to: Where-Object {$_ -match $Pattern }.

    Recovering Deleted Branches:
    If you wind up deleting a branch you didn't intend to, you can easily
    recover it with the info provided by Git during the delete.  For instance,
    let's say you realized you didn't want to delete the branch 'feature/exp1'.
    In the output of this command, you should see a deletion entry for this
    branch that looks like:

    Deleted branch feature/exp1 (was 08f9000).

    To recover this branch, execute the following Git command:

    # git branch <branch-name> <sha1>
    git branch feature/exp1 08f9000
.EXAMPLE
    PS> Remove-GitBranch -Name "user/${env:USERNAME}/*" -WhatIf
    Shows the branches that would be removed by the specified regular
    expression without actually removing them. Remove the WhatIf parameter
    when you are happy with the list of branches that will be removed.
.EXAMPLE
    PS> Remove-GitBranch "feature/*" -Force
    Removes the branches that match the specified wildcard. Using -Force skips
    all the confirmation prompts. Name is a positional parameter. The
    first argument is assumed to be the value of the -Name parameter.
.EXAMPLE
    PS> Remove-GitBranch "bugfix/*" -Force -DeleteForce
    Removes the branches that match the specified wildcard. Using the Force
    parameter skips all the confirmation prompts while the DeleteForce
    parameter uses the --force option in the underlying
    `git branch --delete <branch-name>` command.
.EXAMPLE
    PS> Remove-GitBranch -Pattern 'user/(dahlbyk|hillr)/.*'
    Removes the branches that match the specified regular expression.
.EXAMPLE
    PS> Remove-GitBranch -Name * -ExcludePattern '(^\*)|(^. (develop|master|v\d+)$)'
    Removes ALL branches except the current branch, develop, master and branches
    that also match the pattern 'v\d+' e.g. v1, v1.0, v1.x. BE VERY CAREFUL
    WHEN SPECIYING SUCH A BROAD -NAME WILDCARD TO THIS COMMAND!
.LINK
    Remove-MergedGitBranch
#>
function Remove-GitBranch {
    [CmdletBinding(DefaultParameterSetName="Wildcard", SupportsShouldProcess, ConfirmImpact="Medium")]
    param(
        # Specifies a regular expression pattern for the branches that will be deleted.
        # Certain branches are always excluded from deletion e.g. the current branch
        # as well as the develop and master branches.  See the ExcludePattern
        # parameter to modify that pattern.
        [Parameter(Position=0, Mandatory, ParameterSetName="Wildcard")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        # Specifies a regular expression pattern for the branches that will be deleted.
        # Certain branches are always excluded from deletion e.g. the current branch
        # as well as the develop and master branches.  See the ExcludePattern
        # parameter to modify that pattern.
        [Parameter(Position=0, Mandatory, ParameterSetName="Pattern")]
        [ValidateNotNull()]
        [string]
        $Pattern,

        # Specifies a regular expression used to exclude merged branches from being removed.
        # The default pattern excludes the current branch, develop and master branches.
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $ExcludePattern = '(^\*)|(^. (develop|master)$)',

        # Removes the specified branches without prompting for confirmation. By default,
        # Remove-GitBranch prompts for confirmation before removing branches.
        [Parameter()]
        [switch]
        $Force,

        # Removes the specified branches by adding the --force parameter to the
        # git branch --delete command e.g. git branch --delete --force <branch-name>.
        # This is also the equivalent of using the -D parameter on the git
        # branch command.
        [Parameter()]
        [switch]
        $DeleteForce
    )

    $branches = git branch | Where-Object {$_ -notmatch $ExcludePattern }

    if ($PSCmdlet.ParameterSetName -eq "Wildcard") {
        $branchesToDelete = $branches | Where-Object { $_.Trim() -like $Name }
    }
    else {
        $branchesToDelete = $branches | Where-Object { $_ -match $Pattern }
    }

    $action = if ($DeleteForce) { "delete with force"} else { "delete" }
    $yesToAll = $noToAll = $false

    foreach ($branch in $branchesToDelete) {
        $targetBranch = $branch.Trim()
        if ($PSCmdlet.ShouldProcess($targetBranch, $action)) {
            if ($Force -or $yesToAll -or
                $PSCmdlet.ShouldContinue("Are you REALLY sure you want to $action `"$targetBranch`"?",
                                         "Confirm branch deletion", [ref]$yesToAll, [ref]$noToAll)) {

                if ($noToAll) { return }

                if ($DeleteForce) {
                    Invoke-Utf8ConsoleCommand { git branch --delete --force $targetBranch }
                }
                else {
                    Invoke-Utf8ConsoleCommand { git branch --delete $targetBranch }
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Removes the specified Git branch or branches that have been merged.
.DESCRIPTION
    Removes the specified Git branches that have been merged into the
    commit specified by the Commit parameter (HEAD by default).

    By default, the following branches are always excluded from removal:
    the current branch and the `develop` and `master` branches.

    IMPORTANT: Be careful using this command. Most, if not all, of your
    historical branches have been merged but that doesn't mean you want to
    remove them.  That is why this command excludes `develop` and `master` by
    default. But you may use different names e.g. `development` or have other
    historical branches you don't want to delete.  In these cases, you can
    either:

    * Request confirmation by using the Confirm parameter.
    * Specify a narrower branch Name wildcard such as "user/$env:USERNAME/*".
    * Specify an updated ExcludeParameter e.g. '(^\*)|(^. (develop|master|v\d+)$)'
      which adds any branch matching the pattern 'v\d+' to the exclusion list.

    The following Git commands are executed by this command:

    git branch --merged $Commit | Where-Object {$_ -notmatch $ExcludePattern} |
        Where-Object {$_.Trim() -like $Name} |
        Foreach-Object {git branch --delete $_.Trim()}

    If the Pattern parameter is used instead of the Name parameter, the second
    Where-Object changes to: Where-Object {$_ -match $Pattern }.

    Recovering Deleted Branches:
    If you wind up deleting a branch you didn't intend to, you can easily
    recover it with the info provided by Git during the delete.  For instance,
    let's say you realized you didn't want to delete the branch 'feature/exp1'.
    In the output of this command, you should see a deletion entry for this
    branch that looks like:

    Deleted branch feature/exp1 (was 08f9000).

    To recover this branch, execute the following Git command:

    # git branch <branch-name> <sha1>
    git branch feature/exp1 08f9000
.EXAMPLE
    PS> Remove-MergedGitBranch -Name "user/$env:USERNAME/*" -Whatif
    Shows which branches would be removed without actually removing them.
    Remove the WhatIf parameter when you are happy with the list of branches
    that will be removed.
.EXAMPLE
    PS> Remove-MergedGitBranch "feature/*"
    Removes only merged feature/* branches except for the current branch, if
    it matches this wildcard pattern. Note that Name is a positional (first)
    parameter.
.EXAMPLE
    PS> Remove-MergedGitBranch "*" -Confirm
    Removes all merged branches but give you the chance to confirm each and
    every branch deletion.
.EXAMPLE
    PS> Remove-MergedGitBranch -Pattern "user/(dahlbyk|hillr)/.*"
    Removes only merged feature/* branches except the current branch, if it's a
    feature branch.
.EXAMPLE
    PS> Remove-MergedGitBranch -ExcludePattern '(^\*)|(^. (develop|master|v\d+)$)'
    Removes ALL merged branches except the current branch, develop, master and
    branches that also match the pattern 'v\d+' e.g. v1, v1.0, v1.x.
.LINK
    Remove-GitBranch
#>
function Remove-MergedGitBranch {
    [CmdletBinding(DefaultParameterSetName="Wildcard", SupportsShouldProcess)]
    param(
        # Specifies a regular expression pattern for the merged branches that will be deleted.
        # Certain branches are always excluded from deletion e.g. the current branch
        # as well as the develop and master branches.  See the ExcludePattern
        # parameter to modify that pattern.
        [Parameter(Position=0, Mandatory, ParameterSetName="Wildcard")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        # Specifies a regular expression pattern for the merged ranches that will be deleted.
        # Certain branches are always excluded from deletion e.g. the current branch
        # as well as the develop and master branches.  See the ExcludePattern
        # parameter to modify that pattern.
        [Parameter(Position=0, Mandatory, ParameterSetName="Pattern")]
        [ValidateNotNull()]
        [string]
        $Pattern,

        # Branches whose tips are reachable from the specified commit will be removed.
        # The default commit is HEAD.
        [Parameter(Position=1)]
        [string]
        $Commit = "HEAD",

        # Specifies a regular expression used to exclude merged branches from being removed.
        # The default "notmatch" pattern '(^\*)|(^. (develop|master)$)' which
        # excludes the current branch in addition to the develop and master branches.
        [Parameter()]
        [string]
        $ExcludePattern = '(^\*)|(^. (develop|master)$)'
    )

    $branches = git branch --merged | Where-Object {$_ -notmatch $ExcludePattern }

    if ($PSCmdlet.ParameterSetName -eq "Wildcard") {
        $branchesToDelete = $branches | Where-Object { $_.Trim() -like $Name }
    }
    else {
        $branchesToDelete = $branches | Where-Object { $_ -match $Pattern }
    }

    foreach ($branch in $branchesToDelete) {
        $targetBranch = $branch.Trim()
        if ($PSCmdlet.ShouldProcess($targetBranch, "delete")) {
            Invoke-Utf8ConsoleCommand { git branch --delete $targetBranch }
        }
    }
}

function Update-AllBranches($Upstream = 'master', [switch]$Quiet) {
    $head = git rev-parse --abbrev-ref HEAD
    git checkout -q $Upstream
    $branches = Invoke-Utf8ConsoleCommand { (git branch --no-color --no-merged) } | Where-Object { $_ -notmatch '^\* ' }
    foreach ($line in $branches) {
        $branch = $line.SubString(2)
        if (!$Quiet) { Write-Host "Rebasing $branch onto $Upstream..." }

        git rebase -q $Upstream $branch > $null 2> $null
        if ($LASTEXITCODE) {
            git rebase --abort
            Write-Warning "Rebase failed for $branch"
        }
    }

    git checkout -q $head
}
