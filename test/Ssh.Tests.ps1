. $PSScriptRoot\Shared.ps1

Describe 'SSH Function Tests' {
    Context 'Get-SshPath Tests' {
        It 'Returns the correct default path' {
            Get-SshPath | Should BeExactly (MakeNativePath $Home\.ssh\id_rsa)
        }
        It 'Returns the correct path given a filename' {
            Get-SshPath mykey | Should BeExactly (MakeNativePath $Home\.ssh\mykey)
        }
    }
}
