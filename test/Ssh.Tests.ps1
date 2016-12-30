. $PSScriptRoot\Shared.ps1

Describe 'SSH Function Tests' {
    Context 'Get-SshPath Tests' {
        BeforeAll {
            $sepChar = [System.IO.Path]::DirectorySeparatorChar
        }
        It 'Returns the correct default path' {
            Get-SshPath | Should BeExactly "${Home}${sepChar}.ssh${sepChar}id_rsa"
        }
        It 'Returns the correct path given a filename' {
            Get-SshPath mykey | Should BeExactly "${Home}${sepChar}.ssh${sepChar}mykey"
        }
    }
}
