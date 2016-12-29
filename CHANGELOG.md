Changelog
=========

v1.0.0 - 2016-12-29
----------------------------
- Minimum supported version of PowerShell is now 3.0
- Performance of Get-GitStatus on large repos has been improved
- Fix crash on PowerShell Core due to missing .NET types for WindowsIdentity/Principal
- Fix syntax error on setenv calls
- Fix temp path issue with ~ in 8.3 filenames
- Fix inable to find type [EnvironmentVariableTarget] on PowerShell v6
- Remove error thrown by symbolic-ref and describe
- Add about_posh-git help topic
- profile.example.ps1 updated
