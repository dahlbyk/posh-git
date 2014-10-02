function IsNotCurrentOrIgnoredLocal-GitBranch($branch)
{
    $ignored = "master", "develop"
    !$branch.StartsWith("*") -and !$ignored.Contains($branch)
}

function TrimRemote-GitBranch($branch)
{
    $branch -replace "^(.*?)/(.*)$", "`$2"
}

function IsNotCurrentOrIgnoredRemote-GitBranch($branch)
{
    $ignored = "master", "develop"
    if ($branch.Contains("/HEAD ->"))
    {
        return $false
    }

    $branchName = TrimRemote-GitBranch $branch
    return !$ignored.Contains($branchName)
}

function Get-MergedLocalGitBranches
{
    $branches = git branch --merged
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed | where {IsNotCurrentOrIgnoredLocal-GitBranch $_}
}

function Get-MergedRemoteBranches
{
    $branches = git branch -r --merged
    $trimmed = $branches | foreach {$_.Trim()}
    $filtered = $trimmed | where {IsNotCurrentOrIgnoredRemote-GitBranch $_}
    return $filtered | foreach {TrimRemote-GitBranch $_}
}

function Remove-MergedLocalGitBranches
{
    $branches = Get-MergedLocalGitBranches
    if ($branches.Length -eq 0)
    {
        Write-Host "No local merged branches"
        return
    }

    Write-Host "Start deleting local merged branches"
    Write-Host
    
    foreach ($item in $branches)
    {
        Write-Host "Deleting branch $item..."
        git branch -d $trimmed
        Write-Host
    }
    Write-Host "Finish deleting local merged branches"
}

function Remove-MergedRemoteGitBranches
{
    $branches = Get-MergedRemoteBranches
    if ($branches.Length -eq 0)
    {
        Write-Host "No remote merged branches"
        return
    }

    Write-Host "Start deleting remote merged branches"
    Write-Host
    
    foreach ($item in $branches)
    {
        Write-Host "Deleting branch $item..."
        git push origin :$branch
        Write-Host
    }
    Write-Host "Finish deleting remote merged branches"
}

function Remove-MergedGitBranches
{
    Remove-MergedLocalGitBranches
    Write-Host
    Remove-MergedRemoteGitBranches
}