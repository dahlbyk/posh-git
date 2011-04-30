try {
  $scriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
  Install-ChocolateyZipPackage 'poshgit' 'https://github.com/dahlbyk/posh-git/zipball/v0.3' $scriptPath

  #------- ADDITIONAL SETUP -------#
  #todo: find the installer. This is not it
  #$installer = Join-Path $scriptPath 'install.ps1' 
  #& $installer

  write-host "poshgit has been installed into powershell."
  Start-Sleep 6
} catch {
@"
Error Occurred: $($_.Exception.Message)
"@ | Write-Host -ForegroundColor White -BackgroundColor DarkRed
	Start-Sleep 8
	throw 
}