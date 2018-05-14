$ErrorActionPreference = 'Stop'

$moduleName = 'posh-git'
$sourcePath = Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"

Write-Verbose "Removing all version of '$moduleName' from '$sourcePath'."
Remove-Item -Path $sourcePath -Recurse -Force -ErrorAction SilentlyContinue

if ($PSVersionTable.PSVersion.Major -lt 4) {
    $modulePaths = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') -split ';'

    Write-Verbose "Removing '$sourcePath' from PSModulePath."
    $newModulePath = $modulePaths | Where-Object { $_ -ne $sourcePath }

    [Environment]::SetEnvironmentVariable('PSModulePath', $newModulePath, 'Machine')
    $env:PSModulePath = $newModulePath
}