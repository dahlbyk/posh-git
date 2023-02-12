BeforeAll {
    . $PSScriptRoot\Shared.ps1
    . $PSScriptRoot\ParamValidationUtils.ps1
}

Describe 'TabExpansion Tests' {
    Context 'TabExpansion suggest valid long params' {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo -MakeInitialCommit
        }

        AfterAll {
            RemoveGitTempRepo $repoPath
        }

        It 'Suggest only valid long params for "add" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'add' -paramsToSkip @('--edit', '--interactive')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "bisect" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'bisect'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "branch" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'branch' -paramsToSkip @('--edit-description')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "checkout" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'checkout'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "cherry-pick" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'cherry-pick'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "clean" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'clean'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "clone" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'clone'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "commit" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'commit' -paramsToSkip @('--allow-empty', '--amend', '--edit')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "config" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'config' -paramsToSkip @('--edit')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "describe" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'describe'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "diff" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'diff'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "difftool" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'difftool'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "fetch" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'fetch'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "gc" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'gc'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "grep" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'grep'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "help" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'help'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "init" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'init'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "log" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'log' -paramsToSkip @('--stdin')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "merge" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'merge'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "mergetool" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'mergetool'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "mv" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'mv'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "prune" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'prune'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "pull" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'pull'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "push" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'push'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "rebase" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'rebase'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "reflog" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'reflog' @('--expire=', '--expire-unreachable=', '--rewrite', '--stale-fix', '--updateref', '--verbose')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "remote" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'remote'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "reset" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'reset'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "restore" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'restore'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "revert" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'revert'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "rm" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'rm'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "shortlog" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'shortlog'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "show" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'show'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "stash" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'stash' -paramsToSkip @('--index')

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "status" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'status'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "submodule" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'submodule'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "switch" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'switch'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "tag" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'tag'

            $invalidOptions | Should -BeNullOrEmpty
        }

        It 'Suggest only valid long params for "whatchanged" subcommand' {
            $invalidOptions = GetInvalidLongParams -subcommand 'whatchanged'

            $invalidOptions | Should -BeNullOrEmpty
        }
    }
}
