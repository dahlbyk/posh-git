BeforeAll {
    . $PSScriptRoot\Shared.ps1
    . $PSScriptRoot\ParamValidationUtils.ps1
}

Describe 'ParamValidationUtils Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $repoPath = NewGitTempRepo -MakeInitialCommit
    }

    AfterAll {
        RemoveGitTempRepo $repoPath
    }

    Context 'Catching long params errors' {
        It 'Command with correct long param does not contains params errors' {
            $errorStream = GetErrorStream -command "$gitbin help --info"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $false
        }

        It 'Incorrect command usage with valid long param does not contains params errors' {
            # Returns usage info
            $errorStream = GetErrorStream -command "$gitbin bisect --no-checkout"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $false
        }

        It 'Failed command with valid long params does not contains params errors' {
            # Returns: fatal: There is no merge to abort (MERGE_HEAD missing).
            $errorStream = GetErrorStream -command "$gitbin merge --abort"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $false
        }

        It 'Command with invalid long param contains errors' {
            # Returns: error: invalid option: --bad-param-option
            $errorStream = GetErrorStream -command "$gitbin diff --bad-param-option"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $true
        }

        It 'Command with unknow long param contains errors' {
            # Returns: error: unknown option `--bad-param-option'
            # and usage info
            $errorStream = GetErrorStream -command "$gitbin blame --bad-param-option"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $true
        }

        It 'Command with unrecognized long param contains error' {
            # Returns: fatal: unrecognized argument: --bad-param-option
            $errorStream = GetErrorStream -command "$gitbin show --bad-param-option"
            $result = IsStreamContainsInvalidParamsErrors -errorStream $errorStream

            $result | Should -be $true
        }
    }
}
