# posh-git Release History

## 0.7.0 - January 31, 2017
This release has focused on improving the "getting started" experience by adding an `Add-PoshGitToProfile` command that
modifies the user's PowerShell profile script to import the posh-git module whenever PowerShell starts.
When posh-git is imported, it will automatically install a posh-git prompt that displays Git status summary information.
Work was also done to improve performance of Get-GitStatus when inside large Git repositories.
Work was begun to eliminate some obvious crashes on PowerShell on .NET Core but more work remains to be done.

- Performance of Get-GitStatus on large repos has been improved
- Fix crash on PowerShell Core due to missing .NET types for WindowsIdentity/Principal
- Fix syntax error on setenv calls
- Fix temp path issue with ~ in 8.3 filenames
- Fix unable to find type [EnvironmentVariableTarget] in PowerShell on .NET Core
- Fix support for bare repository ([#291](https://github.com/dahlbyk/posh-git/issues/291))
- Fewer errors generated in global $Error collection
- Remove error thrown by symbolic-ref and describe
- Update module import so that it sets the prompt function *iff* the user does not have a customized prompt function ([#217](https://github.com/dahlbyk/posh-git/issues/217))
- Update profile.example.ps1 to remove prompt function and tweak how module is imported
- Add new commmand Add-PoshGitToProfile
- Add about_posh-git help topic
- Add new branch status to indicate upstream is gone ([#326](https://github.com/dahlbyk/posh-git/pull/326))
- Add ahead/behind count to prompt ([#256](https://github.com/dahlbyk/posh-git/pull/256))
- Add BranchBehindAndAheadDisplay setting to control count display (Full (default), Compact, Minimal)
