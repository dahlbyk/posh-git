#requires -version 3

function Get-GitIgnore()
{
    <#
    .Synopsis
        Displays list of supported templates.
    .Description
        Command will download list of supported .gitignore file from github.
    .Link
        https://github.com/dotCypress/ps-git-ignores
    .Example
        Get-GitIgnore
        Get-GitIgnore OCaml
    #>

    param(
        [Parameter(Position = 0, Mandatory=$false, HelpMessage="Template name")]
        [string] $Template
    )

    if($Template){
        try{
            (new-object Net.WebClient).DownloadString("https://api.github.com/gitignore/templates/$Template") | ConvertFrom-Json | Select-Object -ExpandProperty source
        }
        catch [Exception]{
            Write-Error "Template '$Template' not found"
        }
    } else {
        if(!$global:gitIgnoreTemplates){
            $global:gitIgnoreTemplates = (new-object Net.WebClient).DownloadString("https://api.github.com/gitignore/templates") | ConvertFrom-Json
        }
        $global:gitIgnoreTemplates
    }
}

function Add-GitIgnore()
{
    <#
    .Synopsis
        Adds requested .gitignore to current directory.
    .Description
        Command will create .gitignore file for specific template and put it to the current folder.
    .Link
        https://github.com/dotCypress/ps-git-ignores
    .Example
        Add-GitIgnore CSharp
    #>
    param(
        [Parameter(Position = 0, Mandatory=$true, HelpMessage="Template name")]
        [ValidateNotNullOrEmpty()]
        [string] $Template
    )
    $content = Get-GitIgnore $Template
    if($content){
        Out-File -Encoding UTF8 -Filepath .gitignore -NoClobber -InputObject $content
    }
}

# Register tab expansion
if(Get-Module PowerTab){
    $EventHandler = {
        param($Context, [ref]$TabExpansionHasOutput)
        $Argument = $Context.Argument
        switch -exact ($Context.Parameter) {
            'Template' {
                $TabExpansionHasOutput.Value = $true
                Get-GitIgnore | Where {$_ -like "$Argument*"}
            }
        }
    }.GetNewClosure()

    Register-TabExpansion "Get-GitIgnore" $EventHandler -Type "Command"
    Register-TabExpansion "Add-GitIgnore" $EventHandler -Type "Command"
}

Export-ModuleMember Get-GitIgnore, Add-GitIgnore