# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

function Write-GitStatus($status) {
    if ($status) {
        $indexColor = [ConsoleColor]::Blue
        $workingColor = [ConsoleColor]::Yellow
        
        $currentBranch = $status.Branch
        
        Write-Host(' [') -nonewline -foregroundcolor Yellow
        if ($status.AheadBy -eq 0) {
            # We are not ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Cyan
        } else {
            # We are ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Red
        }
        
        if($status.HasIndex) {
            Write-Host " +$($status.IndexAdded.Count)" -nonewline -foregroundcolor $indexColor
            Write-Host " ~$($status.IndexModified.Count)" -nonewline -foregroundcolor $indexColor
            Write-Host " -$($status.IndexDeleted.Count)" -nonewline -foregroundcolor $indexColor

            if($status.HasWorking) {
                Write-Host " |" -nonewline -foregroundcolor Yellow
            }
        }
        
        if($status.HasWorking) {
            Write-Host " +$($status.Added.Count)" -nonewline -foregroundcolor $workingColor
            Write-Host " ~$($status.Modified.Count)" -nonewline -foregroundcolor $workingColor
            Write-Host " -$($status.Deleted.Count)" -nonewline -foregroundcolor $workingColor
        }
        
        if ($status.HasUntracked) {
            Write-Host(' !') -nonewline -foregroundcolor Yellow
        }
        
        Write-Host(']') -nonewline -foregroundcolor Yellow
    }
}
