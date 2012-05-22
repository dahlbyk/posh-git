Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-git module from current directory
Import-Module .\posh-git

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
# Import-Module posh-git

# Rename the old prompt function for later access
Rename-Item function:prompt _PoshGitAliasPrompt

# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    if(Get-GitDirectory) { # check if this is a git repo
    
        # Reset color, which can be messed up by Enable-GitColors
        $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

        Write-Host($pwd) -nonewline

        Write-VcsStatus

        $global:LASTEXITCODE = $realLASTEXITCODE
        return "> "
    } else { # if not execute old prompt
        $global:LASTEXITCODE = $realLASTEXITCODE
        return _PoshGitAliasPrompt
    }
}

Enable-GitColors

Pop-Location

Start-SshAgent -Quiet
