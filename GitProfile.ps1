Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

. .\GitUtils.ps1
. .\GitPrompt.ps1
. .\GitTabExpansion.ps1

function Prompt() {
    Write-Host "$(1+(Get-History -Count 1).Id) " -nonewline
    $dir = $pwd | Get-Item

    $Host.UI.RawUi.WindowTitle = $dir.FullName
    Write-Host $dir.Name -nonewline -foregroundcolor Green

    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus

    return '> '
}

Pop-Location
