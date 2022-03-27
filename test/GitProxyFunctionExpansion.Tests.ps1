BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'Proxy Function Expansion Tests' {
    Context 'Proxy Function Name TabExpansion Tests' {
        BeforeEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
            if (Test-Path -Path Alias:\igf) {
                Rename-Item -Path Alias:\igf -NewName igfbackup
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
        }
        AfterEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if (Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item Function:\Invoke-GitFunctionBackup Invoke-GitFunction
            }
            if (Test-Path -Path Alias:\igf) {
                Remove-Item -Path Alias:\igf
            }
            if (Test-Path -Path Alias:\igfbackup) {
                Rename-Item -Path Alias:\igfbackup -NewName igf
            }
        }
        It 'Expands a proxy function with parameters' {
            function global:Invoke-GitFunction { git checkout $args }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction -b newbranch'
            $result | Should -Be 'git checkout -b newbranch'
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf -b newbranch')
        }
        It 'Expands a multiline proxy function' {
            function global:Invoke-GitFunction { git checkout $args }
            $result = & $module Expand-GitProxyFunction "Invoke-GitFunction ```r`n-b ```r`nnewbranch"
            $result | Should -Be 'git checkout -b newbranch'
            $result | Should -Be (& $module Expand-GitProxyFunction "igf ```r`n-b ```r`nnewbranch")
        }
        It 'Does not expand the proxy function name if there is no preceding whitespace before backtick newlines' {
            function global:Invoke-GitFunction { git checkout $args }
            & $module Expand-GitProxyFunction "Invoke-GitFunction```r`n-b```r`nnewbranch" | Should -Be "Invoke-GitFunction```r`n-b```r`nnewbranch"
            & $module Expand-GitProxyFunction "igf```r`n-b```r`nnewbranch" | Should -Be "igf```r`n-b```r`nnewbranch"
        }
        It 'Does not expand the proxy function name if there is no preceding non-newline whitespace before any backtick newlines' {
            function global:Invoke-GitFunction { git checkout $args }
            & $module Expand-GitProxyFunction "Invoke-GitFunction ```r`n-b```r`nnewbranch" | Should -Be "Invoke-GitFunction ```r`n-b```r`nnewbranch"
            & $module Expand-GitProxyFunction "igf ```r`n-b```r`nnewbranch" | Should -Be "igf ```r`n-b```r`nnewbranch"
        }
        It 'Does not expand the proxy function name if the preceding whitespace before backtick newlines are newlines' {
            function global:Invoke-GitFunction { git checkout $args }
            & $module Expand-GitProxyFunction "Invoke-GitFunction`r`n```r`n-b`r`n```r`nnewbranch" | Should -Be "Invoke-GitFunction`r`n```r`n-b`r`n```r`nnewbranch"
            & $module Expand-GitProxyFunction "igf`r`n```r`n-b`r`n```r`nnewbranch" | Should -Be "igf`r`n```r`n-b`r`n```r`nnewbranch"
        }
        It 'Does not expand the proxy function if there is no trailing space' {
            function global:Invoke-GitFunction { git checkout $args }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction' | Should -Be 'Invoke-GitFunction'
            & $module Expand-GitProxyFunction 'igf' | Should -Be 'igf'
        }
    }
    Context 'Proxy Function Definition Expansion Tests' {
        BeforeEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
            if (Test-Path -Path Alias:\igf) {
                Rename-Item -Path Alias:\igf -NewName igfbackup
            }
            New-Alias -Name 'igf' -Value Invoke-GitFunction -Scope 'Global'
        }
        AfterEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if (Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item Function:\Invoke-GitFunctionBackup Invoke-GitFunction
            }
            if (Test-Path -Path Alias:\igf) {
                Remove-Item -Path Alias:\igf
            }
            if (Test-Path -Path Alias:\igfbackup) {
                Rename-Item -Path Alias:\igfbackup -NewName igf
            }
        }
        It 'Expands a single line function' {
            function global:Invoke-GitFunction {
                git checkout $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands a single line function with short parameter' {
            function global:Invoke-GitFunction {
                git checkout -b $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout -b '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands a single line function with long parameter' {
            function global:Invoke-GitFunction {
                git checkout --detach $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout --detach '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands a single line with piped function suffix' {
            function global:Invoke-GitFunction {
                git checkout --detach $args | Write-Host
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout --detach '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands the first line in function' {
            function global:Invoke-GitFunction {
                git checkout $args
                $a = 5
                Write-Host $null
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands the middle line in function' {
            function global:Invoke-GitFunction {
                $a = 5
                git checkout $args
                Write-Host $null
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands the last line in function' {
            function global:Invoke-GitFunction {
                $a = 5
                Write-Host $null
                git checkout $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands semicolon delimited functions' {
            function global:Invoke-GitFunction {
                $a = 5; git checkout $args; Write-Host $null;
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands mixed semicolon delimited and newline functions' {
            function global:Invoke-GitFunction {
                $a = 5; Write-Host $null
                git checkout $args; Write-Host $null;
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands mixed semicolon delimited and newline multiline functions' {
            function global:Invoke-GitFunction {
                $a = 5; Write-Host $null
                git `
                    checkout `
                    $args; Write-Host $null;
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands simultaneously semicolon delimited and newline functions' {
            function global:Invoke-GitFunction {
                $a = 5;
                Write-Host $null;
                git checkout $args;
                Write-Host $null;
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands multiline function' {
            function global:Invoke-GitFunction {
                git `
                    checkout `
                    $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands multiline function that terminates with semicolon on new line' {
            function global:Invoke-GitFunction {
                git `
                    checkout `
                    $args `
                    ;
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands multiline function with short parameter' {
            function global:Invoke-GitFunction {
                git `
                    checkout `
                    -b `
                    $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout -b '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Expands multiline function with long parameter' {
            function global:Invoke-GitFunction {
                git `
                    checkout `
                    --detach `
                    $args
            }
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result | Should -Be 'git checkout --detach '
            $result | Should -Be (& $module Expand-GitProxyFunction 'igf ' )
        }
        It 'Does not expand a single line with piped function prefix' {
            function global:Invoke-GitFunction {
                "master" | git checkout --detach $args
            }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction ' | Should -Be 'Invoke-GitFunction '
            & $module Expand-GitProxyFunction 'igf ' | Should -Be 'igf '
        }
        It 'Does not expand function if $args is not present' {
            function global:Invoke-GitFunction {
                git checkout
            }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction ' | Should -Be 'Invoke-GitFunction '
            & $module Expand-GitProxyFunction 'igf ' | Should -Be 'igf '
        }
        It 'Does not expand function if $args is not attached to the git function' {
            function global:Invoke-GitFunction {
                $a = 5
                git checkout
                Write-Host $args
            }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction ' | Should -Be 'Invoke-GitFunction '
            & $module Expand-GitProxyFunction 'igf ' | Should -Be 'igf '
        }
        It 'Does not expand multiline function if $args is not attached to the git function' {
            function global:Invoke-GitFunction {
                $a = 5
                git `
                    checkout
                Write-Host $args
            }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction ' | Should -Be 'Invoke-GitFunction '
            & $module Expand-GitProxyFunction 'igf ' | Should -Be 'igf '
        }
        It 'Does not expand multiline function backtick newlines are not preceded with whitespace' {
            function global:Invoke-GitFunction {
                $a = 5
                git`
                checkout`
                $args
                Write-Host $null
            }
            & $module Expand-GitProxyFunction 'Invoke-GitFunction ' | Should -Be 'Invoke-GitFunction '
            & $module Expand-GitProxyFunction 'igf ' | Should -Be 'igf '
        }
    }
    Context 'Proxy Function Parameter Replacement Tests' {
        BeforeEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
            function global:Invoke-GitFunction { git checkout $args }
        }
        AfterEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if (Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item Function:\Invoke-GitFunctionBackup Invoke-GitFunction
            }
        }
        It 'Replaces parameter in $args' {
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction master'
            $result | Should -Be 'git checkout master'
        }
        It 'Replaces short parameter in $args' {
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction -b master'
            $result | Should -Be 'git checkout -b master'
        }
        It 'Replaces long parameter in $args' {
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction --detach master'
            $result | Should -Be 'git checkout --detach master'
        }
        It 'Replaces mixed parameters in $args' {
            $result = & $module Expand-GitProxyFunction 'Invoke-GitFunction -q -f -m --detach master'
            $result | Should -Be 'git checkout -q -f -m --detach master'
        }
    }
    Context 'Proxy Subcommand TabExpansion Tests' {
        BeforeEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Rename-Item -Path Function:\Invoke-GitFunction -NewName Invoke-GitFunctionBackup
            }
        }
        AfterEach {
            if (Test-Path -Path Function:\Invoke-GitFunction) {
                Remove-Item -Path Function:\Invoke-GitFunction
            }
            if (Test-Path -Path Function:\Invoke-GitFunctionBackup) {
                Rename-Item -Path Function:\Invoke-GitFunctionBackup -NewName Invoke-GitFunction
            }
        }
        It 'Tab completes without subcommands' {
            function global:Invoke-GitFunction { git whatever $args }
            $functionText = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $functionText

            $result | Should -Be @()
        }
        It 'Tab completes bisect subcommands' {
            function global:Invoke-GitFunction { git bisect $args }
            $functionText = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $functionText

            $result -contains '' | Should -Be $false
            $result -contains 'start' | Should -Be $true
            $result -contains 'run' | Should -Be $true

            $functionText = & $module Expand-GitProxyFunction 'Invoke-GitFunction s'
            $result2 = & $module GitTabExpansionInternal $functionText

            $result2 -contains 'start' | Should -Be $true
            $result2 -contains 'skip' | Should -Be $true
        }
        It 'Tab completes remote subcommands' {
            function global:Invoke-GitFunction { git remote $args }
            $functionText = & $module Expand-GitProxyFunction 'Invoke-GitFunction '
            $result = & $module GitTabExpansionInternal $functionText

            $result -contains '' | Should -Be $false
            $result -contains 'add' | Should -Be $true
            $result -contains 'set-branches' | Should -Be $true
            $result -contains 'get-url' | Should -Be $true
            $result -contains 'update' | Should -Be $true

            $functionText = & $module Expand-GitProxyFunction 'Invoke-GitFunction s'
            $result2 = & $module GitTabExpansionInternal $functionText

            $result2 -contains 'set-branches' | Should -Be $true
            $result2 -contains 'set-head' | Should -Be $true
            $result2 -contains 'set-url' | Should -Be $true
        }
    }
}
