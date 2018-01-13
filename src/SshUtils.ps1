#
# SshUtils.ps1
#

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
    if ($null -eq $value) {
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
    $gitItem = Get-Command git -CommandType Application -Erroraction SilentlyContinue | Get-Item
    if ($null -eq $gitItem) {
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
            if (!$Quiet) {
                Write-Warning 'Could not find Pageant'
            }
            return
        }

        Start-Process -NoNewWindow $pageant
    }
    else {
        $sshAgent = Get-Command ssh-agent -TotalCount 1 -ErrorAction SilentlyContinue
        $sshAgent = if ($sshAgent) { $sshAgent } else { Find-Ssh('ssh-agent') }
        if (!$sshAgent) {
            if (!$Quiet) {
                Write-Warning 'Could not find ssh-agent'
            }
            return
        }

        & $sshAgent | ForEach-Object {
            if ($_ -match '(?<key>[^=]+)=(?<value>[^;]+);') {
                setenv $Matches['key'] $Matches['value']
            }
        }
    }

    Add-SshKey -Quiet:$Quiet
}

function Get-SshPath($File = 'id_rsa') {
    # Avoid paths with path separator char since it is different on Linux/macOS.
    # Also avoid ~ as it is invalid if the user is cd'd into say cert:\ or hklm:\.
    # Also, apparently using the PowerShell built-in $HOME variable may not cut it for msysGit with has different
    # ideas about the path to the user's home dir e.g. /c/Users/Keith
    # $homePath = Invoke-NullCoalescing $Env:HOME $Home
    $homePath = if ($Env:HOME) {$Env:HOME} else {$Home}
    Join-Path $homePath (Join-Path .ssh $File)
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
function Add-SshKey([switch]$Quiet) {
    if ($env:GIT_SSH -imatch 'plink') {
        $pageant = Get-Command pageant -Erroraction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name
        $pageant = if ($pageant) { $pageant } else { Find-Pageant }
        if (!$pageant) {
            if (!$Quiet) {
                Write-Warning 'Could not find Pageant'
            }
            return
        }

        if ($args.Count -eq 0) {
            $keyPath = Join-Path $Env:HOME .ssh
            $keys = Get-ChildItem $keyPath/*.ppk -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
            if ($keys) {
                & $pageant $keys
            }
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
            if (!$Quiet) {
                Write-Warning 'Could not find ssh-add'
            }
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
        if ($null -ne $proc) {
            Stop-Process $agentPid
        }

        setenv 'SSH_AGENT_PID' $null
        setenv 'SSH_AUTH_SOCK' $null
    }
}

Get-TempEnv 'SSH_AGENT_PID'
Get-TempEnv 'SSH_AUTH_SOCK'
