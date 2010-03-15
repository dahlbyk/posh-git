Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Git utils
. ./GitUtils.ps1
. ./GitPrompt.ps1

# Use Git tab expansion
. ./GitTabExpansion.ps1

Pop-Location

# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
    Write-Host($pwd) -nonewline
        
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
      
    return "> "
}

# Set up tab expansion and include git expansion
function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1]
    
    switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
        'git (.*)' { GitTabExpansion $lastBlock }
        # OR to include all advanced commands in tab command completion:
        #'git (.*)' { GitTabExpansion $lastBlock $TRUE }
    }
}

Enable-GitColors