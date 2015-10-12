#requires -Version 1
function Siphon-Git
{
    param
    (
        [String]
        $Root
    )
    if($Root -eq $null)
    {
        Write-Error -Message 'Cannot handle null paths! Aborting...'
        Break
    }
    else
    {
        if(Test-Path $Root)
        {
            $Root = Convert-Path $Root
            Set-Location -Path $Root
            $Children = Get-ChildItem
            foreach($Child in $Children)
            {
                Write-Host "Currently pulling `"$Child`"..."
                Set-Location -Path $Child
                git pull
                Set-Location -Path '..\'
            }
        }
        else
        {
            Write-Error -Message "Path `"$Root`" not found! Aborting..."
            Break
        }
    }
}
