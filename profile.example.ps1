Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-hg module from current directory
Import-Module .\posh-hg

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
# Import-Module posh-hg


# Set up a simple prompt, adding the hg prompt parts inside hg repos
function prompt {
    Write-Host($pwd) -nonewline

    Write-VcsStatus
      
    return "> "
}

Pop-Location
