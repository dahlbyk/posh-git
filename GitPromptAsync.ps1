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
                    $repository.Status = (Get-GitStatus $repository.Path)
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

function Start-GitPromptRepository($path) {
    if ($GitPromptState -and (-not $GitPromptState.Repositories.ContainsKey($path))) {
        $repositories = $GitPromptState.Repositories.Clone()
        $watcher = New-Object IO.FileSystemWatcher $path, '*.*' -Property @{
            IncludeSubdirectories = $true
            EnableRaisingEvents = $true
        }
        $watcherAction = [scriptblock]::Create( { Publish-GitPromptRepositoryUpdated $path $eventArgs.Name }.ToString().Replace('$path', $path) )

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
        $GitPromptState.Repositories = $repositories
    }
}

function Publish-GitPromptRepositoryUpdated($path, $file) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($path)) {
        $repository = $GitPromptState.Repositories.Get_Item($path)
        if ($repository.Ignore | Where-Object { $file -match $_ }) { return }
        $repository.LastUpdate = [DateTime]::Now
    }
}

function Stop-GitPromptRepository($path) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($path)) {
        $repository = $GitPromptState.Repositories[$path]
        $repository.Watcher.EnableRaisingEvents = $false
        Unregister-Event $repository.Changed.Id
        Unregister-Event $repository.Created.Id
        Unregister-Event $repository.Deleted.Id
        Unregister-Event $repository.Renamed.Id

        $repositories = $GitPromptState.Repositories.Clone()
        $repositories.Remove($path)
        $GitPromptState.Repositories = $repositories
    }
}

function Update-GitPromptRepository($path) {
    if ($GitPromptState -and $GitPromptState.Repositories.ContainsKey($path) -and (-not $GitPromptState.Asynchronous)) {
		$repository = $GitPromptState.Repositories[$path]
		if ($repository.LastStatusUpdate -lt $repository.LastUpdate) {
			$repository.Status = Get-GitStatus $repository.Path
			$repository.LastStatusUpdate = [DateTime]::Now
		}
	}
}

function Get-GitPromptStatus {
    $path = Get-GitDirectory
    if ($path) {
		$repositoryPath = Split-Path -parent $path
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
            Get-GitStatus $path
        }
    }
}