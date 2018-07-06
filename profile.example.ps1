# Import the posh-git module, first via installed posh-git module.
# If the module isn't installed, then attempt to load it from the cloned posh-git Git repo.
$poshGitModule = Get-Module posh-git -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($poshGitModule) {
    $poshGitModule | Import-Module
}
elseif (Test-Path -LiteralPath ($modulePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) (Join-Path src 'posh-git.psd1'))) {
    Import-Module $modulePath
}
else {
    throw "Failed to import posh-git."
}

# Settings for the prompt are in GitPrompt.ps1, so add any desired settings changes here.
# Example:
#     $Global:GitPromptSettings.BranchBehindAndAheadDisplay = "Compact"

if ($args[0] -ne 'choco') {
    Write-Warning "posh-git's profile.example.ps1 will be removed in a future version."
    Write-Warning "Consider using `Add-PoshGitToProfile` instead."
}
