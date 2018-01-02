#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Builds posh-git by copying the src into an output dir.
.DESCRIPTION
    Builds posh-git by copying the src into an output dir. The name of the
    output dir is the version number specified in src\posh-git.psd1 for the
    checked out branch.  The naming scheme results in the path
    posh-git\<version-number> which is compatible with Import-Module when it
    imports a module by name.  The posh-git repo needs to be either located in
    a built-in Modules directory such as ~\Documents\WindowsPowerShell\Modules
    or ~/.local/share/powershell/Modules or the repo dir needs to be added to
    $env:PSModulePath.
.EXAMPLE
    PS C:\> C:\github\posh-git\build.ps1
    Builds posh-git out dir on Windows.
.EXAMPLE
    PS C:\> ~/github/posh-git/build.ps1
    Builds posh-git out dir on Linux / macOS.
.EXAMPLE
    PS C:\> C:\github\posh-git\build.ps1 -PrepareForPublish -PrereleaseVersion beta1
    Prepare for publishing a beta1 release.
.EXAMPLE
    PS C:\> C:\github\posh-git\build.ps1 -PrepareForPublish
    Prepare for publishing a release (not a prerelease).
.INPUTS
    None
.OUTPUTS
    None
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # If specified, updates the module manifest in the out dir to either remove
    # the PrivateData.PSData.PrereleaseVersion or change its value to the value
    # specified by the PrereleaseVersion parameter.
    [Parameter(ParameterSetName="Publish")]
    [switch]
    $PrepareForPublish,

    # Specify prerelease version e.g. 'beta1` if the release is prerelease.
    [Parameter()]
    [string]
    $PrereleaseVersion = $null
)

$moduleManifest = Import-LocalizedData -BaseDirectory $PSScriptRoot/src -FileName posh-git
$outDir = Join-Path $PSScriptRoot $moduleManifest.ModuleVersion

if (Test-Path -LiteralPath $outDir) {
    # Clean out dir if it exists
    if ($PSCmdlet.ShouldProcess($outDir, "Cleaning contents of out dir")) {
        Remove-Item $outDir/* -Recurse -Force
    }
}
elseif ($PSCmdlet.ShouldProcess($outDir, "Creating out dir")) {
    New-Item $outDir -ItemType Directory > $null
}

if ($PSCmdlet.ShouldProcess($outDir, "Copying src dir to out dir")) {
    Copy-Item $PSScriptRoot/src/* $outDir -Recurse
}

if ($PrepareForPublish -and $PSCmdlet.ShouldProcess((Join-Path $outDir posh-git.psd1), "Preparing for publish")) {
    $outDirManifestPath = Join-Path $outDir posh-git.psd1
    $content = Get-Content $outDirManifestPath
    $newContent = @()
    foreach ($line in $content) {
        if ($line -notmatch '\s*Prerelease\s*=') {
            $newContent += $line
            continue
        }

        if ($PrereleaseVersion) {
            $newContent += "        Prerelease = '$PrereleaseVersion'"
        }
        else {
            # do nothing and the line will be removed
        }
    }

    $newContent | Out-File $outDirManifestPath -Encoding ascii
}
