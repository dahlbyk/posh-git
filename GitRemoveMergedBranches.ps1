function IsNotCurrentLocal-GitBranch($branch)
{
    !$branch.StartsWith("*")
}

function TrimRemote-GitBranch()
{
    PROCESS
    {
        $_ -replace "^(.*?)/(.*)$", "`$2"
    }
}

function Get-MergedLocalGitBranches($ignore)
{
    $branches = git branch --merged
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed | where {(IsNotCurrentLocal-GitBranch $_) -and !$ignore.Contains($_)}
}

function Get-MergedRemoteBranches($ignore)
{
    $current = Get-GitBranch
    $branches = git branch -r --merged
    $trimmed = $branches | foreach {$_.Trim()}
    return $trimmed `
        | where {!$_.Contains("/HEAD ->")} `
        | TrimRemote-GitBranch `
        | where {($_ -ne $current) -and !$ignore.Contains($_)}
}

function Remove-MergedLocalGitBranches
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter()]
        [string[]]
        $Ignore = @("master", "develop")
    )

    $branches = Get-MergedLocalGitBranches $Ignore
    if ($branches.Length -eq 0)
    {
        Write-Host "No local merged branches"
        return
    }

    Write-Host "Start deleting local merged branches"
    Write-Host
    
    foreach ($item in $branches)
    {
        if ($PSCmdlet.ShouldProcess($item, "delete branch"))
        {
            Write-Host "Deleting branch $item..."
            git branch -d $item
        }
        Write-Host
    }
    Write-Host "Finish deleting local merged branches"
}

function Remove-MergedRemoteGitBranches
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter()]
        [string[]]
        $Ignore = @("master", "develop")
    )

    $branches = Get-MergedRemoteBranches $Ignore
    if ($branches.Length -eq 0)
    {
        Write-Host "No remote merged branches"
        return
    }

    Write-Host "Start deleting remote merged branches"
    Write-Host
    
    foreach ($item in $branches)
    {
        if ($PSCmdlet.ShouldProcess($item, "delete remote branch"))
        {
            Write-Host "Deleting branch $item..."
            git push origin :$item
        }
        Write-Host
    }
    Write-Host "Finish deleting remote merged branches"
}

function Remove-MergedGitBranches()
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter()]
        [string[]]
        $Ignore = @("master", "develop")
    )

    Remove-MergedLocalGitBranches @PSBoundParameters
    Write-Host
    Remove-MergedRemoteGitBranches @PSBoundParameters
}