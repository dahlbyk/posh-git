function Insert-Script([ref]$originalScript, $script) {
    if(!($originalScript.Value -Contains $script)) { $originalScript.Value += $script }
}

try {
    $binRoot = join-path $env:systemdrive 'tools'
    $oldPromptOverride = "if(Test-Path Function:\Prompt) {Rename-Item Function:\Prompt PrePoshGitPrompt -Force}"
    $newPromptOverride = "function Prompt() {if(Test-Path Function:\PrePoshGitPrompt){++`$global:poshScope; New-Item function:\script:Write-host -value `"param([object] ```$object, ```$backgroundColor, ```$foregroundColor, [switch] ```$nonewline) `" -Force | Out-Null;`$private:p = PrePoshGitPrompt; if(--`$global:poshScope -eq 0) {Remove-Item function:\Write-Host -Force}}PoshGitPrompt}"
    ### Using an environment variable to to define the bin root until we implement YAML configuration ###
    if($env:chocolatey_bin_root -ne $null){$binRoot = join-path $env:systemdrive $env:chocolatey_bin_root}
    $poshgitPath = join-path $binRoot 'poshgit'

    try {
      if (test-path($poshgitPath)) {
        Write-Host "Attempting to remove existing `'$poshgitPath`' prior to install."
        remove-item $poshgitPath -recurse -force
      }
    } catch {
      Write-Host 'Could not remove poshgit folder'
    }

    $poshGitInstall = if($env:poshGit -ne $null){ $env:poshGit } else {'https://github.com/dahlbyk/posh-git/zipball/master'}
    #Install-ChocolateyZipPackage 'poshgit' 'https://github.com/dahlbyk/posh-git/zipball/v0.4' $poshgitPath
    Install-ChocolateyZipPackage 'poshgit' $poshGitInstall $poshgitPath
    $pgitDir = [Array](Dir "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime)[-1]

    if(Test-Path $PROFILE) {
        $oldProfile = [string[]](Get-Content $PROFILE)
        $newProfile = @()
        #If old profile exists replace with new one and make sure prompt preservation function is on top
        $pgitExample = "$pgitDir\profile.example.ps1"
        foreach($line in $oldProfile) {
            if($line.ToLower().Contains("$poshgitPath".ToLower())) {
                Insert-Script ([REF]$newProfile) $oldPromptOverride
                $line = ". '$pgitExample'"
            }
            if($line.Trim().Length -gt 0) {  $newProfile += $line }
        }
        #Save any previous Prompt logic
        Insert-Script ([REF]$newProfile) $oldPromptOverride
        Set-Content -path $profile -value $newProfile -Force
    }


    #------- ADDITIONAL SETUP -------#
    $subfolder = get-childitem $poshgitPath -recurse -include 'dahlbyk-posh-git-*' | select -First 1
    write-debug "Found and using folder `'$subfolder`'"
    #$installer = Join-Path $poshgitPath $subfolder #'dahlbyk-posh-git-60be436'
    $installer = Join-Path $subfolder 'install.ps1'
    & $installer

    $newProfile = [string[]](Get-Content $PROFILE)
    Insert-Script ([REF]$newProfile) "Rename-Item Function:\Prompt PoshGitPrompt -Force"

    #function that will run previous prompt logic and then the poshgit logic
    #all output from previous prompts will be swallowed
    Insert-Script ([REF]$newProfile) $newPromptOverride
    Set-Content -path $profile  -value $newProfile -Force

    Write-ChocolateySuccess 'poshgit'
} catch {
  try {
    if($oldProfile){ Set-Content -path $PROFILE -value $oldProfile -Force }
  }
  catch{}
  Write-ChocolateyFailure 'poshgit' $($_.Exception.Message)
  throw
}

