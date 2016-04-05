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

Installing via PsGet
--------------------

If you have [PsGet](http://psget.net/) installed just run:

```
Install-Module posh-git
```

Installing (manual)
-------------------

**Pre-requisites:**

0. Verify you have PowerShell 2.0 or better with `$PSVersionTable.PSVersion`. PowerShell 3.0 is preferred as 2.0 support is deprecated.

1. Verify execution of scripts is allowed with `Get-ExecutionPolicy` (should be `RemoteSigned` or `Unrestricted`). If scripts are not enabled, run PowerShell as Administrator and call `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

2. Verify that `git` can be run from PowerShell.
   If the command is not found, you will need to add a git alias or add `%ProgramFiles(x86)%\Git\cmd`
   (or `%ProgramFiles%\Git\cmd` if you're still on 32-bit) to your `PATH` environment variable.

Then do this:

```
git clone https://github.com/dahlbyk/posh-git.git
cd posh-git
.\install.ps1
```

And you're set!

The Prompt
----------

PowerShell generates its prompt by executing a `prompt` function, if one exists. posh-git defines such a function in `profile.example.ps1` that outputs the current working directory followed by an abbreviated `git status`:

    C:\Users\Keith [master]>

By default, the status summary has the following format:

    [{HEAD-name} +A ~B -C !D | +E ~F -G !H !]

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
 * As in `git status`, index status is dark green and working directory status is dark red
 * The trailing `!` means there are untracked files

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
