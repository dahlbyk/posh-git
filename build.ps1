$moduleVersion = (Import-LocalizedData -FileName 'posh-git.psd1' -BaseDirectory (Join-Path $PSScriptRoot 'src')).ModuleVersion
$outputFolder = (Join-Path $PSScriptRoot $moduleVersion)

# Clean
if (Test-Path $outputFolder) {
    Remove-Item $outputFolder -Recurse
}

# Copy files to output folder
Copy-Item -Path (Join-Path $PSScriptRoot 'src') -Destination $outputFolder -Recurse

$mainModulePath = (Join-Path $outputFolder 'posh-git.psm1')
$contentOfMainModule = Get-Content -Path $mainModulePath

$PowerShellScriptsToBeMerged = Get-ChildItem -Path $outputFolder -Filter '*.ps1'
foreach ($powerShellScriptToBeMerged in $PowerShellScriptsToBeMerged) {
    $NameOfScriptToBeMerged = $powerShellScriptToBeMerged.Name
    $scriptContentToBeMerged = Get-Content -Path $powerShellScriptToBeMerged.FullName -Raw
    $replaceSearchText = ". `$PSScriptRoot\$NameOfScriptToBeMerged"
    if ($contentOfMainModule.Contains($replaceSearchText)) {
        $contentOfMainModule = $contentOfMainModule.Replace(". `$PSScriptRoot\$NameOfScriptToBeMerged",
            @"
#region $($powerShellScriptToBeMerged.BaseName)
$scriptContentToBeMerged
#endregion

"@)
        Remove-Item $powerShellScriptToBeMerged.FullName
    }
}

Set-Content -Path $mainModulePath -Value $contentOfMainModule

Write-Verbose "Module created at '$outputFolder'" -Verbose
