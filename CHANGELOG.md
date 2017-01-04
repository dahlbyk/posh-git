Changelog
=========

v0.7.0 - 2017-01-11
----------------------------
- Performance of Get-GitStatus on large repos has been improved
- Fix crash on PowerShell Core due to missing .NET types for WindowsIdentity/Principal
- Fix syntax error on setenv calls
- Fix temp path issue with ~ in 8.3 filenames
- Fix inable to find type [EnvironmentVariableTarget] on PowerShell v6
- Remove error thrown by symbolic-ref and describe
- Update module import so that it sets the prompt function *iff* the user does not have a customized prompt function ([#217](https://github.com/dahlbyk/posh-git/issues/217))
- Update profile.example.ps1 to remove prompt function and tweak how module is imported
- Add about_posh-git help topic
- Add new branch status to indicate upstream is gone ([#326](https://github.com/dahlbyk/posh-git/pull/326))
- Add ahead/behind count to prompt ([#256](https://github.com/dahlbyk/posh-git/pull/256))
- Add BranchBehindAndAheadDisplay setting to control count display (Full (default), Compact, Minimal)
