function Start-GitPrompt {
    if (-not $AsynchronousGitPrompt) {
        $timer = New-Object Timers.Timer -Property @{
            Interval = 250
            AutoReset = $true
            Enabled = $true
        }
        Set-Variable AsynchronousGitPrompt -Scope Global -Value (New-Object PSObject -Property @{
            Repositories = @{ }
            Timer = $timer
            Elapsed = Register-ObjectEvent $timer Elapsed -Action { Update-GitPromptRepositories }
        })
    }
}

function Update-GitPromptRepositories {
    if ($AsynchronousGitPrompt) {
        $repositories = $AsynchronousGitPrompt.Repositories
        foreach($key in $repositories.Keys) {
            $repository = $repositories[$key]
            if ($repository.LastStatusUpdate -lt $repository.LastUpdate) {
                if ($repository.LastStatusUpdate.AddMilliseconds($repository.StatusUpdateIntervalBuffer) -lt [DateTime]::Now) {
                    $repository.Status = (Get-GitStatus $repository.Path)
                }
                $repository.LastStatusUpdate = [DateTime]::Now
            }
        }
    }
}

function Stop-GitPrompt {
    if ($AsynchronousGitPrompt) {
        $AsynchronousGitPrompt.Timer.Enabled = $false
        Unregister-Event $AsynchronousGitPrompt.Elapsed.Id
        $AsynchronousGitPrompt.Repositories.Keys | ForEach-Object { Stop-GitPromptRepository $_ }
        Remove-Variable AsynchronousGitPrompt -Scope Global
    }
}

function Start-GitPromptRepository($path) {
    if ($AsynchronousGitPrompt -and (-not $AsynchronousGitPrompt.Repositories.ContainsKey($path))) {
        $repositories = $AsynchronousGitPrompt.Repositories.Clone()
        $watcher = New-Object IO.FileSystemWatcher $path, '*.*' -Property @{
            IncludeSubdirectories = $true
            EnableRaisingEvents = $true
        }
        $watcherAction = [scriptblock]::Create( { Update-GitPromptRepository $path $eventArgs.Name }.ToString().Replace('$path', $path) )

        $repositories[$path] = New-Object PSObject -Property @{
            Path = $path
            Status = (Get-GitStatus $path)
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
        $AsynchronousGitPrompt.Repositories = $repositories
    }
}

function Update-GitPromptRepository($path, $file) {
    if ($AsynchronousGitPrompt -and $AsynchronousGitPrompt.Repositories.ContainsKey($path)) {
        $repository = $AsynchronousGitPrompt.Repositories.Get_Item($path)
        if ($repository.Ignore | where { $file -match $_ }) { return }
        $repository.LastUpdate = [DateTime]::Now
    }
}

function Stop-GitPromptRepository($path) {
    if ($AsynchronousGitPrompt -and $AsynchronousGitPrompt.Repositories.ContainsKey($path)) {
        $repository = $AsynchronousGitPrompt.Repositories[$path]
        $repository.Watcher.EnableRaisingEvents = $false
        Unregister-Event $repository.Changed.Id
        Unregister-Event $repository.Created.Id
        Unregister-Event $repository.Deleted.Id
        Unregister-Event $repository.Renamed.Id
        $repository.Update = $false

        $repositories = $AsynchronousGitPrompt.Repositories.Clone()
        $repositories.Remove($path)
        $AsynchronousGitPrompt.Repositories = $repositories
    }
}

function Get-GitPromptStatus {
    $path = Get-GitDirectory
    if ($path) {
        if ($AsynchronousGitPrompt) {
            $repositoryPath = Split-Path -parent $path
            Start-GitPromptRepository $repositoryPath
            $AsynchronousGitPrompt.Repositories[$repositoryPath].Status
        }
        else {
            Get-GitStatus $path
        }
    }
}