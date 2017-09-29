try {
    $poshgitPath = join-path (Get-ToolsLocation) 'poshgit'

    try {
      if (test-path($poshgitPath)) {
        Write-Host "Attempting to remove existing `'$poshgitPath`'."
        remove-item $poshgitPath -recurse -force
      }
    } catch {
      Write-Host "Could not remove `'$poshgitPath`'"
    }

    $version = "v$Env:chocolateyPackageVersion"
    if ($version -eq 'v') { $version = 'master' }
    $poshGitInstall = if ($env:poshGit ) { $env:poshGit } else { "https://github.com/dahlbyk/posh-git/zipball/$version" }
    $zip = Install-ChocolateyZipPackage 'poshgit' $poshGitInstall $poshgitPath
    $currentVersionPath = Get-ChildItem "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime | Select-Object -Last 1

    if(Test-Path $PROFILE) {
        $oldProfile = @(Get-Content $PROFILE)

        . $currentVersionPath\src\Utils.ps1
        $oldProfileEncoding = Get-FileEncoding $PROFILE

        $newProfile = @()
        foreach($line in $oldProfile) {
            if ($line -like '*PoshGitPrompt*') { continue; }

            if($line -like '. *posh-git*profile.example.ps1*') {
                $line = ". '$currentVersionPath\profile.example.ps1' choco"
            }
            if($line -like 'Import-Module *\src\posh-git.psd1*') {
                $line = "Import-Module '$currentVersionPath\src\posh-git.psd1'"
            }
            $newProfile += $line
        }
        Set-Content -path $profile -value $newProfile -Force -Encoding $oldProfileEncoding
    }

    $installer = Join-Path $currentVersionPath 'install.ps1'
    & $installer
} catch {
  try {
    if($oldProfile){ Set-Content -path $PROFILE -value $oldProfile -Force -Encoding $oldProfileEncoding }
  }
  catch {}
  throw
}

