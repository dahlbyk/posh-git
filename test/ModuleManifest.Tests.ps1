
Describe 'Module Manifest Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $moduleManifestPath = "$PSScriptRoot\..\posh-git.psd1"
    }
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $moduleManifestPath | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
}
