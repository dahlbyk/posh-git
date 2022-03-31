@{

# Script module or binary module file associated with this manifest.
RootModule = 'posh-git.psm1'

# Version number of this module.
ModuleVersion = '1.1.0'

# ID used to uniquely identify this module
GUID = '74c9fd30-734b-4c89-a8ae-7727ad21d1d5'

# Author of this module
Author = 'Keith Dahlby, Keith Hill, and contributors'

# Copyright statement for this module
Copyright = '(c) 2010-2021 Keith Dahlby, Keith Hill, and contributors'

# Description of the functionality provided by this module
Description = 'Provides prompt with Git status summary information and tab completion for Git commands, parameters, remotes and branch names.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Functions to export from this module
FunctionsToExport = @(
    'Add-PoshGitToProfile',
    'Expand-GitCommand',
    'Format-GitBranchName',
    'Get-GitBranchStatusColor',
    'Get-GitStatus',
    'Get-GitDirectory',
    'Get-PromptConnectionInfo',
    'Get-PromptPath',
    'New-GitPromptSettings',
    'Remove-GitBranch',
    'Remove-PoshGitFromProfile',
    'Update-AllBranches',
    'Write-GitStatus',
    'Write-GitBranchName',
    'Write-GitBranchStatus',
    'Write-GitIndexStatus',
    'Write-GitStashCount',
    'Write-GitWorkingDirStatus',
    'Write-GitWorkingDirStatusSummary',
    'Write-Prompt',
    'Write-VcsStatus',
    'TabExpansion',
    'tgit'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @('GitPromptScriptBlock')

# Aliases to export from this module
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess.
# This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('git', 'prompt', 'tab', 'tab-completion', 'tab-expansion', 'tabexpansion', 'PSEdition_Core')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/dahlbyk/posh-git/blob/v1.1.0/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/dahlbyk/posh-git'

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/dahlbyk/posh-git/blob/v1.1.0/CHANGELOG.md'
    }
}
}
