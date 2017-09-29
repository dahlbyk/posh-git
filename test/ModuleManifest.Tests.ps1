. $PSScriptRoot\Shared.ps1

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $moduleManifestPath | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
}
