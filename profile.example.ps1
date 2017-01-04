# Import the posh-git module, first via installed posh-git module.
# If the module isn't installed, then attempt to load it from the cloned posh-git Git repo.
if (Get-Module posh-git -ListAvailable) {
    Import-Module posh-git
}
elseif (Test-Path -LiteralPath $PSScriptRoot\posh-git.psd1) {
    Import-Module $PSScriptRoot\posh-git.psd1
}
else {
    throw "Failed to import posh-git."
}

# Settings for the prompt are in GitPrompt.ps1, so add any desired settings changes here.
# Example:
#     $Global:GitPromptSettings.BranchBehindAndAheadDisplay = "Compact"

Start-SshAgent -Quiet
