<#
 # The source code: https://github.com/devSoheilAlizadeh/posh-git 
 #>

Import-Module posh-git

<#
 # Remove Default Path 
 #>
$GitPromptSettings.DefaultPromptPath = ''

<#
 # Change the posh-git text symbols
 #>
$GitPromptSettings.BeforeText = '('
$GitPromptSettings.AfterText  = ')'

<#
 # Overrride the default powershell prompt 
 #>
function prompt {
    
  $p = Split-Path -leaf -path (Get-Location)
  
    " $p" + ":"; 
  
    & $GitPromptScriptBlock
}

  