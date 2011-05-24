# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

function Get-GitDirectory {
    Get-LocalOrParentPath .git
}

function Get-GitBranch($gitDir = $(Get-GitDirectory), [Diagnostics.Stopwatch]$sw) {
    if ($gitDir) {
        dbg 'Finding branch' $sw
        $r = ''; $b = ''; $c = ''
        if (Test-Path $gitDir\rebase-merge\interactive) {
            dbg 'Found rebase-merge\interactive' $sw
            $r = '|REBASE-i'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        } elseif (Test-Path $gitDir\rebase-merge) {
            dbg 'Found rebase-merge' $sw
            $r = '|REBASE-m'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        } else {
            if (Test-Path $gitDir\rebase-apply) {
                dbg 'Found rebase-apply' $sw
                if (Test-Path $gitDir\rebase-apply\rebasing) {
                    dbg 'Found rebase-apply\rebasing' $sw
                    $r = '|REBASE'
                } elseif (Test-Path $gitDir\rebase-apply\applying) {
                    dbg 'Found rebase-apply\applying' $sw
                    $r = '|AM'
                } else {
                    dbg 'Found rebase-apply' $sw
                    $r = '|AM/REBASE'
                }
            } elseif (Test-Path $gitDir\MERGE_HEAD) {
                dbg 'Found MERGE_HEAD' $sw
                $r = '|MERGING'
            } elseif (Test-Path $gitDir\BISECT_LOG) {
                dbg 'Found BISECT_LOG' $sw
                $r = '|BISECTING'
            }

            $b = '({0})' -f (
                Coalesce-Args `
                    { dbg 'Trying describe' $sw; git describe --exact-match HEAD 2>$null } `
                    {
                        dbg 'Falling back on parsing HEAD' $sw
                        $ref = Get-Content $gitDir\HEAD 2>$null
                        if ($ref -match 'ref: (?<ref>.+)') {
                            return $Matches['ref']
                        } elseif ($ref -and $ref.Length -ge 7) {
                            return $ref.Substring(0,7)+'...'
                        } else {
                            return 'unknown'
                        }
                    }
                )
        }

        if ('true' -eq $(git rev-parse --is-inside-git-dir 2>$null)) {
            dbg 'Inside git directory' $sw
            if ('true' -eq $(git rev-parse --is-bare-repository 2>$null)) {
                $c = 'BARE:'
            } else {
                $b = 'GIT_DIR!'
            }
        }

        "$c$($b -replace 'refs/heads/','')$r"
    }
}

function Get-GitStatus($gitDir = (Get-GitDirectory)) {
    $settings = $Global:GitPromptSettings
    $enabled = (-not $settings) -or $settings.EnablePromptStatus
    if ($enabled -and $gitDir)
    {
        if($settings.Debug) { $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host '' }
        $branch = $null
        $aheadBy = 0
        $behindBy = 0
        $indexAdded = @()
        $indexModified = @()
        $indexDeleted = @()
        $indexUnmerged = @()
        $filesAdded = @()
        $filesModified = @()
        $filesDeleted = @()
        $filesUnmerged = @()

        if($settings.EnableFileStatus) {
            dbg 'Getting status' $sw
            $status = git status --short --branch 2>$null
        } else {
            $status = @()
        }

        dbg 'Parsing status' $sw
        $status | foreach {
            dbg "Status: $_" $sw
            if($_) {
                switch -regex ($_) {
                    '^(?<index>[^#])(?<working>.) (?<path1>.*?)(?: -> (?<path2>.*))?$' {
                        switch ($matches['index']) {
                            'A' { $indexAdded += $matches['path1'] }
                            'M' { $indexModified += $matches['path1'] }
                            'R' { $indexModified += $matches['path1'] }
                            'C' { $indexModified += $matches['path1'] }
                            'D' { $indexDeleted += $matches['path1'] }
                            'U' { $indexUnmerged += $matches['path1'] }
                        }
                        switch ($matches['working']) {
                            '?' { $filesAdded += $matches['path1'] }
                            'A' { $filesAdded += $matches['path1'] }
                            'M' { $filesModified += $matches['path1'] }
                            'D' { $filesDeleted += $matches['path1'] }
                            'U' { $filesUnmerged += $matches['path1'] }
                        }
                    }

                    '^## (?<branch>\S+)(?:\.\.\.(?<upstream>\S+) \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?\])?$' {
                        $branch = $matches['branch']
                        $upstream = $matches['upstream']
                        $aheadBy = [int]$matches['ahead']
                        $behindBy = [int]$matches['behind']
                    }

                    '^## Initial commit on (?<branch>\S+)$' {
                        $branch = $matches['branch']
                    }
                }
            }
        }

        if(!$branch) { $branch = Get-GitBranch $gitDir $sw }
        dbg 'Building status object' $sw
        $indexPaths = $indexAdded + $indexModified + $indexDeleted + $indexUnmerged
        $workingPaths = $filesAdded + $filesModified + $filesDeleted + $filesUnmerged
        $index = New-Object PSObject @(,@($indexPaths | ?{ $_ } | Select -Unique)) |
            Add-Member -PassThru NoteProperty Added    $indexAdded |
            Add-Member -PassThru NoteProperty Modified $indexModified |
            Add-Member -PassThru NoteProperty Deleted  $indexDeleted |
            Add-Member -PassThru NoteProperty Unmerged $indexUnmerged
        $working = New-Object PSObject @(,@($workingPaths | ?{ $_ } | Select -Unique)) |
            Add-Member -PassThru NoteProperty Added    $filesAdded |
            Add-Member -PassThru NoteProperty Modified $filesModified |
            Add-Member -PassThru NoteProperty Deleted  $filesDeleted |
            Add-Member -PassThru NoteProperty Unmerged $filesUnmerged

        $result = New-Object PSObject -Property @{
            GitDir          = $gitDir
            Branch          = $branch
            AheadBy         = $aheadBy
            BehindBy        = $behindBy
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
        }

        dbg 'Finished' $sw
        if($sw) { $sw.Stop() }
        return $result
    }
}

function Enable-GitColors {
    $env:TERM = 'cygwin'
}

function Get-GitAliasPattern {
   $aliases = @('git') + (Get-Alias | where {$_.definition -eq 'git' } | select -Exp Name) -join '|' 
   "(" + $aliases + ")"
}

