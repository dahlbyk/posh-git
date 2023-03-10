BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe 'ParamsTabExpansion Tests' {
    Context 'Push Parameters TabExpansion Tests' {
        It 'Tab completes all long push parameters' {
            $result = & $module GitTabExpansionInternal 'git push --'
            $result | Should -Contain '--all'
            $result | Should -Contain '--delete'
            $result | Should -Contain '--dry-run'
            $result | Should -Contain '--exec='
            $result | Should -Contain '--follow-tags'
            $result | Should -Contain '--force'
            $result | Should -Contain '--force-with-lease'
            $result | Should -Contain '--mirror'
            $result | Should -Contain '--no-force-with-lease'
            $result | Should -Contain '--no-thin'
            $result | Should -Contain '--no-verify'
            $result | Should -Contain '--porcelain'
            $result | Should -Contain '--progress'
            $result | Should -Contain '--prune'
            $result | Should -Contain '--quiet'
            $result | Should -Contain '--receive-pack='
            $result | Should -Contain '--recurse-submodules='
            $result | Should -Contain '--repo='
            $result | Should -Contain '--set-upstream'
            $result | Should -Contain '--tags'
            $result | Should -Contain '--thin'
            $result | Should -Contain '--verbose'
            $result | Should -Contain '--verify'
        }
        It 'Tab completes all short push parameters' {
            $result = & $module GitTabExpansionInternal 'git push -'
            $result | Should -Contain '-f'
            $result | Should -Contain '-n'
            $result | Should -Contain '-q'
            $result | Should -Contain '-u'
            $result | Should -Contain '-v'
        }
        It 'Tab completes push parameters values' {
            $result = & $module GitTabExpansionInternal 'git push --recurse-submodules='
            $result | Should -Contain '--recurse-submodules=check'
            $result | Should -Contain '--recurse-submodules=on-demand'
        }
    }

    Context 'Pretty/Format TabCompletion Tests - No Custom Formats' {
        It 'Tab completes default formats for log --pretty' {
            $result = & $module GitTabExpansionInternal 'git log --pretty='
            $result | Should -Contain '--pretty=oneline'
            $result | Should -Contain '--pretty=short'
            $result | Should -Contain '--pretty=medium'
            $result | Should -Contain '--pretty=full'
            $result | Should -Contain '--pretty=fuller'
            $result | Should -Contain '--pretty=email'
            $result | Should -Contain '--pretty=raw'
        }
        It 'Tab completes default formats for log --format' {
            $result = & $module GitTabExpansionInternal 'git log --format='
            $result | Should -Contain '--format=oneline'
            $result | Should -Contain '--format=short'
            $result | Should -Contain '--format=medium'
            $result | Should -Contain '--format=full'
            $result | Should -Contain '--format=fuller'
            $result | Should -Contain '--format=email'
            $result | Should -Contain '--format=raw'
        }
        It 'Tab completes default formats for show --pretty' {
            $result = & $module GitTabExpansionInternal 'git show --pretty='
            $result | Should -Contain '--pretty=oneline'
            $result | Should -Contain '--pretty=short'
            $result | Should -Contain '--pretty=medium'
            $result | Should -Contain '--pretty=full'
            $result | Should -Contain '--pretty=fuller'
            $result | Should -Contain '--pretty=email'
            $result | Should -Contain '--pretty=raw'
        }
        It 'Tab completes default formats for show --format' {
            $result = & $module GitTabExpansionInternal 'git show --format='
            $result | Should -Contain '--format=oneline'
            $result | Should -Contain '--format=short'
            $result | Should -Contain '--format=medium'
            $result | Should -Contain '--format=full'
            $result | Should -Contain '--format=fuller'
            $result | Should -Contain '--format=email'
            $result | Should -Contain '--format=raw'
        }
    }

    Context 'Pretty/Format TabCompletion Tests - With Custom Formats' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $repoPath = NewGitTempRepo

            # Test with custom formats
            &$gitbin config pretty.birdseye "%C(auto)%h%d %s %C(bold blue)<%aN> %C(green)(%cr)%Creset"
            &$gitbin config pretty.test2 "%h%d %s <%aN> (%cr)"
        }
        AfterEach {
            RemoveGitTempRepo $repoPath
        }

        It 'Tab completes default and custom formats for log --pretty' {
            $result = & $module GitTabExpansionInternal 'git log --pretty='
            $result | Should -Contain '--pretty=oneline'
            $result | Should -Contain '--pretty=short'
            $result | Should -Contain '--pretty=medium'
            $result | Should -Contain '--pretty=full'
            $result | Should -Contain '--pretty=fuller'
            $result | Should -Contain '--pretty=email'
            $result | Should -Contain '--pretty=raw'
            $result | Should -Contain '--pretty=birdseye'
            $result | Should -Contain '--pretty=test2'
        }
        It 'Tab completes default and custom formats for log --format' {
            $result = & $module GitTabExpansionInternal 'git log --format='
            $result | Should -Contain '--format=oneline'
            $result | Should -Contain '--format=short'
            $result | Should -Contain '--format=medium'
            $result | Should -Contain '--format=full'
            $result | Should -Contain '--format=fuller'
            $result | Should -Contain '--format=email'
            $result | Should -Contain '--format=raw'
            $result | Should -Contain '--format=birdseye'
            $result | Should -Contain '--format=test2'
        }
        It 'Tab completes default and custom formats for show --pretty' {
            $result = & $module GitTabExpansionInternal 'git show --pretty='
            $result | Should -Contain '--pretty=oneline'
            $result | Should -Contain '--pretty=short'
            $result | Should -Contain '--pretty=medium'
            $result | Should -Contain '--pretty=full'
            $result | Should -Contain '--pretty=fuller'
            $result | Should -Contain '--pretty=email'
            $result | Should -Contain '--pretty=raw'
            $result | Should -Contain '--pretty=birdseye'
            $result | Should -Contain '--pretty=test2'
        }
        It 'Tab completes default and custom formats for show --format' {
            $result = & $module GitTabExpansionInternal 'git show --format='
            $result | Should -Contain '--format=oneline'
            $result | Should -Contain '--format=short'
            $result | Should -Contain '--format=medium'
            $result | Should -Contain '--format=full'
            $result | Should -Contain '--format=fuller'
            $result | Should -Contain '--format=email'
            $result | Should -Contain '--format=raw'
            $result | Should -Contain '--format=birdseye'
            $result | Should -Contain '--format=test2'
        }
    }
}

