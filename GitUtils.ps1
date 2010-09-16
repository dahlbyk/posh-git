# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

function Get-GitDirectory {
    Get-LocalOrParentPath .git
}

function Get-GitBranch($gitDir = $(Get-GitDirectory)) {
    if ($gitDir) {
        $r = ''; $b = ''; $c = ''
        if (Test-Path $gitDir\rebase-merge\interactive) {
            $r = '|REBASE-i'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        } elseif (Test-Path $gitDir\rebase-merge) {
            $r = '|REBASE-m'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        } else {
            if (Test-Path $gitDir\rebase-apply) {
                if (Test-Path $gitDir\rebase-apply\rebasing) {
                    $r = '|REBASE'
                } elseif (Test-Path $gitDir\rebase-apply\applying) {
                    $r = '|AM'
                } else {
                    $r = '|AM/REBASE'
                }
            } elseif (Test-Path $gitDir\MERGE_HEAD) {
                $r = '|MERGING'
            } elseif (Test-Path $gitDir\BISECT_LOG) {
                $r = '|BISECTING'
            }

            $b = ?? { git symbolic-ref HEAD 2>$null } `
                    { "($(
                        Coalesce-Args `
                            { git describe --exact-match HEAD 2>$null } `
                            {
                                $ref = Get-Content $gitDir\HEAD 2>$null
                                if ($ref -and $ref.Length -ge 7) {
                                    return $ref.Substring(0,7)+'...'
                                } else {
                                    return $null
                                }
                            } `
                            'unknown'
                    ))" }
        }

        if ('true' -eq $(git rev-parse --is-inside-git-dir 2>$null)) {
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
        $branch = Get-GitBranch $gitDir
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
            $status = git status --short --branch 2>$null
        } else {
            $status = @()
        }

        $status | where { $_ } | foreach {
            switch -regex ($_) {
                '^## (?<branch>\S+)(?:\.\.\.(?<upstream>\S+) \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?\])?$' {
                    $upstream = $matches['upstream']
                    $aheadBy = [int]$matches['ahead']
                    $behindBy = [int]$matches['behind']
                }
                
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
            }
        }

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
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
        }

        return $result
    }
}

function Enable-GitColors {
    $env:TERM = 'cygwin'
    $env:LESS = 'FRSX'
}
