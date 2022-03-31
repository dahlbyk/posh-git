# Not using BeforeAll because discovery doesn't like InModuleScope without posh-git loaded
. $PSScriptRoot\Shared.ps1

Describe 'Test-GitVersion' {
    InModuleScope 'posh-git' {
        It 'Returns true for Git for Windows newer than 2.15 (<_>)' -ForEach @(
            'git version 2.33.0.rc2.windows.1',
            'git version 2.33.0-rc2.windows.1',
            'git version 2.31.0.vfs.0.1',
            'git version 2.15.0.windows.0',
            'git version 2.100.0.windows.0',
            'git version 3.0.0.windows.0'
        ) {
            Mock Write-Warning {}

            Test-GitVersion $_ | Should -Be $true

            Should -Not -Invoke Write-Warning
        }

        It 'Returns false for Git for Windows older than 2.15 (<_>)' -ForEach @(
            'git version 0.1.0.windows',
            'git version 1.99.0.windows',
            'git version 2.14.0.windows'
        ) {
            Mock Write-Warning {}

            Test-GitVersion $_ | Should -Be $false

            Should -Not -Invoke Write-Warning
        }

        It 'Returns false for unparseable version (<_>)' -ForEach @(
            'git version 1'
        ) {
            Mock Write-Warning {} -Verifiable -ParameterFilter { $Message -like '*could not parse*' }

            Test-GitVersion $_ | Should -Be $false

            Should -InvokeVerifiable Write-Warning
        }

        # TODO: Test Cygwin warning and POSHGIT_CYGWIN_WARNING
    }
}
