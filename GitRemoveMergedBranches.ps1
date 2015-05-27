function IsNotCurrentLocal-GitBranch($branch) {
    !$branch.StartsWith("*")
}

function Select-RemoteBranch($remoteName) {
    PROCESS
    {
        $trimmed = $_.Trim()
        if ($trimmed -match "^(.*?)/(.*)$" -and !$trimmed.Contains('/HEAD ->')) {
            if (!$remoteName -or $Matches[1] -in $remoteName) {
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

function Get-MergedRemoteBranches($target) {
    $targetInfo = $target | Select-RemoteBranch | select -First 1

    if ($targetInfo -ne $null) {
        $allMerged = git branch -r --merged $targetInfo.FullName
        $allMerged `
            | Select-RemoteBranch $targetInfo.RemoteName `
            | where {$_.FullName -ne $targetInfo.FullName} `
            | foreach {write $_}
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

function Remove-MergedRemoteGitBranches {
    [CmdletBinding()]
    Param(
        [string[]]
        $RemoteBranch
    )

    foreach ($target in $RemoteBranch) {
        $merged = Get-MergedRemoteBranches $target | where {$_ -notin $Global:GitPromptSettings.MergedBranchesToKeep}
        if ($merged.Length -eq 0) {
            Write-Host "No remote merged branches for $target"
            continue
        }

        foreach ($branch in $merged) {
            if ($PSCmdlet.ShouldProcess($branch.FullName, "delete remote branch")) {
                git push $branch.RemoteName :$($branch.BranchName)
            }
        }
    }
}

function Remove-MergedGitBranches() {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Switch]
        $Local,

        [string[]]
        $RemoteBranch
    )

    if (!$PSBoundParameters.ContainsKey('Local') -and !$PSBoundParameters.ContainsKey('RemoteBranch')) {
        $Local = $true;
    }
    if ($Local) {
        Remove-MergedLocalGitBranches
    }
    if ($RemoteBranch.Length -gt 0) {
        Remove-MergedRemoteGitBranches $RemoteBranch
    }
}