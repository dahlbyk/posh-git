function IsNotCurrentLocal-GitBranch($branch) {
    !$branch.StartsWith("*")
}

function Select-RemoteBranch($remoteName) {
    PROCESS
    {
        if ($_ -match "^(.*?)/(.*)$") {
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

function Get-MergedRemoteBranches($remoteName) {
    $current = Get-GitBranch
    $branches = git branch -r --merged
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed `
        | where {!$_.Contains("/HEAD ->")} `
        | Select-RemoteBranch $remoteName `
        | where {$_.BranchName -ne $current}
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
    $branches = Get-MergedRemoteBranches $remoteName `
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