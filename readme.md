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

Note on performance: displaying file status in the git prompt for a very large repo can be prohibitively slow. Rather than turn off file status entirely, you can disable it on a repo-by-repo basis by adding individual repository paths to $GitPromptSettings.RepositoriesInWhichToDisableFileStatus.

Installing
----------

0. Verify you have PowerShell 2.0 or better with $PSVersionTable.PSVersion

1. Verify execution of scripts is allowed with `Get-ExecutionPolicy` (should be `RemoteSigned` or `Unrestricted`). If scripts are not enabled, run PowerShell as Administrator and call `Set-ExecutionPolicy RemoteSigned -Confirm`.

2. Verify that `git` can be run from PowerShell. If the command is not found, you will need to add a git alias or add `%ProgramFiles%\Git\cmd` to your PATH environment variable.

3. Clone the posh-git repository to your local machine.

4. From the posh-git repository directory, run `.\install.ps1`.

5. Enjoy!

The Prompt
----------

PowerShell generates its prompt by executing a `prompt` function, if one exists. posh-git defines such a function in `profile.example.ps1` that outputs the current working directory followed by an abbreviated `git status`:

    C:\Users\Keith [master]>

By default, the status summary has the following format:

    [{HEAD-name} +A ~B -C !D | +E ~F -G !H]

* `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
 * Cyan means the branch matches its remote
 * Green means the branch is ahead of its remote (green light to push)
 * Red means the branch is behind its remote
 * Yellow means the branch is both ahead of and behind its remote
* ABCD represent the index; EFGH represent the working directory
 * `+` = Added files
 * `~` = Modified files
 * `-` = Removed files
 * `!` = Conflicted files
 * As in `git status`, index status is dark red and working directory status is dark green

For example, a status of `[master +0 ~2 -1 | +1 ~1 -0]` corresponds to the following `git status`:

    # On branch master
    #
    # Changes to be committed:
    #   (use "git reset HEAD <file>..." to unstage)
    #
    #        modified:   this-changed.txt
    #        modified:   this-too.txt
    #        deleted:    gone.ps1
    #
    # Changed but not updated:
    #   (use "git add <file>..." to update what will be committed)
    #   (use "git checkout -- <file>..." to discard changes in working directory)
    #
    #        modified:   not-staged.ps1
    #
    # Untracked files:
    #   (use "git add <file>..." to include in what will be committed)
    #
    #        new.file

### Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
