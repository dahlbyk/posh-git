$packageName = "poshgit"
cpack

function Setup-Environment {
    Cleanup
    $env:poshGit = join-path (Resolve-Path .\Tests ) dahlbyk-posh-git-60be436.zip
    $profileScript = "function Prompt(){ `$host.ui.RawUI.WindowTitle = `"My Prompt`" }"
    (Set-Content $Profile -value $profileScript -Force)
}

function Cleanup {
    Clean-Temp
    Remove-Item $env:ChocolateyInstall\lib\$packageName* -Recurse -Force
}

function Clean-Temp {
    if(Test-Path $env:Temp\Chocolatey\$packageName) {Remove-Item $env:Temp\Chocolatey\$packageName -Recurse -Force}
}

function RunInstall {
    cinst $packageName -source (Resolve-Path .)
}
$binRoot = join-path $env:systemdrive 'tools'
if($env:chocolatey_bin_root -ne $null){$binRoot = join-path $env:systemdrive $env:chocolatey_bin_root}
$poshgitPath = join-path $binRoot 'poshgit'
if(Test-Path $Profile) { $currentProfileScript = (Get-Content $Profile) }

function Clean-Environment {
    Set-Content $Profile -value $currentProfileScript -Force
}

Describe "Install-Posh-Git" {

    It "WillRemvePreviousInstallVersion" {
        Setup-Environment
        try{
            Add-Content $profile -value ". '$poshgitPath\posh-git\profile.example.ps1'"

            RunInstall

            $newProfile = (Get-Content $Profile)
            $pgitDir = [Array](Dir "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime)[-1]
            ($newProfile -like ". '$poshgitPath\posh-git\profile.example.ps1'").Count.should.be(0)
            ($newProfile -like ". '$pgitDir\profile.example.ps1'").Count.should.be(1)
        }
        catch {
            write-host (Get-Content $Profile)
            throw
        }
        finally {Clean-Environment}
    }

    It "WillNotAddDuplicateCallOnRepeatInstall" {
        Setup-Environment
        try{
            RunInstall
            Cleanup

            RunInstall

            $newProfile = (Get-Content $Profile)
            $pgitDir = [Array](Dir "$poshgitPath\*posh-git*\" | Sort-Object -Property LastWriteTime)[-1]
            ($newProfile -like ". '$pgitDir\profile.example.ps1'").Count.should.be(1)
        }
        catch {
            write-host (Get-Content $Profile)
            throw
        }
        finally {Clean-Environment}
    }

    It "WillPreserveOldPromptLogic" {
        Setup-Environment
        try{
            RunInstall
            . $Profile
            $host.ui.RawUI.WindowTitle = "bad"

            Prompt

            $host.ui.RawUI.WindowTitle.should.be("My Prompt")
        }
        catch {
            write-host (Get-Content function:\prompt)
            throw
        }
        finally {
            Clean-Environment
        }
    }

    It "WillOutputVcsStatus" {
        Setup-Environment
        try{
            RunInstall
            mkdir PoshTest
            Pushd PoshTest
            git init
            . $Profile
            $global:wh=""
            New-Item function:\global:Write-Host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) try{Write-Output `$object;[string]`$global:wh += `$object.ToString()} catch{}"

            Prompt

            Popd
            $wh.should.be("$pwd\PoshTest [master]")
        }
        catch {
            write-output (Get-Content $Profile)
            throw
        }
        finally {
            Clean-Environment
            if( Test-Path function:\Write-Host ) {Remove-Item function:\Write-Host}
            if( Test-Path PoshTest ) {Remove-Item PoshTest -Force -Recurse}
        }
    }

    It "WillSucceedOnEmptyProfile" {
        Setup-Environment
        try{
            Remove-Item $Profile -Force
            RunInstall
            mkdir PoshTest
            Pushd PoshTest
            git init
            . $Profile
            $global:wh=""
            New-Item function:\global:Write-Host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) try{Write-Output `$object;[string]`$global:wh += `$object.ToString()} catch{}"

            Prompt

            Popd
            $wh.should.be("$pwd\PoshTest [master]")
        }
        catch {
            write-output (Get-Content $Profile)
            throw
        }
        finally {
            Clean-Environment
            if( Test-Path function:\Write-Host ) {Remove-Item function:\Write-Host}
            if( Test-Path PoshTest ) {Remove-Item PoshTest -Force -Recurse}
        }
    }

    It "WillSucceedOnProfileWithPromptWithWriteHost" {
        Cleanup
        Setup-Environment
        try{
            Remove-Item $Profile -Force
            Add-Content $profile -value "function prompt {Write-Host 'Hi'}" -Force
            RunInstall
            mkdir PoshTest
            Pushd PoshTest
            git init
            . $Profile
            $global:wh=""
            New-Item function:\global:Write-Host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) try{Write-Output `$object;[string]`$global:wh += `$object.ToString()} catch{}"

            Prompt

            Remove-Item function:\global:Write-Host
            Popd
            $wh.should.be("$pwd\PoshTest [master]")
        }
        catch {
            write-output (Get-Content $Profile)
            throw
        }
        finally {
            Clean-Environment
            if( Test-Path function:\Write-Host ) {Remove-Item function:\Write-Host}
            if( Test-Path PoshTest ) {Remove-Item PoshTest -Force -Recurse}
        }
    }

    It "WillSucceedOnUpdatingFrom040" {
        Cleanup
        Setup-Environment
        try{
            Remove-Item $Profile -Force
            Add-Content $profile -value ". 'C:\tools\poshgit\dahlbyk-posh-git-60be436\profile.example.ps1'" -Force
            RunInstall
            mkdir PoshTest
            Pushd PoshTest
            git init
            write-output (Get-Content function:\prompt)
            . $Profile
            $global:wh=""
            New-Item function:\global:Write-Host -value "param([object] `$object, `$backgroundColor, `$foregroundColor, [switch] `$nonewline) try{Write-Output `$object;[string]`$global:wh += `$object.ToString()} catch{}"

            Prompt

            Remove-Item function:\global:Write-Host
            Popd
            $wh.should.be("$pwd\PoshTest [master]")
        }
        catch {
            write-output (Get-Content $Profile)
            throw
        }
        finally {
            Clean-Environment
            if( Test-Path function:\Write-Host ) {Remove-Item function:\Write-Host}
            if( Test-Path PoshTest ) {Remove-Item PoshTest -Force -Recurse}
        }
    }

}
