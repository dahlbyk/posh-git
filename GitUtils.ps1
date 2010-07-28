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
    if ($gitDir)
    {
        $branch = ''
        $aheadBy = 0
        $indexAdded = @()
        $indexModified = @()
        $indexDeleted = @()
        $indexUnmerged = @()
        $filesAdded = @()
        $filesModified = @()
        $filesDeleted = @()
        $filesUnmerged = @()

        if ($global:GitPromptSettings.AutoRefreshIndex) {
            git update-index -q --refresh >$null 2>$null
        }

        $branch = Get-GitBranch $gitDir
        $aheadBy = (git cherry 2>$null | where { $_ -like '+*' } | Measure-Object).Count

        $diffIndex = git diff-index -M --name-status --no-ext-diff --ignore-submodules --cached HEAD |
                     ConvertFrom-CSV -Delim "`t" -Header 'Status','Path'
        $diffFiles = git diff-files -M --name-status --no-ext-diff --ignore-submodules |
                     ConvertFrom-CSV -Delim "`t" -Header 'Status','Path'

        $grpIndex = $diffIndex | Group-Object Status -AsHashTable
        $grpFiles = $diffFiles | Group-Object Status -AsHashTable

        if($grpIndex.A) { $indexAdded += $grpIndex.A | %{ $_.Path } }
        if($grpIndex.M) { $indexModified += $grpIndex.M | %{ $_.Path } }
        if($grpIndex.R) { $indexModified += $grpIndex.R | %{ $_.Path } }
        if($grpIndex.D) { $indexDeleted += $grpIndex.D | %{ $_.Path } }
        if($grpIndex.U) { $indexUnmerged += $grpIndex.U | %{ $_.Path } }
        if($grpFiles.M) { $filesModified += $grpFiles.M | %{ $_.Path } }
        if($grpFiles.R) { $filesModified += $grpFiles.R | %{ $_.Path } }
        if($grpFiles.D) { $filesDeleted += $grpFiles.D | %{ $_.Path } }
        if($grpIndex.U) { $filesUnmerged += $grpIndex.U | %{ $_.Path } }

        $filesAdded = @(git ls-files -o --exclude-standard 2>$null)

        $indexPaths = @($diffIndex | %{ $_.Path })
        $workingPaths = @($diffFiles | %{ $_.Path }) + $filesAdded
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

        $status = New-Object PSObject -Property @{
            GitDir          = $gitDir
            Branch          = $branch
            AheadBy         = $aheadBy
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
        }

        return $status
    }
}

function Enable-GitColors {
    $env:TERM = 'cygwin'
    $env:LESS = 'FRSX'
}
