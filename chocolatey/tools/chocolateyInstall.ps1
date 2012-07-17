try {
    $binRoot = join-path $env:systemdrive 'tools'

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

    #Install-ChocolateyZipPackage 'poshgit' 'https://github.com/dahlbyk/posh-git/zipball/v0.4' $poshgitPath
    Install-ChocolateyZipPackage 'poshgit' 'https://github.com/dahlbyk/posh-git/zipball/master' $poshgitPath

    #------- ADDITIONAL SETUP -------#
    $subfolder = get-childitem $poshgitPath -recurse -include 'dahlbyk-posh-git-*' | select -First 1
    write-debug "Found and using folder `'$subfolder`'"
    #$installer = Join-Path $poshgitPath $subfolder #'dahlbyk-posh-git-60be436'
    $installer = Join-Path $subfolder 'install.ps1'
    & $installer

    Write-ChocolateySuccess 'poshgit'
} catch {
  Write-ChocolateyFailure 'poshgit' $($_.Exception.Message)
  throw
}
