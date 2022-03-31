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

function Get-GitBranch($branch = $null, $gitDir = $(Get-GitDirectory), [switch]$isDotGitOrBare, [Diagnostics.Stopwatch]$sw) {
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
                $step = "$(Get-Content $gitDir/rebase-apply/next)"
                $total = "$(Get-Content $gitDir/rebase-apply/last)"

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

            if ($step -and $total) {
                $r += " $step/$total"
            }

            $b = Invoke-NullCoalescing `
                $b `
                $branch `
                { dbg 'Trying symbolic-ref' $sw; git --no-optional-locks symbolic-ref HEAD -q 2>$null } `
                { '({0})' -f (Invoke-NullCoalescing `
                    {
                        dbg 'Trying describe' $sw
                        switch ($Global:GitPromptSettings.DescribeStyle) {
                            'contains' { git --no-optional-locks describe --contains HEAD 2>$null }
                            'branch' { git --no-optional-locks describe --contains --all HEAD 2>$null }
                            'describe' { git --no-optional-locks describe HEAD 2>$null }
                            default { git --no-optional-locks tag --points-at HEAD 2>$null }
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
                            $ref = git --no-optional-locks rev-parse HEAD 2>$null
                        }

                        if ($ref -match 'ref: (?<ref>.+)') {
                            return $Matches['ref']
                        }
                        elseif ($ref -and $ref.Length -ge 7) {
                            return $ref.Substring(0, 7) + '...'
                        }
                        else {
                            return 'unknown'
                        }
                    }
                ) }
        }

        if ($isDotGitOrBare -or !$b) {
            dbg 'Inside git directory?' $sw
            $revParseOut = git --no-optional-locks rev-parse --is-inside-git-dir 2>$null
            if ('true' -eq $revParseOut) {
                dbg 'Inside git directory' $sw
                $revParseOut = git --no-optional-locks rev-parse --is-bare-repository 2>$null
                if ('true' -eq $revParseOut) {
                    $c = 'BARE:'
                }
                else {
                    $b = 'GIT_DIR!'
                }
            }
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
    Gets a Git status object that is used by `Write-GitStatus`.
.DESCRIPTION
    The `Get-GitStatus` cmdlet gets the status of the current Git repo.

    The status object returned by this cmdlet provides the information
    displayed in the various sections of the posh-git prompt. The following
    properties in $GitPromptSettings control what information is returned in
    the status object:

    EnableFileStatus          = $true # Or $false if Git not installed
    EnableFileStatusFromCache = <unset> # Or $true if GitStatusCachePoshClient installed
    EnablePromptStatus        = $true
    EnableStashStatus         = $false
    UntrackedFilesMode        = Default # Other enum values: No, Normal, All

    The `Force` parameter can be used to override the EnableFileStatus and
    EnablePromptStatus properties to ensure that both file and prompt status
    information is returned in the status object.
.EXAMPLE
    PS C:\> $s = Get-GitStatus; Write-GitStatus $s
    Gets a Git status object. Then passes the object to Write-GitStatus which
    writes out a posh-git prompt (or returns a string in ANSI mode) with the
    information contained in the status object.
.EXAMPLE
    PS C:\> $s = Get-GitStatus -Force
    Gets a Git status object that always returns all status information even
    if $GitPromptSettings has disabled `EnableFileStatus` and/or
    `EnablePromptStatus`.
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
        [Parameter(Position = 0)]
        $GitDir = (Get-GitDirectory),

        # If specified, overrides $GitPromptSettings.EnableFileStatus and
        # $GitPromptSettings.EnablePromptStatus when they are set to $false.
        [Parameter()]
        [switch]
        $Force
    )

    $settings = if ($global:GitPromptSettings) { $global:GitPromptSettings } else { [PoshGitPromptSettings]::new() }

    $promptStatusEnabled = $Force -or $settings.EnablePromptStatus
    if ($promptStatusEnabled -and $GitDir) {
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
        $upstream = $null

        $indexAdded = New-Object System.Collections.Generic.List[string]
        $indexModified = New-Object System.Collections.Generic.List[string]
        $indexDeleted = New-Object System.Collections.Generic.List[string]
        $indexUnmerged = New-Object System.Collections.Generic.List[string]
        $filesAdded = New-Object System.Collections.Generic.List[string]
        $filesModified = New-Object System.Collections.Generic.List[string]
        $filesDeleted = New-Object System.Collections.Generic.List[string]
        $filesUnmerged = New-Object System.Collections.Generic.List[string]
        $stashCount = 0

        $fileStatusEnabled = $Force -or $settings.EnableFileStatus
        # Optimization: short-circuit to avoid InDotGitOrBareRepoDir and InDisabledRepository if !$fileStatusEnabled
        if ($fileStatusEnabled -and !$($isDotGitOrBare = InDotGitOrBareRepoDir $GitDir) -and !$(InDisabledRepository)) {
            if ($null -eq $settings.EnableFileStatusFromCache) {
                $settings.EnableFileStatusFromCache = $null -ne (Get-Module GitStatusCachePoshClient)
            }

            if ($settings.EnableFileStatusFromCache) {
                dbg 'Getting status from cache' $sw
                $cacheResponse = Get-GitStatusFromCache

                if ($cacheResponse.Error) {
                    # git-status-cache failed; set $global:GitStatusCacheLoggingEnabled = $true, call Restart-GitStatusCache,
                    # and check %temp%\GitStatusCache_[timestamp].log for details.
                    dbg "Cache returned an error: $($cacheResponse.Error)" $sw
                    $branch = "CACHE ERROR"
                    $behindBy = 1
                }
                else {
                    dbg 'Parsing status' $sw

                    $indexAdded.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.IndexAdded))))
                    $indexModified.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.IndexModified))))
                    foreach ($indexRenamed in $cacheResponse.IndexRenamed) {
                        $indexModified.Add($indexRenamed.Old)
                    }
                    $indexDeleted.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.IndexDeleted))))
                    $indexUnmerged.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.Conflicted))))

                    $filesAdded.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.WorkingAdded))))
                    $filesModified.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.WorkingModified))))
                    foreach ($workingRenamed in $cacheResponse.WorkingRenamed) {
                        $filesModified.Add($workingRenamed.Old)
                    }
                    $filesDeleted.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.WorkingDeleted))))
                    $filesUnmerged.AddRange($castStringSeq.Invoke($null, (, @($cacheResponse.Conflicted))))

                    $branch = $cacheResponse.Branch
                    $upstream = $cacheResponse.Upstream
                    $gone = $cacheResponse.UpstreamGone
                    $aheadBy = $cacheResponse.AheadBy
                    $behindBy = $cacheResponse.BehindBy

                    if ($settings.EnableStashStatus -and $cacheResponse.Stashes) {
                        $stashCount = $cacheResponse.Stashes.Length
                    }

                    if ($cacheResponse.State) {
                        $branch += "|" + $cacheResponse.State
                    }
                }
            }
            else {
                dbg 'Getting status' $sw
                switch ($settings.UntrackedFilesMode) {
                    "No" { $untrackedFilesOption = "-uno" }
                    "All" { $untrackedFilesOption = "-uall" }
                    default { $untrackedFilesOption = "-unormal" }
                }
                $status = Invoke-Utf8ConsoleCommand { git --no-optional-locks -c core.quotepath=false -c color.status=false status $untrackedFilesOption --short --branch 2>$null }
                if ($settings.EnableStashStatus) {
                    dbg 'Getting stash count' $sw
                    $stashCount = $null | git --no-optional-locks stash list 2>$null | measure-object | Select-Object -expand Count
                }

                dbg 'Parsing status' $sw
                switch -regex ($status) {
                    '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {
                        if ($sw) { dbg "Status: $_" $sw }

                        $path1 = $matches['path1']

                        # Even with core.quotePath=false, paths with spaces are wrapped in ""
                        # https://github.com/git/git/commit/dbfdc625a5aad10c47e3ffa446d0b92e341a7b44
                        # https://github.com/git/git/commit/f3fc4a1b8680c114defd98ce6f2429f8946a5dc1
                        if ($path1 -like '"*"') {
                            $path1 = $path1.Substring(1, $path1.Length - 2)
                        }

                        switch ($matches['index']) {
                            'A' { $null = $indexAdded.Add($path1); break }
                            'M' { $null = $indexModified.Add($path1); break }
                            'R' { $null = $indexModified.Add($path1); break }
                            'C' { $null = $indexModified.Add($path1); break }
                            'D' { $null = $indexDeleted.Add($path1); break }
                            'U' { $null = $indexUnmerged.Add($path1); break }
                        }
                        switch ($matches['working']) {
                            '?' { $null = $filesAdded.Add($path1); break }
                            'A' { $null = $filesAdded.Add($path1); break }
                            'M' { $null = $filesModified.Add($path1); break }
                            'D' { $null = $filesDeleted.Add($path1); break }
                            'U' { $null = $filesUnmerged.Add($path1); break }
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

        $branch = Get-GitBranch -Branch $branch -GitDir $GitDir -IsDotGitOrBare:$isDotGitOrBare -sw $sw

        dbg 'Building status object' $sw

        # This collection is used twice, so create the array just once
        $filesAdded = $filesAdded.ToArray()

        $indexPaths = @(GetUniquePaths $indexAdded, $indexModified, $indexDeleted, $indexUnmerged)
        $workingPaths = @(GetUniquePaths $filesAdded, $filesModified, $filesDeleted, $filesUnmerged)
        $index = (, $indexPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $indexAdded.ToArray() |
            Add-Member -Force -PassThru NoteProperty Modified $indexModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $indexDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $indexUnmerged.ToArray()

        $working = (, $workingPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $filesAdded |
            Add-Member -Force -PassThru NoteProperty Modified $filesModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $filesDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $filesUnmerged.ToArray()

        $result = New-Object PSObject -Property @{
            GitDir       = $GitDir
            RepoName     = Split-Path (Split-Path $GitDir -Parent) -Leaf
            Branch       = $branch
            AheadBy      = $aheadBy
            BehindBy     = $behindBy
            UpstreamGone = $gone
            Upstream     = $upstream
            HasIndex     = [bool]$index
            Index        = $index
            HasWorking   = [bool]$working
            Working      = $working
            HasUntracked = [bool]$filesAdded
            StashCount   = $stashCount
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
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $res = "$currentPath$separator".StartsWith("$GitDir$separator", (Get-PathStringComparison))
    $res
}

function Get-AliasPattern($cmd) {
    $aliases = @($cmd) + @(Get-Alias | Where-Object { $_.Definition -match "^$cmd(\.exe)?$" } | Foreach-Object Name)
    "($($aliases -join '|'))"
}

<#
.SYNOPSIS
    Deletes the specified Git branches.
.DESCRIPTION
    Deletes the specified Git branches that have been merged into the commit specified by the Commit parameter (HEAD by default). You must either specify a branch name via the Name parameter, which accepts wildard characters, or via the Pattern parameter, which accepts a regular expression.

    The following branches are always excluded from deletion:

    * The current branch
    * develop
    * master

    The default set of excluded branches can be overridden with the ExcludePattern parameter.

    Consider always running this command FIRST with the WhatIf parameter. This will show you which branches will be deleted. This gives you a chance to adjust your branch name wildcard pattern or regular expression if you are using the Pattern parameter.

    IMPORTANT: Be careful using this command. Even though by default this command deletes only merged branches, most, if not all, of your historical branches have been merged. But that doesn't mean you want to delete them. That is why this command excludes `develop` and `master` by default. But you may use different names e.g. `development` or have other historical branches you don't want to delete. In these cases, you can either:

    * Specify a narrower branch name wildcard such as "user/$env:USERNAME/*".
    * Specify an updated ExcludeParameter e.g. '(^\*)|(^. (develop|master|v\d+)$)' which adds any branch matching the pattern 'v\d+' to the exclusion list.

    If necessary, you can delete the specified branches REGARDLESS of their merge status by using the IncludeUnmerged parameter. BE VERY CAREFUL using the IncludeUnmerged parameter together with the Force parameter, since you will not be given the opportunity to confirm each branch deletion.

    The following Git commands are executed by this command:

        git branch --merged $Commit |
            Where-Object { $_ -notmatch $ExcludePattern } |
            Where-Object { $_.Trim() -like $Name } |
            Foreach-Object { git branch --delete $_.Trim() }

    If the IncludeUnmerged parameter is specified, execution changes to:

        git branch |
            Where-Object { $_ -notmatch $ExcludePattern } |
            Where-Object { $_.Trim() -like $Name } |
            Foreach-Object { git branch --delete $_.Trim() }

    If the DeleteForce parameter is specified, the Foreach-Object changes to:

        Foreach-Object { git branch --delete --force $_.Trim() }

    If the Pattern parameter is used instead of the Name parameter, the second Where-Object changes to:

        Where-Object { $_ -match $Pattern }

    Recovering Deleted Branches

    If you wind up deleting a branch you didn't intend to, you can easily recover it with the info provided by Git during the delete. For instance, let's say you realized you didn't want to delete the branch 'feature/exp1'. In the output of this command, you should see a deletion entry for this branch that looks like:

        Deleted branch feature/exp1 (was 08f9000).

    To recover this branch, execute the following Git command:

        # git branch <branch-name> <sha1>
        git branch feature/exp1 08f9000
.EXAMPLE
    PS> Remove-GitBranch -Name "user/${env:USERNAME}/*" -WhatIf
    Shows the merged branches that would be deleted by the specified branch name without actually deleting. Remove the WhatIf parameter when you are happy with the list of branches that will be deleted.
.EXAMPLE
    PS> Remove-GitBranch "feature/*" -Force
    Deletes the merged branches that match the specified wildcard. Using the Force parameter skips all confirmation prompts. Name is a positional parameter. The first argument is assumed to be the value of the Name parameter.
.EXAMPLE
    PS> Remove-GitBranch "bugfix/*" -Force -DeleteForce
    Deletes the merged branches that match the specified wildcard. Using the Force parameter skips all confirmation prompts while the DeleteForce parameter uses the --force option in the underlying Git command.
.EXAMPLE
    PS> Remove-GitBranch -Pattern 'user/(dahlbyk|hillr)/.*'
    Deletes the merged branches that match the specified regular expression.
.EXAMPLE
    PS> Remove-GitBranch -Name * -ExcludePattern '(^\*)|(^. (develop|master|v\d+)$)'
    Deletes merged branches except the current branch, develop, master and branches that also match the pattern 'v\d+' e.g. v1, v1.0, v1.x. BE VERY CAREFUL SPECIYING SUCH A BROAD BRANCH NAME WILDCARD!
.EXAMPLE
    PS> Remove-GitBranch "feature/*" -IncludeUnmerged -WhatIf
    Shows the branches, both merged and unmerged, that match the specified wildcard that would be deleted without actually deleting them. Once you've verified the list of branches looks correct, remove the WhatIf parameter to actually delete the branches.
#>
function Remove-GitBranch {
    [CmdletBinding(DefaultParameterSetName = "Wildcard", SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        # Specifies a regular expression pattern for the branches that will be deleted. Certain branches are always excluded from deletion e.g. the current branch as well as the develop and master branches. See the ExcludePattern parameter to modify that pattern.
        [Parameter(Position = 0, Mandatory, ParameterSetName = "Wildcard")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        # Specifies a regular expression for the branches that will be deleted. Certain branches are always excluded from deletion e.g. the current branch as well as the develop and master branches. See the ExcludePattern parameter to modify that pattern.
        [Parameter(Position = 0, Mandatory, ParameterSetName = "Pattern")]
        [ValidateNotNull()]
        [string]
        $Pattern,

        # Specifies a regular expression used to exclude merged branches from being deleted. The default pattern excludes the current branch, develop and master branches.
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $ExcludePattern = '(^\*)|(^. (develop|master)$)',

        # Branches whose tips are reachable from the specified commit will be deleted. The default commit is HEAD. This parameter is ignored if the IncludeUnmerged parameter is specified.
        [Parameter()]
        [string]
        $Commit = "HEAD",

        # Specifies that unmerged branches are also eligible to be deleted.
        [Parameter()]
        [switch]
        $IncludeUnmerged,

        # Deletes the specified branches without prompting for confirmation. By default, Remove-GitBranch prompts for confirmation before deleting branches.
        [Parameter()]
        [switch]
        $Force,

        # Deletes the specified branches by adding the --force parameter to the git branch --delete command e.g. git branch --delete --force <branch-name>. This is also the equivalent of using the -D parameter on the git branch command.
        [Parameter()]
        [switch]
        $DeleteForce
    )

    if ($IncludeUnmerged) {
        $branches = git branch
    }
    else {
        $branches = git branch --merged $Commit
    }

    $filteredBranches = $branches | Where-Object { $_ -notmatch $ExcludePattern }

    if ($PSCmdlet.ParameterSetName -eq "Wildcard") {
        $branchesToDelete = $filteredBranches | Where-Object { $_.Trim() -like $Name }
    }
    else {
        $branchesToDelete = $filteredBranches | Where-Object { $_ -match $Pattern }
    }

    $action = if ($DeleteForce) { "delete with force" } else { "delete" }
    $yesToAll = $noToAll = $false

    foreach ($branch in $branchesToDelete) {
        $targetBranch = $branch.Trim()
        if ($PSCmdlet.ShouldProcess($targetBranch, $action)) {
            if ($Force -or $yesToAll -or
                $PSCmdlet.ShouldContinue(
                    "Are you REALLY sure you want to $action `"$targetBranch`"?",
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
