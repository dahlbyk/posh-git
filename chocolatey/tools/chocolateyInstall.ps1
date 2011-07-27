try {
  $poshgitPath = "$env:SystemDrive\tools\poshgit"
  
  Install-ChocolateyZipPackage 'poshgit' 'https://github.com/dahlbyk/posh-git/zipball/v0.3' $poshgitPath

  #------- ADDITIONAL SETUP -------#
  $installer = Join-Path $poshgitPath 'dahlbyk-posh-git-60e1ed7'
  $installer = Join-Path $installer 'install.ps1' 
  & $installer

  Write-ChocolateySuccess 'poshgit'
} catch {
  Write-ChocolateyFailure 'poshgit' $($_.Exception.Message)
  throw 
}