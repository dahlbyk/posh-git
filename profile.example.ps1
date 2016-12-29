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

# Set up a simple prompt that displays Git status summary info when inside of a Git repo.
function global:prompt {
    $origLastExitCode = $LASTEXITCODE

    # A UNC path has no drive so it's better to use the ProviderPath e.g. "\\server\share".
    # However for any path with a drive defined, it's better to use the Path property.
    # In this case, ProviderPath is "\LocalMachine\My"" whereas Path is "Cert:\LocalMachine\My".
    # The latter is more desirable.
    $pathInfo = $ExecutionContext.SessionState.Path.CurrentLocation
    $curPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }
    Write-Host $curPath -NoNewline

    # Write the Git status summary information to the host.
    Write-VcsStatus

    $global:LASTEXITCODE = $origLastExitCode
    "> "
}

Start-SshAgent -Quiet
