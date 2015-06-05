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

function Get-MergedLocalGitBranches($target) {
    $branches = git branch --merged $target
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed | where {IsNotCurrentLocal-GitBranch $_}
}

function Get-MergedRemoteBranches($remote, $branch) {
    $targetBranch = "$remote/$branch"

    $allMerged = git branch -r --merged $targetBranch
    $allMerged `
        | Select-RemoteBranch $remote `
        | where {$_.FullName -ne $targetBranch} `
        | foreach {write $_}
}

function Remove-MergedLocalGitBranches($target) {
    $branches = Get-MergedLocalGitBranches $target `
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
    Param(
        [string[]]
        $Remote,

        [string]
        $Target
    )

    foreach ($remoteName in $Remote) {
        $targetBranch = "$remoteName/$Target"
        $exists = git rev-parse --verify --quiet $targetBranch
        if (!$exists) {
            Write-Warning "$targetBranch not exists"
            continue
        }

        $merged = Get-MergedRemoteBranches $remoteName $Target `
            | where {$_.BranchName -notin $Global:GitPromptSettings.MergedBranchesToKeep}
        if ($merged.Length -eq 0) {
            Write-Host "No remote merged branches for $targetBranch"
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
        $Remote,

        [parameter(Position=0)]
        [string]
        $Target = "HEAD"
    )

    if (!$PSBoundParameters.ContainsKey('Local') -and !$PSBoundParameters.ContainsKey('Remote')) {
        $Local = $true;
    }
    if ($Local) {
        Remove-MergedLocalGitBranches $Target
    }
    if ($Remote.Length -gt 0) {
        Remove-MergedRemoteGitBranches -Remote $Remote -Target $Target
    }
}