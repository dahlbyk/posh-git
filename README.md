# posh-git

[![Join the chat at https://gitter.im/dahlbyk/posh-git][gitter-img]][gitter]
[![PowerShell Gallery][psgallery-img]][psgallery-site]
[![posh-git on Chocolatey][choco-img]][choco-site]

Table of contents:

- [Overview](#overview)
- [Git Status Summary Information](#git-status-summary-information)
- [Customization variables](#customization-variables)
- [Supported version](#supported-versions)
- [Installation](#installation)
- [Using posh-git](#using-posh-git)
- [Based on work by](#based-on-work-by)

## Build status

| Windows (AppVeyor) | Linux/macOS (Travis | Code Coverage Status |
|--------------------|---------------------|----------------------|
| [![master build status][av-master-img]][av-master-site] | | [![master build coverage][cc-master-img]][cc-master-site] |
| [![develop build status][av-develop-img]][av-develop-site] | [![develop pscore build status][tv-develop-img]][tv-develop-site] | [![develop build coverage][cc-develop-img]][cc-develop-site] |

## Overview

posh-git is a PowerShell module that integrates Git and PowerShell by providing Git status summary information that can be displayed in the PowerShell prompt, e.g.:

![C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 | +0 ~1 -0 !]> ][prompt-def-long]

posh-git also provides tab completion support for common git commands, branch names, paths and more.
For example, with posh-git, PowerShell can tab complete git commands like `checkout` by typing `git ch` and pressing the <kbd>tab</kbd> key.
That will tab complete to `git checkout` and if you keep pressing <kbd>tab</kbd>, it will cycle through other command matches such as `cherry` and `cherry-pick`.
You can also tab complete remote names and branch names e.g.: `git pull or<tab> ma<tab>` tab completes to `git pull origin master`.

## Git Status Summary Information

The Git status summary information provides a wealth of "Git status" information at a glance, all the time in your prompt.

By default, the status summary has the following format:

    [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]

- `[` (`BeforeText`)
- `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
  - Cyan means the branch matches its remote
  - Green means the branch is ahead of its remote (green light to push)
  - Red means the branch is behind its remote
  - Yellow means the branch is both ahead of and behind its remote
- S represents the branch status in relation to remote (tracked origin) branch. Note: This information reflects the state of the remote tracked branch after the last `git fetch/pull` of the remote.
  - ≡ = The local branch in at the same commit level as the remote branch (`BranchIdenticalStatus`)
  - ↑`<num>` = The local branch is ahead of the remote branch by the specified number of commits; a `git push` is required to update the remote branch (`BranchAheadStatus`)
  - ↓`<num>` = The local branch is behind the remote branch by the specified number of commits; a `git pull` is required to update the local branch (`BranchBehindStatus`)
  - `<a>`↕`<b>` = The local branch is both ahead of the remote branch by the specified number of commits (a) and behind by the specified number of commits (b); a rebase of the local branch is required before pushing local changes to the remote branch (`BranchBehindAndAheadStatus`).  NOTE: this status is only available if `$GitPromptSettings.BranchBehindAndAheadDisplay` is set to `Compact`.
  - × = The local branch is tracking a branch that is gone from the remote (`BranchGoneStatus`)
- ABCD represent the index; `|` (`DelimText`); EFGH represent the working directory
  - `+` = Added files
  - `~` = Modified files
  - `-` = Removed files
  - `!` = Conflicted files
  - As in `git status`, index status is dark green and working directory status is dark red

- W represents the overall status of the working directory
  - `!` = There are unstaged changes in the working tree (`LocalWorkingStatus`)
  - `~` = There are uncommitted changes i.e. staged changes in the working tree waiting to be committed (`LocalStagedStatus`)
  - None = There are no unstaged or uncommitted changes to the working tree (`LocalDefault`)
- `]` (`AfterText`)

The symbols and surrounding text can be customized by the corresponding properties on `$GitPromptSettings`.

For example, a status of `[master ≡ +0 ~2 -1 | +1 ~1 -0]` corresponds to the following `git status`:

```powershell
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
```

## Customization variables

posh-git adds variables to your session to let you customize it, including `$GitPromptSettings`, `$GitTabSettings`, and `$TortoiseGitSettings`.
For an example of how to configure your PowerShell profile script to import the posh-git module and create a custom prompt function that displays git status info, see the [Customizing Your PowerShell Prompt](#step-3-optional-customize-your-powershell-prompt) section below.

Note on performance: Displaying file status in the git prompt for a very large repo can be prohibitively slow.
Rather than turn off file status entirely (`$GitPromptSettings.EnableFileStatus = $false`), you can disable it on a repo-by-repo basis by adding individual repository paths to `$GitPromptSettings.RepositoriesInWhichToDisableFileStatus`.

## Supported Versions

Two versions of posh-git are available to provide support for Windows PowerShell v2 up through PowerShell Core v6.

### posh-git v0.x

Version 0.x of posh-git continues to support Windows PowerShell versions 2, 3 and 4.
And if you don't need ANSI escape sequence support, v0.x can be used on Windows PowerShell v5.x.
See the v0.x [README][!!!PATH-TO-0x-README-HERE!!!] for installation instructions.

This version is being maintained on the branch:

- `master` avoids breaking changes, maintaining v0.x.
  ( [README](https://github.com/dahlbyk/posh-git/blob/master/README.md)
  • [CHANGELOG](https://github.com/dahlbyk/posh-git/blob/master/CHANGELOG.md) )

- Previous releases:
  - v0.7.1
    ( [README](https://github.com/dahlbyk/posh-git/blob/v0.7.1/README.md)
    • [CHANGELOG](https://github.com/dahlbyk/posh-git/blob/v0.7.1/CHANGELOG.md) )
  - v0.7.0
    ( [README](https://github.com/dahlbyk/posh-git/blob/v0.7.0/README.md)
    • [CHANGELOG](https://github.com/dahlbyk/posh-git/blob/v0.7.0/CHANGELOG.md) )

### posh-git v1.x

Version 1.x of posh-git is targeted specifically at Windows PowerShell 5.x and (cross-platform)
PowerShell Core 6.x.  It takes advantage of features only available in these versions such as the
class and enum keywords to better organize the `$GitPromptSettings` object.
Consequently this version of posh-git introduces BREAKING changes with 0.x which including dropping support
for Windows PowerShell version 2, 3 and 4. There are other breaking changes, see the
[CHANGELOG](./CHANGELOG.md) for details.

In addition, version 1.x is able to render prompt status strings using [ANSI escape sequences][ansi-esc-code].
This can be used in hosts that support virtual terminal escape sequences such as PowerShell Core on Linux,
macOS and Windows and Windows PowerShell 5.x on Windows 10. Support for [Console Virtual Terminal Sequences][console-vt-seq] was added in Windows 10 version 1511.

This version is being developed on the branch:

- `develop` includes breaking changes, toward [v1.0](https://github.com/dahlbyk/posh-git/issues/328).
  ( [README](./README.md)
  • [CHANGELOG](./CHANGELOG.md) )

The rest of this readme applies only to version 1.x of posh-git.

## Installation

### Prerequisites

Before installing posh-git make sure the following prerequisites have been met.

1. Windows PowerShell 5.x or PowerShell Core 6.0.
   You can get PowerShell Core 6.0 for Windows, Linux or macOS from [here][pscore-install].
   Check your PowerShell version by executing `$PSVersionTable.PSVersion`.

2. On Windows, script execution policy must be set to either `RemoteSigned` or `Unrestricted`.
   Check the script execution policy setting by executing `Get-ExecutionPolicy`.
   If the policy is not set to one of the two required values, run PowerShell as Administrator and execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

3. Git must be installed and available via the PATH environment variable.
   Check that `git` is accessible from PowerShell by executing `git --version` from PowerShell.
   If `git` is not recognized as the name of a command verify that you have Git installed.
   If not, install Git from [https://git-scm.com](https://git-scm.com).
   If you have Git installed, make sure the path to git is in your PATH environment variable.

### Installing posh-git

posh-git is available on the [PowerShell Gallery][psgallery-beta1] and can be installed using the PowerShellGet module.

1. Start either Windows PowerShell 5.x or PowerShell Core 6.x (`pwsh`).

2. Execute one of the following two commands from an elevated PowerShell prompt depending on your current posh-git installation status:

   ```powershell
   # If you have never installed posh-git from the PowerShell Gallery
   # NOTE: If asked to trust packages from the PowerShell Gallery, answer yes to continue install of posh-git
   PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
   ```

   OR

   ```powershell
   # If you have already installed a previous version of posh-git from the PowerShell Gallery
   PowerShellGet\Update-Module posh-git
   ```

### Extra step for Linux and macOS users

The version of `PSReadLine` (1.2) that ships PowerShell Core 6.0.0 has known issues that cause problems with the
prompt function that posh-git uses.  Fortunately, there is a beta of PSReadLine 2.0.0 that fixes these problems.
You can check the version of PSReadLine you have by executing: `get-module psreadline`.
If it less than 2.0.0, follow this procedure.

1. Start PowerShell Core by running `pwsh`.

2. Install the prerelease version of PSReadLine - 2.0.0-beta* by executing:

   ```powershell
   Install-Module PSReadLine -AllowClobber -AllowPrerelease -Force -Scope CurrentUser
   ```

3. Restart `pwsh` and verify you have at least the `2.0.0` version of PSReadLine by executing: `get-module psreadline`.

## Using posh-git

After you have installed posh-git, you need to configure your PowerShell session to use the posh-git module.

### Step 1: Import posh-git

The first step is to import the module into your PowerShell session which will enable git tab completion.
You can do this with the command `Import-Module posh-git`.

### Step 2: Import posh-git from your PowerShell profile

You do not want to have to manually execute the `Import-Module` command every time you open a new PowerShell prompt.
Let's have PowerShell import this module for you in each new PowerShell session.
We can do this by either executing the command `Add-PoshGitToProfile` or by editing your PowerShell profile script and adding the command `Import-Module posh-git`.

If you want posh-git to be available in all your PowerShell hosts (console, ISE, etc) then execute `Add-PoshGitToProfile -AllHosts`.
This will add a line containing `Import-Module posh-git` to the file `$profile.CurrentUserAllHosts`.

If you want posh-git to be available in just the current host, then execute `Add-PoshGitToProfile`.
This will add the same command but to the file `$profile.CurrentUserCurrentHost`.

If you want posh-git to be available for all users on the system, start PowerShell as Administrator or
via sudo (sudo pwsh) on Linux/macOS then execute `Add-PoshGitToProfile -AllUsers -AllHosts`.
This will add the import command to `$profile.AllUsersAllHosts`.

If you want to configure posh-git for all users but only for the current host,
drop the `-AllHosts` parameter and the command will modify `$profile.AllUsersCurrentHost`.

If you'd prefer, you can manually edit the desired PowerShell profile script.
Open (or create) your profile script with the command `notepad $profile.CurrentUserAllHosts`.
In the profile script, add the following line:

```powershell
Import-Module posh-git
```

Save the profile script, then close PowerShell and open a new PowerShell session.
Type `git fe` and then press <kbd>tab</kbd>. If posh-git has been imported, that command should tab complete to `git fetch`.

### Step 3 (optional): Customize your PowerShell prompt

When you import the posh-git module, it will replace PowerShell's default prompt function with a new
prompt function that displays Git status summary information when the current directory is inside a Git repository.
posh-git will not replace the prompt function if it has detected that you have your own, customized prompt
function.

The prompt function provided by posh-git creates a prompt that looks like this:

![C:\Users\Keith\GitHub\posh-git [master ≡]> ][prompt-default]

You can customize the posh-git prompt function or define your own custom prompt function.
The rest of this section covers how to customize posh-git's prompt function using the global variale `$GitPromptSettings`.

You can customize the default prompt prefix to display a timestamp with these settings:

```text
$GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-Date -f "MM-dd HH:mm:ss") '
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::DarkMagenta
```

This will change the prompt to:

![02-11 19:03:31 C:\Users\Keith\GitHub\posh-git [master ≡]> ][prompt-prefix]

If you would prefer to have any path under your home directory abbreviated with `~`, use the following setting:

```text
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
```

This will change the prompt to:

![~\GitHub\posh-git [master ≡]> ][prompt-abbrev]

If you would like to change the color of the path, you can use the following setting on Windows:

```text
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 'Orange'
```

Setting the ForegroundColor to a color name, other than one of the standard ConsoleColor names, only works on Windows.
On Windows, posh-git uses the `System.Drawing.ColorTranslator.FromHtml()` method to parse a color name as an HTML color.
For a complete list of HTML colors, see this [W3Schools page][w3c-colors].

If you are on Linux or macOS and desire an Orange path, you can specify the RGB value for Orange e.g.:

```text
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 0xFFA500
```

This will change the prompt to:

![C:\Users\Keith\GitHub\posh-git [master]> ][prompt-path]

If you would like to make your prompt span two lines, with a newline after the Git status summary, use these settings:

```text
$GitPromptSettings.AfterText.Text += "`n"
$GitPromptSettings.DefaultPromptDebug = "[DBG]: "
```

This will change the prompt to:

![C:\Users\Keith\GitHub\posh-git [master ≡]&#10;> ][prompt-two-line]

Finally, you can swap the order of the path and the Git status summary with the following settings:

```text
$GitPromptSettings.DefaultPromptWriteStatusFirst = $true
$GitPromptSettings.BeforeText.Text = '['
$GitPromptSettings.AfterText.Text  = '] '
```

This will change the prompt to:

![[master ≡] C:\Users\Keith\GitHub\posh-git> ][prompt-swap]

If you'd like to make any of these changes available whenever you start PowerShell, put the corresponding
setting(s) in one of your profile scripts after the line that imports posh-git.

If you require more customization than `$GitPromptSettings` provides, you can create your own prompt function to show whatever information you want. See the [Customizing Your PowerShell Prompt][wiki-custom-prompt] wiki page for details.
However, if you need a custom prompt to perform some non-prompt logic, you can still use posh-git's prompt function to
write out a prompt string.  This can be done with the `$GitPromptScriptBlock` variable as shown below e.g.:

```powershell
# my profile.ps1
function prompt {
    # Your non-prompt logic here

    # Have posh-git display its default prompt
    & $GitPromptScriptBlock
}
```

And if you'd like to write prompt text before and/or after the posh-git prompt,
you can use posh-git's `Write-Prompt` command as shown below:

```powershell
# my profile.ps1
function prompt {
    # Your non-prompt logic here
    $prompt = Write-Prompt "Text before posh-git prompt " -ForegroundColor Orange
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt "Text after posh-git prompt " -ForegroundColor ([ConsoleColor]::Magenta)
    if ($prompt) { $prompt }
}
```

## Based on work by

- Keith Dahlby,   http://solutionizing.net/
- Mark Embling,   http://www.markembling.info/
- Jeremy Skinner, http://www.jeremyskinner.co.uk/

[av-develop-site]: https://ci.appveyor.com/project/dahlbyk/posh-git/branch/develop
[av-develop-img]:  https://ci.appveyor.com/api/projects/status/eb8erd5afaa01w80/branch/develop?svg=true&pendingText=develop%20%E2%80%A3%20pending&failingText=develop%20%E2%80%A3%20failing&passingText=develop%20%E2%80%A3%20passing
[av-master-site]:  https://ci.appveyor.com/project/dahlbyk/posh-git/branch/master
[av-master-img]:   https://ci.appveyor.com/api/projects/status/eb8erd5afaa01w80/branch/master?svg=true&pendingText=master%20%E2%80%A3%20pending&failingText=master%20%E2%80%A3%20failing&passingText=master%20%E2%80%A3%20passing

[tv-develop-img]:  https://travis-ci.org/dahlbyk/posh-git.svg?branch=develop
[tv-develop-site]: https://travis-ci.org/dahlbyk/posh-git

[cc-develop-img]:  https://coveralls.io/repos/github/dahlbyk/posh-git/badge.svg?branch=develop
[cc-develop-site]: https://coveralls.io/github/dahlbyk/posh-git?branch=develop
[cc-master-img]:   https://coveralls.io/repos/github/dahlbyk/posh-git/badge.svg?branch=master
[cc-master-site]:  https://coveralls.io/github/dahlbyk/posh-git?branch=master

[ansi-esc-code]:   https://en.wikipedia.org/wiki/ANSI_escape_code
[console-vt-seq]:  https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
[gitter-img]:      https://badges.gitter.im/dahlbyk/posh-git.svg
[gitter]:          https://gitter.im/dahlbyk/posh-git?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[pscore-install]:  https://github.com/PowerShell/PowerShell#get-powershell

[choco-img]:       https://img.shields.io/chocolatey/dt/poshgit.svg
[choco-site]:      https://chocolatey.org/packages/poshgit/
[psgallery-beta1]: https://www.powershellgallery.com/packages/posh-git/1.0.0-beta1
[psgallery-img]:   https://img.shields.io/powershellgallery/dt/posh-git.svg
[psgallery-site]:  https://powershellgallery.com/packages/posh-git
[w3c-colors]:      https://www.w3schools.com/colors/colors_names.asp

[prompt-def-long]: https://github.com/dahlbyk/posh-git/wiki/images/PromptDefaultLong.png   "C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 | +0 ~1 -0 !]> "
[prompt-default]:  https://github.com/dahlbyk/posh-git/wiki/images/PromptDefault.png       "C:\Users\Keith\GitHub\posh-git [master ≡]> "
[prompt-prefix]:   https://github.com/dahlbyk/posh-git/wiki/images/PromptPrefix.png        "02-11 19:03:31 C:\Users\Keith\GitHub\posh-git [master ≡]>"
[prompt-abbrev]:   https://github.com/dahlbyk/posh-git/wiki/images/PromptAbbrevHomeDir.png "~\GitHub\posh-git [master ≡]> "
[prompt-path]:     https://github.com/dahlbyk/posh-git/wiki/images/PromptOrangePath.png    "C:\Users\Keith\GitHub\posh-git [master ≡]> "
[prompt-swap]:     https://github.com/dahlbyk/posh-git/wiki/images/PromptStatusFirst.png   "[master ≡] C:\Users\Keith\GitHub\posh-git> "
[prompt-two-line]: https://github.com/dahlbyk/posh-git/wiki/images/PromptTwoLine.png       "C:\Users\Keith\GitHub\posh-git [master ≡]&#10;> "

[wiki-custom-prompt]: https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt
