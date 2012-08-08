function Start-GitPrompt([switch] $Asynchronous) {
    if (-not $GitPromptState) {
        if ($Asynchronous) {
            $timer = New-Object Timers.Timer -Property @{
                Interval = 250
                AutoReset = $true
                Enabled = $true
            }
            Set-Variable GitPromptState -Scope Global -Value (New-Object PSObject -Property @{
                Asynchronous = $true
                Repositories = @{ }
                Timer = $timer
                Elapsed = Register-ObjectEvent $timer Elapsed -Action { Update-GitPromptRepositories }
            })
        }
        else {
            Set-Variable GitPromptState -Scope Global -Value (New-Object PSObject -Property @{
                Asynchronous = $false
                Repositories = @{ }
            })
        }
    }
}

function Update-GitPromptRepositories {
    if ($GitPromptState) {
        $repositories = $GitPromptState.Repositories
        foreach($key in $repositories.Keys) {
            $repository = $repositories[$key]
            if ($repository.LastStatusUpdate -lt $repository.LastUpdate) {
                if ($repository.LastStatusUpdate.AddMilliseconds($repository.StatusUpdateIntervalBuffer) -lt [DateTime]::Now) {
                    Push-Location $repository.Path
                    try { $repository.Status = Get-GitStatus $repository.Path }
                    finally { Pop-Location }
                }
                $repository.LastStatusUpdate = [DateTime]::Now
            }
        }
    }
}

function Stop-GitPrompt {
    if ($GitPromptState) {
        if ($GitPromptState.Asynchronous) {
            $GitPromptState.Timer.Enabled = $false
            Unregister-Event $GitPromptState.Elapsed.Id
        }
        $GitPromptState.Repositories.Keys | ForEach-Object { Stop-GitPromptRepository $_ }
        Remove-Variable GitPromptState -Scope Global
    }
}

function Start-GitPromptRepository($Path) {
    if ($GitPromptState -and (-not $GitPromptState.Repositories.ContainsKey($Path))) {
        $repositories = $GitPromptState.Repositories.Clone()
        $watcher = New-Object IO.FileSystemWatcher $Path, '*.*' -Property @{
            IncludeSubdirectories = $true
            EnableRaisingEvents = $true
        }
        $watcherAction = [scriptblock]::Create( { Publish-GitPromptRepositoryUpdated $Path $eventArgs.Name }.ToString().Replace('$Path', $Path) )

        $repositories[$Path] = New-Object PSObject -Property @{
            Path = $Path
            Status = (Get-GitStatus $Path)
            StatusUpdateIntervalBuffer = 500
            LastStatusUpdate = ([DateTime]::Now)
            LastUpdate = ([DateTime]::Now)
            Watcher = $watcher
            Changed = Register-ObjectEvent $watcher Changed -Action $watcherAction
            Created = Register-ObjectEvent $watcher Created -Action $watcherAction
            Deleted = Register-ObjectEvent $watcher Deleted -Action $watcherAction
            Renamed = Register-ObjectEvent $watcher Renamed -Action $watcherAction
            Ignore = @('^\.git$', '^\.git\\index\.lock$', '^\.git\\objects\\')
        }
        $GitPromptState.Repositories = $repositories
    }
}

function Publish-GitPromptRepositoryUpdated($Path, $File) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($Path)) {
        $repository = $GitPromptState.Repositories.Get_Item($Path)
        if ($repository.Ignore | Where-Object { $File -match $_ }) { return }
        $repository.LastUpdate = [DateTime]::Now
    }
}

function Stop-GitPromptRepository($Path) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($Path)) {
        $repository = $GitPromptState.Repositories[$Path]
        $repository.Watcher.EnableRaisingEvents = $false
        Unregister-Event $repository.Changed.Id
        Unregister-Event $repository.Created.Id
        Unregister-Event $repository.Deleted.Id
        Unregister-Event $repository.Renamed.Id

        $repositories = $GitPromptState.Repositories.Clone()
        $repositories.Remove($Path)
        $GitPromptState.Repositories = $repositories
    }
}

function Update-GitPromptRepository($Path) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($Path) -and (-not $GitPromptState.Asynchronous)) {
        $repository = $GitPromptState.Repositories[$Path]
        if ($repository.LastStatusUpdate -lt $repository.LastUpdate) {
            Push-Location $repository.Path
            try { $repository.Status = Get-GitStatus $repository.Path }
            finally { Pop-Location }
            $repository.LastStatusUpdate = [DateTime]::Now
        }
    }
}

function Get-GitPromptStatus {
    $Path = Get-GitDirectory
    if ($Path) {
        $repositoryPath = Split-Path -parent $Path
        if ($GitPromptState) {
            if ($GitPromptState.Repositories.ContainsKey($repositoryPath)) {
                Update-GitPromptRepository $repositoryPath
            }
            else {
                Start-GitPromptRepository $repositoryPath
            }
            $GitPromptState.Repositories[$repositoryPath].Status
        }
        else {
            Get-GitStatus $Path
        }
    }
}