. $PSScriptRoot\Shared.ps1

Describe 'SSH Function Tests' {
    Context 'Get-SshPath Tests' {
        It 'Returns the correct default path, given the default keyfile exists' {
            if (!(Test-Path -LiteralPath $home\.ssh\id_rsa)) {
                $createdFile = New-Item $Home\.ssh\id_rsa -ItemType File
            }
            Get-SshPath | Should BeExactly (MakeNativePath $Home\.ssh\id_rsa)
            $createdFile | Remove-Item -ErrorAction SilentlyContinue
        }
        It 'Returns the correct path given an existing keyfile' {
            if (!(Test-Path -LiteralPath $home\.ssh\mykey)) {
                $createdFile = New-Item $Home\.ssh\mykey -ItemType File
            }
            Get-SshPath mykey | Should BeExactly (MakeNativePath $Home\.ssh\mykey)
            $createdFile | Remove-Item -ErrorAction SilentlyContinue
        }
        It 'Returns nothing for a non-existin key file' {
            Get-SshPath xyzzy | Should BeNullOrEmpty
        }
    }
}
