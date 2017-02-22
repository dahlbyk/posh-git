try {
    $poshgitPath = join-path (Get-ToolsLocation) 'poshgit'

    $currentVersionPath = Get-ChildItem "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime | Select-Object -Last 1

    if(Test-Path $PROFILE) {
        $oldProfile = @(Get-Content $PROFILE)

        . $currentVersionPath\src\Utils.ps1
        $oldProfileEncoding = Get-FileEncoding $PROFILE

        $newProfile = @()
        foreach($line in $oldProfile) {
            if ($line -like '*PoshGitPrompt*') { continue; }
            if ($line -like '*Load posh-git example profile*') { continue; }

            if($line -like '. *posh-git*profile.example.ps1*') {
                continue;
            }
            if($line -like 'Import-Module *\src\posh-git.psd1*') {
                continue;
            }
            $newProfile += $line
        }
        Set-Content -path $profile -value $newProfile -Force -Encoding $oldProfileEncoding
    }

    try {
      if (test-path($poshgitPath)) {
        Write-Host "Attempting to remove existing `'$poshgitPath`'."
        remove-item $poshgitPath -recurse -force
      }
    } catch {
      Write-Host "Could not remove `'$poshgitPath`'"
    }
} catch {
  try {
    if($oldProfile){ Set-Content -path $PROFILE -value $oldProfile -Force -Encoding $oldProfileEncoding }
  }
  catch {}
  throw
}

