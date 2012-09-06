posh-hg
========

Inspired by the Posh-Git project (http://github.com/dahlbyk/posh-git), Posh-Hg provides a set of PowerShell scripts which provide Mercurial/PowerShell integration

### Prompt for Hg repositories
   The prompt within Hg repositories can show the current branch and the state of files (additions, modifications, deletions) within.
   
### Tab completion
   Provides tab completion for common commands when using hg.  
   E.g. `hg up<tab>` --> `hg update`
   
Usage
-----

See `profile.example.ps1` as to how you can integrate the tab completion and/or hg prompt into your own profile.
Prompt formatting, among other things, can be customized using the `$PoshHgSettings` variable. 

Installing
----------

0. Verify you have PowerShell 2.0 or better with $PSVersionTable.PSVersion

1. Verify execution of scripts is allowed with `Get-ExecutionPolicy` (should be `RemoteSigned` or `Unrestricted`). If scripts are not enabled, run PowerShell as Administrator and call `Set-ExecutionPolicy RemoteSigned -Confirm`.

2. Verify that `hg` can be run from PowerShell. If the command is not found, you will need to add a hg alias or add `%ProgramFiles%\TortoiseHg` to your PATH environment variable.

3. Clone the posh-hg repository to your local machine.

4. From the posh-hg repository directory, run `.\install.ps1`.

5. Enjoy!

The Prompt
----------

PowerShell generates its prompt by executing a `prompt` function, if one exists. posh-hg defines such a function in `profile.example.ps1` that outputs the current working directory followed by an abbreviated `hg status`:

    C:\Users\JSkinner [default]>

By default, the status summary has the following format:

    [{HEAD-name} +A ~B -C ?D !E ^F]

* `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
 * Cyan means the branch matches its remote
 * Red means the branch is behind its remote
* ABCDEF represent the working directory
 * `+` = Added files
 * `~` = Modified files
 * `-` = Removed files
 * `?` = Untracked files
 * `!` = Missing files
 * `^` = Renamed files

Additionally, Posh-Hg can show any tags and bookmarks in the prompt as well as MQ patches if the MQ extension is enabled (disabled by default)

### Based on work by:

 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/