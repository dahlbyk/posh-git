try {
    $binRoot = Get-BinRoot

    $oldPromptOverride = "if(Test-Path Function:\Prompt) {Rename-Item Function:\Prompt PrePoshGitPrompt -Force}"
    $newPromptOverride = "function Prompt() {if(Test-Path Function:\PrePoshGitPrompt){++`$global:poshScope; New-Item function:\script:Write-host -value `"param([object] ```$object, ```$backgroundColor, ```$foregroundColor, [switch] ```$nonewline) `" -Force | Out-Null;`$private:p = PrePoshGitPrompt; if(--`$global:poshScope -eq 0) {Remove-Item function:\Write-Host -Force}}PoshGitPrompt}"

    $poshgitPath = join-path $binRoot 'poshgit'

    try {
      if (test-path($poshgitPath)) {
        Write-Host "Attempting to remove existing `'$poshgitPath`' prior to install."
        remove-item $poshgitPath -recurse -force
      }
    } catch {
      Write-Host "Could not remove `'$poshgitPath`'"
    }

    $poshGitInstall = if($env:poshGit -ne $null){ $env:poshGit } else {'https://github.com/dahlbyk/posh-git/zipball/master'}
    Install-ChocolateyZipPackage 'poshgit' $poshGitInstall $poshgitPath
    $pgitDir = Dir "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime | Select -Last 1

    if(Test-Path $PROFILE) {
        $oldProfile = @(Get-Content $PROFILE)
        $newProfile = @()
        #If old profile exists replace with new one and make sure prompt preservation function is on top
        $pgitExample = "$pgitDir\profile.example.ps1"
        foreach($line in $oldProfile) {
            if($line.ToLower().Contains("$poshgitPath".ToLower())) {
                $line = ". '$pgitExample'"
            }
            if($line.Trim().Length -gt 0) {  $newProfile += $line }
        }
        Set-Content -path $profile -value $newProfile -Force
    }

    $installer = Join-Path $pgitDir 'install.ps1'
    & $installer
} catch {
  try {
    if($oldProfile){ Set-Content -path $PROFILE -value $oldProfile -Force }
  }
  catch {}
  throw
}

