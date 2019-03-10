# posh-git

[![Join the chat at https://gitter.im/dahlbyk/posh-git][gitter-img]][gitter]
[![PowerShell Gallery][psgallery-img]][psgallery-site]
[![posh-git on Chocolatey][choco-img]][choco-site]

Table of contents:

- [Overview](#overview)
- [Versions](#versions)
- [Installation](#installation)
- [Using posh-git](#using-posh-git)
- [Git status summary information](#git-status-summary-information)
- [Customization variables](#customization-variables)
- [Customizing the posh-git prompt](#customizing-the-posh-git-prompt)
- [Based on work by](#based-on-work-by)

## Overview

posh-git is a PowerShell module that integrates Git and PowerShell by providing Git status summary information that
can be displayed in the PowerShell prompt, e.g.:

![C:\Users\Keith\GitHub\posh-git [master ≡ +0 ~1 -0 | +0 ~1 -0 !]> ][prompt-def-long]

posh-git also provides tab completion support for common git commands, branch names, paths and more.
For example, with posh-git, PowerShell can tab complete git commands like `checkout` by typing `git ch` and pressing
the <kbd>tab</kbd> key. That will tab complete to `git checkout` and if you keep pressing <kbd>tab</kbd>, it will
cycle through other command matches such as `cherry` and `cherry-pick`. You can also tab complete remote names and
branch names e.g.: `git pull or<tab> ma<tab>` tab completes to `git pull origin master`.

## Versions

### posh-git v1.0

| Windows (AppVeyor) | Linux/macOS (Travis) | Code Coverage Status |
|--------------------|----------------------|----------------------|
| [![master build status][av-master-img]][av-master-site] | [![master build status][tv-master-img]][tv-master-site] | [![master build coverage][cc-master-img]][cc-master-site] |

[README][v1-readme] • [CHANGELOG][v1-change]

- Supports Windows PowerShell 5.x
- Supports PowerShell Core 6+ on all platforms
- Supports [ANSI escape sequences][ansi-esc-code] for color customization
- Includes breaking changes from v0.x ([roadmap](https://github.com/dahlbyk/posh-git/issues/328))

#### Releases

- v1.0.0-beta3
  ( [README][v1b3-readme] • [CHANGELOG][v1b3-change] )
- v1.0.0-beta2
  ( [README][v1b2-readme] • [CHANGELOG][v1b2-change] )
- v1.0.0-beta1
  ( [README][v1b1-readme] • [CHANGELOG][v1b1-change] )

### posh-git v0.x

| Windows (AppVeyor) | Code Coverage Status |
|--------------------|----------------------|
| [![v0 build status][av-v0-img]][av-v0-site] | [![v0 build coverage][cc-v0-img]][cc-v0-site] |

[README][v0-readme] • [CHANGELOG][v0-change]

- Supports Windows PowerShell 3+
- Does not support PowerShell Core
- Avoids breaking changes, maintaining v0.x

#### Releases

- v0.7.3
  ( [README][v073-readme] • [CHANGELOG][v073-change] )
- v0.7.1
  ( [README][v071-readme] • [CHANGELOG][v071-change] )
- v0.7.0
  ( [README][v070-readme] • [CHANGELOG][v070-change] )

## Installation

These installation instructions, as well as rest of this readme, applies only to version 1.x of posh-git.
For v0.x installation instructions see this [README][v0-readme].

### Prerequisites

Before installing posh-git make sure the following prerequisites have been met.

1. Windows PowerShell 5.x or PowerShell Core 6.0.
   You can get PowerShell Core 6.0 for Windows, Linux or macOS from [here][pscore-install].
   Check your PowerShell version by executing `$PSVersionTable.PSVersion`.

2. On Windows, script execution policy must be set to either `RemoteSigned` or `Unrestricted`.
   Check the script execution policy setting by executing `Get-ExecutionPolicy`.
   If the policy is not set to one of the two required values, run PowerShell as Administrator and
   execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

3. Git must be installed and available via the PATH environment variable.
   Check that `git` is accessible from PowerShell by executing `git --version` from PowerShell.
   If `git` is not recognized as the name of a command, verify that you have Git installed.
   If not, install Git from [https://git-scm.com](https://git-scm.com).
   If you have Git installed, make sure the path to git is in your PATH environment variable.

### Installing posh-git via PowerShellGet on Linux, macOS and Windows

posh-git is available on the [PowerShell Gallery][psgallery-v1] and can be installed using the PowerShellGet module.

1. Start either Windows PowerShell 5.x or PowerShell Core 6.x (`pwsh`).

2. Execute one of the following two commands from an elevated PowerShell prompt,
   depending on whether (A) you've never installed posh-git, or (B) you've already installed a previous version:

    ```powershell
    # (A) You've never installed posh-git from the PowerShell Gallery
    #
    # NOTE: If asked to trust packages from the PowerShell Gallery, answer yes to continue installation of posh-git
    # NOTE: If the AllowPrerelease parameter is not recognized, update your version of PowerShellGet to >= 1.6 e.g.
    #       Install-Module PowerShellGet -Scope CurrentUser -Force -AllowClobber

    PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
    ```

    OR

    ```powershell
    # (B) You've already installed a previous version of posh-git from the PowerShell Gallery
    PowerShellGet\Update-Module posh-git
    ```

### Installing posh-git via Chocolatey

If you prefer to manage posh-git as a Windows package, you can use [Chocolatey](https://chocolatey.org) to install posh-git.
If you don't have Chocolatey, you can install it from the [Chocolately Install page](https://chocolatey.org/install).
With Chocolatey installed, execute the following command to install posh-git:

```powershell
choco install poshgit
```

### Installing post-git Manually

If you need to test/debug changes prior to contributing here, or would otherwise prefer to install posh-git without
the aid of a package manager, you can execute `Import-Module <path-to-src\posh-git.psd1>`.  For example, if you
have git cloned posh-git to `~\git\posh-git` you can import this version of posh-git by executing
`Import-Module ~\git\posh-git\src\posh-git.psd1`.

## Using posh-git

After you have installed posh-git, you need to configure your PowerShell session to use the posh-git module.

### Step 1: Import posh-git

The first step is to import the module into your PowerShell session which will enable git tab completion.
You can do this with the command `Import-Module posh-git`.

### Step 2: Import posh-git from your PowerShell profile

You do not want to have to manually execute the `Import-Module` command every time you open a new PowerShell prompt.
Let's have PowerShell import this module for you in each new PowerShell session.
We can do this by either executing the command `Add-PoshGitToProfile` or by editing your PowerShell profile script and
adding the command `Import-Module posh-git`.

If you want posh-git to be available in all your PowerShell hosts (console, ISE, etc) then execute
`Add-PoshGitToProfile -AllHosts`. This will add a line containing `Import-Module posh-git` to the file
`$profile.CurrentUserAllHosts`.

If you want posh-git to be available in just the current host, then execute `Add-PoshGitToProfile`.
This will add the same command but to the file `$profile.CurrentUserCurrentHost`.

If you want posh-git to be available for all users on the system, start PowerShell as Administrator or
via sudo (`sudo pwsh`) on Linux/macOS then execute `Add-PoshGitToProfile -AllUsers -AllHosts`.
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
Type `git fe` and then press <kbd>tab</kbd>. If posh-git has been imported, that command should tab complete to
`git fetch`.

## Git status summary information

The Git status summary information provides a wealth of "Git status" information at a glance, all the time in your
prompt.

By default, the status summary has the following format:

    [{HEAD-name} S +A ~B -C !D | +E ~F -G !H W]

- `[` (`BeforeStatus`)
- `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
  - Cyan means the branch matches its remote
  - Green means the branch is ahead of its remote (green light to push)
  - Red means the branch is behind its remote
  - Yellow means the branch is both ahead of and behind its remote
- `S` represents the branch status in relation to remote (tracked origin) branch.

  Note: This status information reflects the state of the remote tracked branch after the last `git fetch/pull`
  of the remote. Execute `git fetch` to update to the latest on the default remote repo. If you have multiple remotes,
  execute `git fetch --all`.

  - `≡` = The local branch in at the same commit level as the remote branch (`BranchIdenticalStatus`)
  - `↑<num>` = The local branch is ahead of the remote branch by the specified number of commits; a `git push` is
    required to update the remote branch (`BranchAheadStatus`)
  - `↓<num>` = The local branch is behind the remote branch by the specified number of commits; a `git pull` is
    required to update the local branch (`BranchBehindStatus`)
  - `<a>↕<b>` = The local branch is both ahead of the remote branch by the specified number of commits (a) and behind
    by the specified number of commits (b); a rebase of the local branch is required before pushing local changes to
    the remote branch (`BranchBehindAndAheadStatus`).  NOTE: this status is only available if
    `$GitPromptSettings.BranchBehindAndAheadDisplay` is set to `Compact`.
  - `×` = The local branch is tracking a branch that is gone from the remote (`BranchGoneStatus`)
- `ABCD` represent the index; `|` (`DelimStatus`); `EFGH` represent the working directory
  - `+` = Added files
  - `~` = Modified files
  - `-` = Removed files
  - `!` = Conflicted files
  - As with `git status` output, index status is displayed in dark green and working directory status in dark red

- `W` represents the overall status of the working directory
  - `!` = There are unstaged changes in the working tree (`LocalWorkingStatusSymbol`)
  - `~` = There are uncommitted changes i.e. staged changes in the working tree waiting to be committed (`LocalStagedStatusSymbol`)
  - None = There are no unstaged or uncommitted changes to the working tree (`LocalDefaultStatusSymbol`)
- `]` (`AfterStatus`)

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

posh-git adds variables to your session to let you customize it, including `$GitPromptSettings`, `$GitTabSettings`, and
`$TortoiseGitSettings`. For an example of how to configure your PowerShell profile script to import the posh-git
module and create a custom prompt function that displays git status info, see the
[Customizing Your PowerShell Prompt](#customizing-the-posh-git-prompt) section below.

Note on performance: Displaying file status in the git prompt for a very large repo can be prohibitively slow.
Rather than turn off file status entirely (`$GitPromptSettings.EnableFileStatus = $false`), you can disable it on a
repo-by-repo basis by adding individual repository paths to `$GitPromptSettings.RepositoriesInWhichToDisableFileStatus`.

## Customizing the posh-git prompt

When you import the posh-git module, it will replace PowerShell's default prompt function with a new prompt function.
The posh-git prompt function will display Git status summary information when the current directory is inside a Git
repository. posh-git will not replace the prompt function if it has detected that you have your own, customized prompt
function.

The prompt function provided by posh-git creates a prompt that looks like this:

![~\GitHub\posh-git [master ≡]> ][prompt-default]

You can customize the posh-git prompt function or define your own custom prompt function.
The rest of this section covers how to customize posh-git's prompt function using the global variable
`$GitPromptSettings`.

For instance, you can customize the default prompt prefix to display a colored timestamp with these settings:

```text
$GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-Date -f "MM-dd HH:mm:ss") '
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::Magenta
```

This will change the prompt to:

![02-18 13:45:19 ~\GitHub\posh-git [master ≡]> ][prompt-prefix]

If you would prefer not to have any path under your home directory abbreviated with `~`, use the following setting:

```text
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $false
```

This will change the prompt to:

![C:\Users\Keith\GitHub\posh-git [master ≡]> ][prompt-no-abbr]

If you would like to change the color of the path, you can use the following setting on Windows:

```text
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 'Orange'
```

> Note: Setting the ForegroundColor to a color name, other than one of the standard ConsoleColor names, only works on Windows.
On Windows, posh-git uses the `[System.Drawing.ColorTranslator]::FromHtml(string colorName)` method to parse a color
name as an HTML color. For a complete list of HTML colors, see this [W3Schools page][w3c-colors].

If you are on Linux or macOS and desire an Orange path, you will need to specify the RGB value for Orange e.g.:

```text
$GitPromptSettings.DefaultPromptPath.ForegroundColor = 0xFFA500
```

This will change the prompt to:

![~\GitHub\posh-git [master]> ][prompt-path]

If you would like to make your prompt span two lines, with a newline after the Git status summary, use this setting:

```text
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n'
```

This will change the prompt to:

![~\GitHub\posh-git [master ≡]&#10;> ][prompt-two-line]

You can swap the order of the path and the Git status summary with the following setting:

```text
$GitPromptSettings.DefaultPromptWriteStatusFirst = $true
```

This will change the prompt to:

![[master ≡] ~\GitHub\posh-git> ][prompt-swap]

Finally, you can combine these settings to customize the posh-git prompt fairly significantly.
In the `DefaultPromptSuffix` field below, we are prepending the PowerShell history id number before the prompt
char `>` e.g.:

```text
$GitPromptSettings.DefaultPromptWriteStatusFirst = $true
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n$([DateTime]::now.ToString("MM-dd HH:mm:ss"))'
$GitPromptSettings.DefaultPromptBeforeSuffix.ForegroundColor = 0x808080
$GitPromptSettings.DefaultPromptSuffix = ' $((Get-History -Count 1).id + 1)$(">" * ($nestedPromptLevel + 1)) '
```

This will change the prompt to:

![[master ≡] ~\GitHub\posh-git&#10;02-18 14:04:35 38> ][prompt-custom]

If you'd like to make any of these changes permanent, i.e. available whenever you start PowerShell, put the
corresponding setting(s) in one of your profile scripts **after** the line that imports posh-git.

For reference, the following layouts show the relative position of the various parts of the posh-git prompt.
Note that `<>` denotes parts of the prompt that may not appear depending on the status of settings and whether or not
the current dir is in a Git repository.
To simplify the layout, `DP` is being used as an abbreviation for `DefaultPrompt` settings.

Default prompt layout:

```text
{DPPrefix}{DPPath}{PathStatusSeparator}<{BeforeStatus}{Status}{AfterStatus}>{DPBeforeSuffix}<{DPDebug}><{DPTimingFormat}>{DPSuffix}
```

Prompt layout when DefaultPromptWriteStatusFirst is set to $true:

```text
{DPPrefix}<{BeforeStatus}{Status}{AfterStatus}>{PathStatusSeparator}{DPPath}{DPBeforeSuffix}<{DPDebug}><{DPTimingFormat}>{DPSuffix}
```

If you require even more customization than `$GitPromptSettings` provides, you can create your own prompt
function to show whatever information you want.
See the [Customizing Your PowerShell Prompt][wiki-custom-prompt] wiki page for details.

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
    $prompt = Write-Prompt "Text before posh-git prompt " -ForegroundColor ([ConsoleColor]::Green)
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt "Text after posh-git prompt" -ForegroundColor ([ConsoleColor]::Magenta)
    if ($prompt) { "$prompt " } else { " " }
}
```

## Based on work by

- Keith Dahlby,   http://solutionizing.net/
- Mark Embling,   http://www.markembling.info/
- Jeremy Skinner, http://www.jeremyskinner.co.uk/

[av-master-site]:  https://ci.appveyor.com/project/dahlbyk/posh-git/branch/master
[av-master-img]:   https://ci.appveyor.com/api/projects/status/eb8erd5afaa01w80/branch/master?svg=true&pendingText=master%20%E2%80%A3%20pending&failingText=master%20%E2%80%A3%20failing&passingText=master%20%E2%80%A3%20passing
[av-v0-img]:       https://ci.appveyor.com/api/projects/status/eb8erd5afaa01w80/branch/v0?svg=true&pendingText=v0%20%E2%80%A3%20pending&failingText=v0%20%E2%80%A3%20failing&passingText=v0%20%E2%80%A3%20passing
[av-v0-site]:      https://ci.appveyor.com/project/dahlbyk/posh-git/branch/v0

[tv-master-img]:   https://travis-ci.org/dahlbyk/posh-git.svg?branch=master
[tv-master-site]:  https://travis-ci.org/dahlbyk/posh-git

[cc-master-img]:   https://coveralls.io/repos/github/dahlbyk/posh-git/badge.svg?branch=master
[cc-master-site]:  https://coveralls.io/github/dahlbyk/posh-git?branch=master
[cc-v0-img]:       https://coveralls.io/repos/github/dahlbyk/posh-git/badge.svg?branch=v0
[cc-v0-site]:      https://coveralls.io/github/dahlbyk/posh-git?branch=v0

[ansi-esc-code]:   https://en.wikipedia.org/wiki/ANSI_escape_code
[console-vt-seq]:  https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
[gitter-img]:      https://badges.gitter.im/dahlbyk/posh-git.svg
[gitter]:          https://gitter.im/dahlbyk/posh-git?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[pscore-install]:  https://github.com/PowerShell/PowerShell#get-powershell

[choco-img]:       https://img.shields.io/chocolatey/dt/poshgit.svg
[choco-site]:      https://chocolatey.org/packages/poshgit/
[psgallery-img]:   https://img.shields.io/powershellgallery/dt/posh-git.svg
[psgallery-site]:  https://www.powershellgallery.com/packages/posh-git
[psgallery-v1]:    https://www.powershellgallery.com/packages/posh-git/1.0.0-beta3
[w3c-colors]:      https://www.w3schools.com/colors/colors_names.asp

[prompt-def-long]: https://github.com/dahlbyk/posh-git/wiki/images/PromptDefaultLong.png   "~\GitHub\posh-git [master ≡ +0 ~1 -0 | +0 ~1 -0 !]> "
[prompt-default]:  https://github.com/dahlbyk/posh-git/wiki/images/PromptDefault.png       "~\GitHub\posh-git [master ≡]> "
[prompt-prefix]:   https://github.com/dahlbyk/posh-git/wiki/images/PromptPrefix.png        "02-18 13:45:19 ~\GitHub\posh-git [master ≡]>"
[prompt-no-abbr]:  https://github.com/dahlbyk/posh-git/wiki/images/PromptNoAbbrevHome.png  "C:\Users\Keith\GitHub\posh-git [master ≡]> "
[prompt-path]:     https://github.com/dahlbyk/posh-git/wiki/images/PromptOrangePath.png    "~\GitHub\posh-git [master ≡]> "
[prompt-swap]:     https://github.com/dahlbyk/posh-git/wiki/images/PromptStatusFirst.png   "[master ≡] ~\GitHub\posh-git> "
[prompt-two-line]: https://github.com/dahlbyk/posh-git/wiki/images/PromptTwoLine.png       "~\GitHub\posh-git [master ≡]&#10;> "
[prompt-custom]:   https://github.com/dahlbyk/posh-git/wiki/images/PromptCustom.png        "[master ≡] ~\GitHub\posh-git&#10;02-18 14:04:35 38> "

[v0-change]:       https://github.com/dahlbyk/posh-git/blob/v0/CHANGELOG.md
[v0-readme]:       https://github.com/dahlbyk/posh-git/blob/v0/README.md

[v070-change]:     https://github.com/dahlbyk/posh-git/blob/v0.7.0/CHANGELOG.md
[v070-readme]:     https://github.com/dahlbyk/posh-git/blob/v0.7.0/README.md

[v071-change]:     https://github.com/dahlbyk/posh-git/blob/v0.7.1/CHANGELOG.md
[v071-readme]:     https://github.com/dahlbyk/posh-git/blob/v0.7.1/README.md

[v073-change]:     https://github.com/dahlbyk/posh-git/blob/v0.7.3/CHANGELOG.md
[v073-readme]:     https://github.com/dahlbyk/posh-git/blob/v0.7.3/README.md

[v1-change]:       https://github.com/dahlbyk/posh-git/blob/master/CHANGELOG.md
[v1-readme]:       https://github.com/dahlbyk/posh-git/blob/master/README.md

[v1b1-change]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta1/CHANGELOG.md
[v1b1-readme]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta1/README.md

[v1b2-change]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta2/CHANGELOG.md
[v1b2-readme]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta2/README.md

[v1b3-change]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta3/CHANGELOG.md
[v1b3-readme]:     https://github.com/dahlbyk/posh-git/blob/v1.0.0-beta3/README.md

[wiki-custom-prompt]: https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt
