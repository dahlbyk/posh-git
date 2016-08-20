posh-git
========

A set of PowerShell scripts that integrate Git and PowerShell.
### Prompt for Git repositories
   The prompt in Git repositories show the current branch and the status of files (additions, modifications, deletions).

### Tab completion
   Provides tab completion for common commands when using git.
   E.g. `git ch<tab>` --> `git checkout`

Notes
-----
Posh-git adds variables to your session to let you customize it, including `$GitPromptSettings`, `$GitTabSettings`, and `$TortoiseGitSettings`. For an example of integrating the tab completion and/or git prompt into your profile, see `profile.example.ps1`. 

Note on performance: Displaying file status in the git prompt for a very large repo can be prohibitively slow. Rather than turn off file status entirely, you can disable it on a repo-by-repo basis by adding individual repository paths to $GitPromptSettings.RepositoriesInWhichToDisableFileStatus.


Installing Posh-git with PowerShellGet
-----------------------------
The PowerShellGet module is installed with Windows PowerShell 5.0 and greater. To get PowerShellGet (and the PackageManagement module that it requires) for PowerShell 3.0 and 4.0, use the [PackageManagement PowerShell Modules Preview](https://www.microsoft.com/en-us/download/details.aspx?id=51451) in the Microsoft Download Center. 

PackageManagement and PowerShellGet are available for PowerShell on Mac OS X and Linux, but are not yet working correctly. Check frequently for updates: [PowerShellGet Issues](https://github.com/PowerShell/PowerShell/labels/Area-PowerShellGet)

If PowerShellGet is installed, to install posh-git:

```
Install-Module posh-git
```

To download the module without installing it:

```
Save-Module posh-git
```


Installing (manual)
-------------------

**Pre-requisites:**

<!---
Previous version said that PowerShell 2.0 is deprecated. Although people have requested that it be deprecated, I don't think it has been, so I removed that line.
-->

0. Verify that you have PowerShell 2.0 or greater (`$PSVersionTable.PSVersion`). PowerShell 3.0 is preferred. 

1. Use `Get-ExecutionPolicy` to verify that the local execution policy allows you to run scripts. `RemoteSigned` or `Unrestricted` are sufficient. 
To change the execution policy so that scripts can run, start PowerShell with the 'Run as Administrator' option and then use `Set-ExecutionPolicy`. For example: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

2. Verify that `git` can run in the PowerShell console. If you get a  "command not found" error, you need to add a git alias or add `%ProgramFiles(x86)%\Git\cmd` (or `%ProgramFiles%\Git\cmd` if you're still on 32-bit) to your `PATH` environment variable.


Then do this:

```
git clone https://github.com/dahlbyk/posh-git.git
cd posh-git
.\install.ps1
. $PROFILE
```

And you're set!

The Prompt
----------

PowerShell generates its prompt by executing a `prompt` function, if one exists. posh-git defines such a function in `profile.example.ps1` that outputs the current working directory followed by an abbreviated `git status`:

    C:\Users\Keith [master ≡]>

By default, the status summary has the following format:

    [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]

* ` [` (`BeforeText`)
* `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
 * Cyan means the branch matches its remote
 * Green means the branch is ahead of its remote (green light to push)
 * Red means the branch is behind its remote
 * Yellow means the branch is both ahead of and behind its remote
* S represents the branch status in relation to remote (tracked origin) branch
  * ≡ = The local branch in at the same commit level as the remote branch (`BranchIdenticalStatus`)
  * ↑ = The local branch is ahead of the remote branch, a 'git push' is required to update the remote branch (`BranchAheadStatus`)
  * ↓ = The local branch is behind the remote branch, a 'git pull' is required to update the local branch (`BranchBehindStatus`)
  * ↕ = The local branch is both ahead and behind the remote branch, a rebase of the local branch is required before pushing local changes to the remote branch (`BranchBehindAndAheadStatus`)
* ABCD represent the index; ` | ` (`DelimText`); EFGH represent the working directory
 * `+` = Added files
 * `~` = Modified files
 * `-` = Removed files
 * `!` = Conflicted files
 * As in `git status`, index status is dark green and working directory status is dark red
* 
* W represents the status of the working folder
 * `!` = There are untracked changes in the working tree (`LocalStagedStatus`)
 * `~` = There are staged changes in the working tree waiting to be committed (`LocalWorkingStatus`)
 * None = There are no uncommitted or unstaged changes to the working tree (`LocalDefault`)
* `]` (`AfterText`)

The symbols and surrounding text can be customized by the corresponding properties on `$GitPromptSettings`.

For example, a status of `[master ≡ +0 ~2 -1 | +1 ~1 -0]` corresponds to the following `git status`:

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
