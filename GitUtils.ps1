# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

function Get-GitDirectory {
    if ($Env:GIT_DIR) {
        $Env:GIT_DIR
    }
    else {
        Get-LocalOrParentPath .git
    }
}

function Get-GitBranch($gitDir = $(Get-GitDirectory), [Diagnostics.Stopwatch]$sw) {
    if ($gitDir) {
        dbg 'Finding branch' $sw
        $r = ''; $b = ''; $c = ''
        if (Test-Path $gitDir\rebase-merge\interactive) {
            dbg 'Found rebase-merge\interactive' $sw
            $r = '|REBASE-i'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        }
        elseif (Test-Path $gitDir\rebase-merge) {
            dbg 'Found rebase-merge' $sw
            $r = '|REBASE-m'
            $b = "$(Get-Content $gitDir\rebase-merge\head-name)"
        }
        else {
            if (Test-Path $gitDir\rebase-apply) {
                dbg 'Found rebase-apply' $sw
                if (Test-Path $gitDir\rebase-apply\rebasing) {
                    dbg 'Found rebase-apply\rebasing' $sw
                    $r = '|REBASE'
                }
                elseif (Test-Path $gitDir\rebase-apply\applying) {
                    dbg 'Found rebase-apply\applying' $sw
                    $r = '|AM'
                }
                else {
                    dbg 'Found rebase-apply' $sw
                    $r = '|AM/REBASE'
                }
            }
            elseif (Test-Path $gitDir\MERGE_HEAD) {
                dbg 'Found MERGE_HEAD' $sw
                $r = '|MERGING'
            }
            elseif (Test-Path $gitDir\CHERRY_PICK_HEAD) {
                dbg 'Found CHERRY_PICK_HEAD' $sw
                $r = '|CHERRY-PICKING'
            }
            elseif (Test-Path $gitDir\BISECT_LOG) {
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

                        if (Test-Path $gitDir\HEAD) {
                            dbg 'Reading from .git\HEAD' $sw
                            $ref = Get-Content $gitDir\HEAD 2>$null
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

        "$c$($b -replace 'refs/heads/','')$r"
    }
}

function GetUniquePaths([System.Collections.Generic.IEnumerable[string][]] $pathCollections) {
    $hash = New-Object System.Collections.Specialized.OrderedDictionary

    foreach ($pathCollection in $pathCollections) {
        foreach ($path in $pathCollection) {
            $hash[$path] = 1
        }
    }

    $hash.Keys
}

function Get-GitStatus($gitDir = (Get-GitDirectory)) {
    $settings = $Global:GitPromptSettings
    $enabled = (-not $settings) -or $settings.EnablePromptStatus
    if ($enabled -and $gitDir) {
        if($settings.Debug) {
            $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
        }
        else {
            $sw = $null
        }

        $branch = $null
        $aheadBy = 0
        $behindBy = 0
        $indexAdded = New-Object System.Collections.Generic.List[string]
        $indexModified = New-Object System.Collections.Generic.List[string]
        $indexDeleted = New-Object System.Collections.Generic.List[string]
        $indexUnmerged = New-Object System.Collections.Generic.List[string]
        $filesAdded = New-Object System.Collections.Generic.List[string]
        $filesModified = New-Object System.Collections.Generic.List[string]
        $filesDeleted = New-Object System.Collections.Generic.List[string]
        $filesUnmerged = New-Object System.Collections.Generic.List[string]
        $stashCount = 0

        if($settings.EnableFileStatus -and !$(InDisabledRepository)) {
            dbg 'Getting status' $sw
            $status = git -c color.status=false status --short --branch 2>$null
            if($settings.EnableStashStatus) {
                dbg 'Getting stash count' $sw
                $stashCount = $null | git stash list 2>$null | measure-object | Select-Object -expand Count
            }
        }
        else {
            $status = @()
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

            '^## (?<branch>\S+?)(?:\.\.\.(?<upstream>\S+))?(?: \[(?:ahead (?<ahead>\d+))?(?:, )?(?:behind (?<behind>\d+))?\])?$' {
                if ($sw) { dbg "Status: $_" $sw }

                $branch = $matches['branch']
                $upstream = $matches['upstream']
                $aheadBy = [int]$matches['ahead']
                $behindBy = [int]$matches['behind']
                continue
            }

            '^## Initial commit on (?<branch>\S+)$' {
                if ($sw) { dbg "Status: $_" $sw }

                $branch = $matches['branch']
                continue
            }

            default { if ($sw) { dbg "Status: $_" $sw } }

        }

        if(!$branch) { $branch = Get-GitBranch $gitDir $sw }

        dbg 'Building status object' $sw
        #
        # This collection is used twice, so create the array just once
        $filesAdded = $filesAdded.ToArray()

        $indexPaths = @(GetUniquePaths $indexAdded,$indexModified,$indexDeleted,$indexUnmerged)
        $workingPaths = @(GetUniquePaths $filesAdded,$filesModified,$filesDeleted,$filesUnmerged)
        $index = Write-Output -NoEnumerate $indexPaths |
            Add-Member -PassThru NoteProperty Added    $indexAdded.ToArray() |
            Add-Member -PassThru NoteProperty Modified $indexModified.ToArray() |
            Add-Member -PassThru NoteProperty Deleted  $indexDeleted.ToArray() |
            Add-Member -PassThru NoteProperty Unmerged $indexUnmerged.ToArray()

        $working = Write-Output -NoEnumerate $workingPaths|
            Add-Member -PassThru NoteProperty Added    $filesAdded |
            Add-Member -PassThru NoteProperty Modified $filesModified.ToArray() |
            Add-Member -PassThru NoteProperty Deleted  $filesDeleted.ToArray() |
            Add-Member -PassThru NoteProperty Unmerged $filesUnmerged.ToArray()

        $result = New-Object PSObject -Property @{
            GitDir          = $gitDir
            Branch          = $branch
            AheadBy         = $aheadBy
            BehindBy        = $behindBy
            Upstream        = $upstream
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
            StashCount      = $stashCount
        }

        dbg 'Finished' $sw
        if($sw) { $sw.Stop() }
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

function Enable-GitColors {
    Write-Warning 'Enable-GitColors is Obsolete and will be removed in a future version of posh-git.'
}

function Get-AliasPattern($exe) {
   $aliases = @($exe) + @(Get-Alias | Where-Object { $_.Definition -eq $exe } | Select-Object -Exp Name)
   "($($aliases -join '|'))"
}

function setenv($key, $value) {
    [void][Environment]::SetEnvironmentVariable($key, $value)
    Set-TempEnv $key $value
}

function Get-TempEnv($key) {
    $path = Get-TempEnvPath($key)
    if (Test-Path $path) {
        $value =  Get-Content $path
        [void][Environment]::SetEnvironmentVariable($key, $value)
    }
}

function Set-TempEnv($key, $value) {
    $path = Get-TempEnvPath($key)
    if ($value -eq $null) {
        if (Test-Path $path) {
            Remove-Item $path
        }
    }
    else {
        New-Item $path -Force -ItemType File > $null
        $value | Out-File -FilePath $path -Encoding ascii -Force
    }
}

function Get-TempEnvPath($key){
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ".ssh\$key.env"
    return $path
}

# Retrieve the current SSH agent PID (or zero). Can be used to determine if there
# is a running agent.
function Get-SshAgent() {
    if ($env:GIT_SSH -imatch 'plink') {
        $pageantPid = Get-Process | Where-Object { $_.Name -eq 'pageant' } | Select-Object -ExpandProperty Id -First 1
        if ($null -ne $pageantPid) { return $pageantPid }
    }
    else {
        $agentPid = $Env:SSH_AGENT_PID
        if ($agentPid) {
            $sshAgentProcess = Get-Process | Where-Object { ($_.Id -eq $agentPid) -and ($_.Name -eq 'ssh-agent') }
            if ($null -ne $sshAgentProcess) {
                return $agentPid
            }
            else {
                setenv 'SSH_AGENT_PID' $null
                setenv 'SSH_AUTH_SOCK' $null
            }
        }
    }

    return 0
}

# Attempt to guess Pageant's location
function Find-Pageant() {
    Write-Verbose "Pageant not in path. Trying to guess location."

    $gitSsh = $env:GIT_SSH
    if ($gitSsh -and (test-path $gitSsh)) {
        $pageant = join-path (split-path $gitSsh) pageant
    }

    if (!(get-command $pageant -Erroraction SilentlyContinue)) {
        return # Guessing failed.
    }
    else {
        return $pageant
    }
}

# Attempt to guess $program's location. For ssh-agent/ssh-add.
function Find-Ssh($program = 'ssh-agent') {
    Write-Verbose "$program not in path. Trying to guess location."
    $gitItem = Get-Command git -Erroraction SilentlyContinue | Get-Item
    if ($gitItem -eq $null) {
        Write-Warning 'git not in path'
        return
    }

    $sshLocation = join-path $gitItem.directory.parent.fullname bin/$program
    if (get-command $sshLocation -Erroraction SilentlyContinue) {
        return $sshLocation
    }

    $sshLocation = join-path $gitItem.directory.parent.fullname usr/bin/$program
    if (get-command $sshLocation -Erroraction SilentlyContinue) {
        return $sshLocation
    }
}

# Loosely based on bash script from http://help.github.com/ssh-key-passphrases/
function Start-SshAgent([switch]$Quiet) {
    [int]$agentPid = Get-SshAgent
    if ($agentPid -gt 0) {
        if (!$Quiet) {
            $agentName = Get-Process -Id $agentPid | Select-Object -ExpandProperty Name
            if (!$agentName) { $agentName = "SSH Agent" }
            Write-Host "$agentName is already running (pid $($agentPid))"
        }
        return
    }

    if ($env:GIT_SSH -imatch 'plink') {
        Write-Host "GIT_SSH set to $($env:GIT_SSH), using Pageant as SSH agent."

        $pageant = Get-Command pageant -TotalCount 1 -Erroraction SilentlyContinue
        $pageant = if ($pageant) { $pageant } else { Find-Pageant }
        if (!$pageant) {
            Write-Warning "Could not find Pageant."
            return
        }

        Start-Process -NoNewWindow $pageant
    }
    else {
        $sshAgent = Get-Command ssh-agent -TotalCount 1 -ErrorAction SilentlyContinue
        $sshAgent = if ($sshAgent) { $sshAgent } else { Find-Ssh('ssh-agent') }
        if (!$sshAgent) {
            Write-Warning 'Could not find ssh-agent'
            return
        }

        & $sshAgent | ForEach-Object {
            if ($_ -match '(?<key>[^=]+)=(?<value>[^;]+);') {
                setenv $Matches['key'] $Matches['value']
            }
        }
    }

    Add-SshKey
}

function Get-SshPath($File = 'id_rsa')
{
    $home = Resolve-Path (Invoke-NullCoalescing $Env:HOME ~)
    Resolve-Path ([io.path]::combine($home, '.ssh', $File))
}

<#
.SYNOPSIS
    Add a key to the SSH agent
.DESCRIPTION
    Adds one or more SSH keys to the SSH agent.
.EXAMPLE
    PS C:\> Add-SshKey
    Adds ~\.ssh\id_rsa to the SSH agent.
.EXAMPLE
    PS C:\> Add-SshKey ~\.ssh\mykey, ~\.ssh\myotherkey
    Adds ~\.ssh\mykey and ~\.ssh\myotherkey to the SSH agent.
.INPUTS
    None.
    You cannot pipe input to this cmdlet.
#>
function Add-SshKey() {
    if ($env:GIT_SSH -imatch 'plink') {
        $pageant = Get-Command pageant -Erroraction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name
        $pageant = if ($pageant) { $pageant } else { Find-Pageant }
        if (!$pageant) {
            Write-Warning 'Could not find Pageant'
            return
        }

        if ($args.Count -eq 0) {
            $keystring = ""
            $keyPath = Join-Path $Env:HOME ".ssh"
            $keys = Get-ChildItem $keyPath/"*.ppk" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
            & $pageant $keys
        }
        else {
            foreach ($value in $args) {
                & $pageant $value
            }
        }
    }
    else {
        $sshAdd = Get-Command ssh-add -TotalCount 1 -ErrorAction SilentlyContinue
        $sshAdd = if ($sshAdd) { $sshAdd } else { Find-Ssh('ssh-add') }
        if (!$sshAdd) {
            Write-Warning 'Could not find ssh-add'
            return
        }

        if ($args.Count -eq 0) {
            & $sshAdd
        }
        else {
            foreach ($value in $args) {
                & $sshAdd $value
            }
        }
    }
}

# Stop a running SSH agent
function Stop-SshAgent() {
    [int]$agentPid = Get-SshAgent
    if ($agentPid -gt 0) {
        # Stop agent process
        $proc = Get-Process -Id $agentPid -ErrorAction SilentlyContinue
        if ($proc -ne $null) {
            Stop-Process $agentPid
        }

        setenv 'SSH_AGENT_PID' $null
        setenv 'SSH_AUTH_SOCK' $null
    }
}

function Update-AllBranches($Upstream = 'master', [switch]$Quiet) {
    $head = git rev-parse --abbrev-ref HEAD
    git checkout -q $Upstream
    $branches = (git branch --no-color --no-merged) | Where-Object { $_ -notmatch '^\* ' }
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
