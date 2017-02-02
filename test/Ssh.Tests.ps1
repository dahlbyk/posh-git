. $PSScriptRoot\Shared.ps1

Describe 'SSH Function Tests' {
    Context 'Get-SshPath Tests' {
        It 'Returns the correct default path' {
            Get-SshPath | Should BeExactly (MakeNativePath $Home\.ssh\id_rsa)
        }
        It 'Returns the correct path for a given filename' {
            $filename = 'xyzzy-eb2ff0a9-81ee-4983-b32d-530286600a51'
            Get-SshPath $filename | Should BeExactly (MakeNativePath $Home\.ssh\$filename)
        }
        It 'Returns the correct path, given $Env:Home is not defined ($null)' {
            $origEnvHome = $Env:HOME
            try {
                Remove-Item Env:\Home -ErrorAction SilentlyContinue
                $Env:Home | Should BeNullOrEmpty
                Get-SshPath | Should BeExactly (MakeNativePath $Home\.ssh\id_rsa)
            }
            finally {
                Set-Item Env:\HOME -Value $origEnvHome
            }
        }
    }
}
