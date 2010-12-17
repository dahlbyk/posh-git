posh-git
========

A set of PowerShell scripts which provide Git/PowerShell integration

### Prompt for Git repositories
   The prompt within Git repositories can show the current branch and the state of files (additions, modifications, deletions) within.
   
### Tab completion
   Provides tab completion for common commands when using git.  
   E.g. `git ch<tab>` --> `git checkout`
   
Usage
-----

See `profile.example.ps1` as to how you can integrate the tab completion and/or git prompt into your own profile.
Prompt formatting, among other things, can be customized using `$GitPromptSettings`, `$GitTabSettings` and `$TortoiseGitSettings`.

Installing
----------

0. Verify you have PowerShell 2.0 or better with $PSVersionTable.PSVersion

1. Verify execution of scripts is allowed with `Get-ExecutionPolicy` (should be `RemoteSigned` or `Unrestricted`). If scripts are not enabled, run PowerShell as Administrator and call `Set-ExecutionPolicy RemoteSigned -Confirm`.

2. Verify that `git` can be run from PowerShell. If the command is not found, you will need to add a git alias or add `%ProgramFiles%\Git\cmd` to your PATH environment variable.

3. Clone the posh-git repository to your local machine.

4. From the posh-git repository directory, run `.\install.ps1`.

5. Enjoy!


### Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
