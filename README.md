# posh-git

[![Build status](https://ci.appveyor.com/api/projects/status/eb8erd5afaa01w80?svg=true)](https://ci.appveyor.com/project/dahlbyk/posh-git)
[![Join the chat at https://gitter.im/dahlbyk/posh-git](https://badges.gitter.im/dahlbyk/posh-git.svg)](https://gitter.im/dahlbyk/posh-git?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

posh-git is a PowerShell module that integrates Git and PowerShell by providing Git status summary information that can be displayed in the PowerShell prompt, e.g.:
```
C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 !]>
```
posh-git also provides tab completion support for common git commands, branch names, paths and more.
For example, with posh-git, PowerShell can tab complete git commands like `checkout` by typing `git ch` and pressing the <kbd>tab</kbd> key.
That will tab complete to `git checkout` and if you keep pressing <kbd>tab</kbd>, it will cycle through other command matches such as `cherry` and `cherry-pick`.
You can also tab complete remote names and branch names e.g.: `git pull or<tab> ma<tab>` tab completes to `git pull origin master`.

## Notes
Posh-git adds variables to your session to let you customize it, including `$GitPromptSettings`, `$GitTabSettings`, and `$TortoiseGitSettings`.
For an example of how to configure your PowerShell profile script to import the posh-git module and create a custom prompt function that displays git status info, see the [Customizing Your PowerShell Prompt](https://github.com/dahlbyk/posh-git#step-3-optional-customize-your-powershell-prompt) section below.

Note on performance: Displaying file status in the git prompt for a very large repo can be prohibitively slow.
Rather than turn off file status entirely (`$GitPromptSettings.EnableFileStatus = $false`), you can disable it on a repo-by-repo basis by adding individual repository paths to `$GitPromptSettings.RepositoriesInWhichToDisableFileStatus`.

## Installation
### Prerequisites
Before installing posh-git make sure the following prerequisites have been met.

1. PowerShell 2.0 or higher. Check your PowerShell version by executing `$PSVersionTable.PSVersion`.

2. Script execution policy must be set to either `RemoteSigned` or `Unrestricted`.
   Check the script execution policy setting by executing `Get-ExecutionPolicy`.
   If the policy is not set to one of the two required values, run PowerShell as Administrator and execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

3. Git must be installed and available via the PATH environment variable.
   Check that `git` is accessible from PowerShell by executing `git --version` from PowerShell.
   If `git` is not recognized as the name of a command verify that you have Git installed.
   If not, install Git from [https://git-scm.com](https://git-scm.com).
   If you have Git installed, make sure the path to git.exe is in your PATH environment variable.

### Installing posh-git via PowerShellGet
If you are on PowerShell version 5 or higher, execute the command below to install from the [PowerShell Gallery](https://www.powershellgallery.com/):

```
PowerShellGet\Install-Module posh-git -Scope CurrentUser
```
You may be asked if you trust packages coming from the PowerShell Gallery. Answer yes to allow installation of this module to proceed.

If you are on PowerShell version 3 or 4, you will need to install the [Package Management Preview for PowerShell 3 & 4](https://www.microsoft.com/en-us/download/details.aspx?id=51451) in order to run the command above.

Note: If you get an error message from Install-Module about NuGet being required to interact with NuGet-based repositories, execute the following commands to bootstrap the NuGet provider:
```
Install-PackageProvider NuGet -Force
Import-PackageProvider NuGet -Force
```
Then retry the Install-Module command above.

After you have successfully installed the posh-git module from the PowerShell Gallery, you will be able to update to a newer version by executing the command:
```
Update-Module posh-git
```

### Installing posh-git via Chocolatey
If you have PowerShell version 2 or are having issues using Install-Module with PowerShell version 3 or 4, you can use [Chocolatey](https://chocolatey.org) to install posh-git.
If you don't have Chocolatey, you can install it from the [Chocolately Install page](https://chocolatey.org/install).
With Chocolatey installed, execute the following command to install posh-git:
```
choco install poshgit
```

## Using posh-git
After you have installed posh-git, you need to configure your PowerShell session to use the posh-git module.

### Step 1: Import posh-git
The first step is to import the module into your PowerShell session which will enable git tab completion.
You can do this with the command `Import-Module posh-git`.

### Step 2: Import posh-git from Your PowerShell Profile
You do not want to have to manually execute the `Import-Module` command every time you open a new PowerShell prompt.
Let's have PowerShell import this module for you in each new PowerShell session.
We can do this by either executing the command `Add-PoshGitToProfile` or by editing your PowerShell profile script and adding the command `Import-Module posh-git`.

If you want posh-git to be available in all your PowerShell hosts (console, ISE, etc) then execute `Add-PoshGitToProfile -AllHosts`.
This will add a line containing `Import-Module posh-git` to the file `$profile.CurrentUserAllHosts`.
If you want posh-git to be available in just the current host, then execute `Add-PoshGitToProfile`.
This will add the same command but to the file `$profile.CurrentUserCurrentHost`.

If you'd prefer, you can manually edit the desired PowerShell profile script.
Open (or create) your profile script with the command `notepad $profile.CurrentUserAllHosts`.
In the profile script, add the following line:
```
Import-Module posh-git
```
Save the profile script, then close PowerShell and open a new PowerShell session.
Type `git fe` and then press <kbd>tab</kbd>. If posh-git has been imported, that command should tab complete to `git fetch`.

### Step 3 (optional): Customize Your PowerShell Prompt
By default, posh-git will update your PowerShell prompt function to display Git status summary information when the current dir is inside a Git repository.
posh-git will not update your PowerShell prompt function if you have your own, customized prompt function that has been defined before importing posh-git.

The posh-git prompt is a single line prompt that looks like this:
```
C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 !]>
```
You can customize the posh-git prompt or define your own custom prompt function.
The most common customization for the posh-git provided prompt is to make it span two lines which can be done with the following command:
```
$GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1)) '
```
This will change the prompt to:
```
C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 !]
>
```
You can also customize the default prompt prefix text e.g.:
```
$GitPromptSettings.DefaultPromptPrefix = '[$(hostname)] '
```
This will change the prompt to:
```
[KEITH1] C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 !]>
```
And if you would prefer to have any path under your home directory abbreviated with ~, you can change this setting:
```
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
```
This will change the prompt to the one shown below:
```
~\GitHub\posh-git [master ≡ +0 ~1 -0 !]>
```

You can also create your own prompt function to show whatever information you want.
See the [Customizing Your PowerShell Prompt](https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt) wiki page for details.

## Git Status Summary Information
The Git status summary information provides a wealth of "Git status" information at a glance, all the time in your prompt.

By default, the status summary has the following format:

    [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]

* ` [` (`BeforeText`)
* `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
 * Cyan means the branch matches its remote
 * Green means the branch is ahead of its remote (green light to push)
 * Red means the branch is behind its remote
 * Yellow means the branch is both ahead of and behind its remote
* S represents the branch status in relation to remote (tracked origin) branch. Note: This information reflects the state of the remote tracked branch after the last `git fetch/pull` of the remote.
  * ≡ = The local branch in at the same commit level as the remote branch (`BranchIdenticalStatus`)
  * ↑`<num>` = The local branch is ahead of the remote branch by the specified number of commits; a 'git push' is required to update the remote branch (`BranchAheadStatus`)
  * ↓`<num>` = The local branch is behind the remote branch by the specified number of commits; a 'git pull' is required to update the local branch (`BranchBehindStatus`)
  * `<a>`↕`<b>` = The local branch is both ahead of the remote branch by the specified number of commits (a) and behind by the specified number of commits (b); a rebase of the local branch is required before pushing local changes to the remote branch (`BranchBehindAndAheadStatus`).  NOTE: this status is only available if $GitPromptSettings.BranchBehindAndAheadDisplay is set to 'Compact'.
  * × = The local branch is tracking a branch that is gone from the remote (`BranchGoneStatus')
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

## Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
