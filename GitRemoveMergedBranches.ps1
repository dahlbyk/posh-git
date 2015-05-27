function IsNotCurrentLocal-GitBranch($branch) {
    !$branch.StartsWith("*")
}

function Select-RemoteBranch($remoteName) {
    PROCESS
    {
        $trimmed = $_.Trim()
        if ($trimmed -match "^(.*?)/(.*)$" -and !$trimmed.Contains('/HEAD ->')) {
            if ($Matches[1] -in $remoteName) {
                $branchInfo = @{
                    RemoteName=$Matches[1];
                    BranchName=$Matches[2];
                    FullName=$Matches[0]
                }
                write (New-Object -TypeName PSObject -Property $branchInfo)
            }
        }
    }
}

function Get-MergedLocalGitBranches() {
    $branches = git branch --merged
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed | where {IsNotCurrentLocal-GitBranch $_}
}

function Get-MergedRemoteBranches {
    BEGIN
    {
        $current = Get-GitBranch
        $branches = git branch -r
    }

    PROCESS
    {
        $remote = $_
        $f = $branches | Select-RemoteBranch $remote
        $currentRemote = $f | where {$_.RemoteName -eq $remote -and $_.BranchName -eq $current}
        if ($currentRemote) {
            $merged = git branch -r --merged $currentRemote.FullName
            $merged | Select-RemoteBranch $remote | where {$_.BranchName -ne $current} | foreach {write $_}
        }
    }
}

function Remove-MergedLocalGitBranches {
    $branches = Get-MergedLocalGitBranches `
        | where {$_ -notin $Global:GitPromptSettings.MergedBranchesToKeep}
    if ($branches.Length -eq 0) {
        Write-Host "No local merged branches"
        return
    }

    foreach ($item in $branches) {
        if ($PSCmdlet.ShouldProcess($item, "delete branch")) {
            git branch -d $item
        }
    }
}

function Remove-MergedRemoteGitBranches($remoteName) {
    $branches = $remoteName | Get-MergedRemoteBranches `
        | where {$_ -notin $Global:GitPromptSettings.MergedBranchesToKeep}
    if ($branches.Length -eq 0) {
        Write-Host "No remote merged branches"
        return
    }

    foreach ($item in $branches) {
        if ($PSCmdlet.ShouldProcess($item.FullName, "delete remote branch")) {
            git push $item.RemoteName :$($item.BranchName)
        }
    }
}

function Remove-MergedGitBranches() {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Switch]
        $Local,

        [string[]]
        $Remote
    )

    if (!$PSBoundParameters.ContainsKey('Local') -and !$PSBoundParameters.ContainsKey('Remote')) {
        $Local = $true;
    }
    if ($Local) {
        Remove-MergedLocalGitBranches
    }
    if ($Remote.Length -gt 0) {
        Remove-MergedRemoteGitBranches $Remote
    }
}