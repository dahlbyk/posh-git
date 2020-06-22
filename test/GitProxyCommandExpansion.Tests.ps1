BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'CommandExpansion Tests' {
    Context 'Proxy Subcommand TabExpansion Tests' {
        BeforeEach {
            if(Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
            if(Test-Path -Path Alias:\igf) {
                Rename-Item -Path Alias:\igf -NewName igfbackup
            }
        }
        AfterEach {
            if(Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if(Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item Function:\Invoke-GitFunctionBackup Invoke-GitFunction
            }
            if(Test-Path -Path Alias:\igf) {
                Remove-Item -Path Alias:\igf
            }
            if(Test-Path -Path Alias:\igfbackup) {
                Rename-Item -Path Alias:\igfbackup -NewName igf
            }
        }
        It 'Expands a single line command' {
            function global:Invoke-GitFunction {
                git checkout $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands a single line command with parameter' {
            function global:Invoke-GitFunction {
                git checkout -b $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout -b '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout -b '
        }
        It 'Expands the first line in command' {
            function global:Invoke-GitFunction {
                git checkout $args
                $a = 5
                Write-Host $null
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands the middle line in command' {
            function global:Invoke-GitFunction {
                $a = 5
                git checkout $args
                Write-Host $null
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands the last line in command' {
            function global:Invoke-GitFunction {
                $a = 5
                Write-Host $null
                git checkout $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands semicolon delimited commands' {
            function global:Invoke-GitFunction {
                $a = 5; git checkout $args; Write-Host $null;
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands mixed semicolon delimited and newline commands' {
            function global:Invoke-GitFunction {
                $a = 5; Write-Host $null
                git checkout $args; Write-Host $null;
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands mixed semicolon delimited and newline multiline commands' {
            function global:Invoke-GitFunction {
                $a = 5; Write-Host $null
                git `
                checkout `
                $args; Write-Host $null;
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands multiline command' {
            function global:Invoke-GitFunction {
                git `
                checkout `
                $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout '
        }
        It 'Expands multiline command with parameter' {
            function global:Invoke-GitFunction {
                git `
                checkout `
				-b `
                $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'git checkout -b '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'git checkout -b '
        }
        It 'Does not expand command if $args is not present' {
            function global:Invoke-GitFunction {
                git checkout
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'Invoke-GitFunction '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'igf '
        }
        It 'Does not expand command if $args is not attached to the git command' {
            function global:Invoke-GitFunction {
                $a = 5
                git checkout
                Write-Host $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'Invoke-GitFunction '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'igf '
        }
        It 'Does not expand multiline command if $args is not attached to the git command' {
            function global:Invoke-GitFunction {
                $a = 5
                git `
                checkout
                Write-Host $args
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
            $result = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result | Should -Be 'Invoke-GitFunction '
            $result = & $module Expand-GitProxyCommand 'igf '
            $result | Should -Be 'igf '
        }
    }
    Context 'Proxy Subcommand TabExpansion Tests' {
        BeforeEach {
            if(Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
        }
        AfterEach {
            if(Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if(Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item -Path Function:\Invoke-GitFunctionBackup -NewName Invoke-GitFunction
            }
        }
        It 'Tab completes without subcommands' {
            function global:Invoke-GitFunction { git whatever $args }
            $CommandText = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $CommandText

            $result | Should -Be @()
        }
        It 'Tab completes bisect subcommands' {
            function global:Invoke-GitFunction { git bisect $args }
            $CommandText = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $CommandText

            $result -contains '' | Should -Be $false
            $result -contains 'start' | Should -Be $true
            $result -contains 'run' | Should -Be $true

            $CommandText = & $module Expand-GitProxyCommand 'Invoke-GitFunction s'
            $result2 = & $module GitTabExpansionInternal $CommandText

            $result2 -contains 'start' | Should -Be $true
            $result2 -contains 'skip' | Should -Be $true
        }
        It 'Tab completes remote subcommands' {
            function global:Invoke-GitFunction { git remote $args }
            $CommandText = & $module Expand-GitProxyCommand 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $CommandText

            $result -contains '' | Should -Be $false
            $result -contains 'add' | Should -Be $true
            $result -contains 'set-branches' | Should -Be $true
            $result -contains 'get-url' | Should -Be $true
            $result -contains 'update' | Should -Be $true

            $CommandText = & $module Expand-GitProxyCommand 'Invoke-GitFunction s'
            $result2 = & $module GitTabExpansionInternal $CommandText

            $result2 -contains 'set-branches' | Should -Be $true
            $result2 -contains 'set-head' | Should -Be $true
            $result2 -contains 'set-url' | Should -Be $true
        }
    }
}
