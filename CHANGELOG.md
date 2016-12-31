Changelog
=========

v0.7.0 - 2016-12-30
----------------------------
- Performance of Get-GitStatus on large repos has been improved
- Fix crash on PowerShell Core due to missing .NET types for WindowsIdentity/Principal
- Fix syntax error on setenv calls
- Fix temp path issue with ~ in 8.3 filenames
- Fix inable to find type [EnvironmentVariableTarget] on PowerShell v6
- Remove error thrown by symbolic-ref and describe
- Add about_posh-git help topic
- profile.example.ps1 updated
- Add new branch status to indicate upstream is gone ([#326](https://github.com/dahlbyk/posh-git/pull/326))
- Add ahead/behind count to prompt ([#256](https://github.com/dahlbyk/posh-git/pull/256))
- Add BranchBehindAndAheadDisplay setting to control count display (Full (default), Compact, Minimal)
