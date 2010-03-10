# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration

function Test-GitDirectory {
	(git rev-parse --git-dir 2> $null) -ne $null
}

function Get-GitBranch {
	if (Test-GitDirectory) {
		$headRef = (git symbolic-ref HEAD) 2> $null
		if ($headRef) {
			Split-Path -Leaf $headRef
		}
	}
}

function Get-GitStatus {
    if(Test-GitDirectory)
    {
        $indexAdded = @()
        $indexModified = @()
        $indexDeleted = @()
        $filesAdded = @()
        $filesModified = @()
        $filesDeleted = @()
        $aheadCount = 0
        
        $diffIndex = git diff-index -M --name-status --cached HEAD |
                     ConvertFrom-CSV -Delim "`t" -Header 'Status','Path'
        $diffFiles = git diff-files -M --name-status |
                     ConvertFrom-CSV -Delim "`t" -Header 'Status','Path'

        $grpIndex = $diffIndex | Group-Object Status -AsHashTable
        $grpFiles = $diffFiles | Group-Object Status -AsHashTable

        if($grpIndex.A) { $indexAdded += $grpIndex.A | %{ $_.Path } }
        if($grpIndex.M) { $indexModified += $grpIndex.M | %{ $_.Path } }
        if($grpIndex.R) { $indexModified += $grpIndex.R | %{ $_.Path } }
        if($grpIndex.D) { $indexDeleted += $grpIndex.D | %{ $_.Path } }
        if($grpFiles.M) { $filesModified += $grpFiles.M | %{ $_.Path } }
        if($grpFiles.R) { $filesModified += $grpFiles.R | %{ $_.Path } }
        if($grpFiles.D) { $filesDeleted += $grpFiles.D | %{ $_.Path } }
        
        $untracked = git ls-files -o --exclude-standard
        if($untracked) { $filesAdded += $untracked }

        $output = git status
        
        $output | foreach {
            if ($_ -match "^\#.*origin/.*' by (\d+) commit.*") {
                $aheadCount = $matches[1]
            }
        }

        return New-Object PSObject -Property @{
            Branch        = Get-GitBranch
            AheadBy       = $aheadCount
            HasIndex      = [bool]$diffIndex
            Index         = $diffIndex | %{ $_.Path }
            IndexAdded    = $indexAdded
            IndexModified = $indexModified
            IndexDeleted  = $indexDeleted
            HasWorking    = [bool]$diffFiles
            Working       = ($diffFiles | %{ $_.Path }) + $untracked
            Added         = $filesAdded
            Modified      = $filesModified
            Deleted       = $filesDeleted
            HasUntracked  = [bool]$filesAdded
        }
    }
}
