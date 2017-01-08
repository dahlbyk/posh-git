# posh-git

[![Join the chat at https://gitter.im/dahlbyk/posh-git](https://badges.gitter.im/dahlbyk/posh-git.svg)](https://gitter.im/dahlbyk/posh-git?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

posh-git is a PowerShell module that integrates Git and PowerShell by providing Git status summary information that can be displayed in the PowerShell prompt e.g.:
```
[master +0 ~1 -0 | +1 ~0 -0 !]
C:\GitHub\posh-git>
```
posh-git also provides tab completion support for common git commands and branch names.
For example, with posh-git, PowerShell can tab complete git commands like `checkout` by typing `git ch` and pressing the <kbd>tab</kbd> key.
That will tab complete to `git checkout` and if you keep pressing <kbd>tab</kbd>, it will cycle through other command matches such as `cherry` and `cherry-pick`.
You can also tab complete remote names and branch names e.g.: `git pull or<tab> ma<tab>` tab completes to `git pull origin master`.

## Notes
Posh-git adds variables to your session to let you customize it, including `$GitPromptSettings`, `$GitTabSettings`, and `$TortoiseGitSettings`.
For an example of how to configure your PowerShell profile script to import the posh-git module and create a custom prompt function that displays git status info, see the `Customizing Your PowerShell Prompt` section below.

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
   If not, install Git from [http://git-scm.org](http://git-scm.org).
   If you have Git installed, make sure the path to git.exe is in your PATH environment variable.

### Installing posh-git via PowerShellGet
If you are on PowerShell version 5 or higher, execute the command below to install from the [PowerShell Gallery](https://www.powershellgallery.com/):

```
Install-Module posh-git -Scope CurrentUser
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
However, you do not want to have to do that every time you open a new PowerShell prompt.
So let's have PowerShell import this module for you in each new PowerShell session.
We can do this by placing the import command in your PowerShell profile script.
Open (or create) your profile script with the command `notepad $profile.CurrentUserAllHosts`.
In the profile script, add the following line:
```
Import-Module posh-git
```
Save the profile script, then close PowerShell and open a new PowerShell session.
Type `git fe` and then press <kbd>tab</kbd>. If posh-git has been imported, that command should tab complete to `git fetch`.

The second step is setting up your PowerShell prompt to display Git status summary information and that is covered in the next section.

### Step 2: Customize Your PowerShell Prompt
Your PowerShell prompt can be customized to show whatever information you want.
In PowerShell, the "prompt" text is provided by a function named `prompt`.
PowerShell provides you with a default `prompt` function that is defined as:
```
# Built-in, default PowerShell prompt
function prompt {
    "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}
```
You can override the built-in `prompt` function by merely defining the following function in your profile script:
```
function prompt {
    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation -ForegroundColor Cyan
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This prompt function illustrates a few features of PowerShell prompt functions.
First, a string that is output by a function can't indicate a color to use to display the string.
Well, at least not on Windows 8.1 and below.
In Windows 10 and on Linux and macOS, PowerShell can utilitize ANSI sequences to colorize parts of the string.
For this example, let's assume we're running on PowerShell v4 on Windows 7.
The `Write-Host` command allows us to output text, the current path in this case, with a different foreground and/or background color.
`Write-Host` host also outputs a newline by default, so the `> ` prompt will appear on the line below the path e.g.:
```
C:\Users
> _
```
Now let's look at how to integrate posh-git's Git status summary information into your prompt.
Open your profile script by executing `powershell_ise $profile.CurrentUserAllHosts`.
Insert the following prompt function **after** the line that imports the posh-git module.
```
Import-Module posh-git
function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation -NoNewline
    Write-VcsStatus
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This results in a PowerShell prompt with both the current path and Git status summary information on a single line:
```
C:\Users\Keith\GitHub\rkeithhill\posh-git [rkeithhill/more-readme-tweaks +0 ~1 -0 | +0 ~1 -0 !]> _
```
Nice!  But that doesn't leave much room to type a command without the command wrapping to the next line.
Personally, I prefer to display my Git status summary information and current path on the line above the prompt, like this:
```
Import-Module posh-git
function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-VcsStatus
    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This gives us the prompt:
```
 [rkeithhill/more-readme-tweaks +0 ~1 -0 | +0 ~1 -0 !]C:\Users\Keith\GitHub\rkeithhill\posh-git
> _
```
This puts the prompt cursor on its own line giving me plenty of room to type commands without them wrapping.
However, this is not quite right.
I have an extra space before the Git status summary and no space before the current path.
This is where having the `$global:GitPromptSettings` is useful for further customization.
The text that appears at the start of the Git status summary is provided by `$global:GitPromptSettings.BeforeText` which defaults to `" ["`.
To see all the settings in `$global:GitPromptSettings`, simply execute `$global:GitPromptSettings` at the PowerShell prompt.
Let's change that setting and add a space before the current path and let's put some color in our path as well:
```
Import-Module posh-git
$global:GitPromptSettings.BeforeText = '['
$global:GitPromptSettings.AfterText  = '] '
function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-VcsStatus
    Write-Host $ExecutionContext.SessionState.Path.CurrentLocation -ForegroundColor Green
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This gives us the prompt:
```
[rkeithhill/more-readme-tweaks +0 ~1 -0 | +0 ~1 -0 !] C:\Users\Keith\GitHub\rkeithhill\posh-git
> _
```
This is better with spaces in the right places.

Hopefully, you can see various ways you can customize your prompt to your liking.

Here are a couple of more variations on the prompt function that deal with long paths.
First, here is an example that will collapse the home dir part of your path e.g. `C:\Users\<your-username>` to just `~`:
```
Import-Module posh-git
$global:GitPromptSettings.BeforeText = '['
$global:GitPromptSettings.AfterText  = '] '
function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-VcsStatus

    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($curPath.ToLower().StartsWith($Home.ToLower()))
    {
        $curPath = "~" + $curPath.SubString($Home.Length)
    }

    Write-Host $curPath -ForegroundColor Green
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This gives us a prompt with a shortened current path:
```
[rkeithhill/more-readme-tweaks +0 ~1 -0 | +0 ~1 -0 !] ~\GitHub\rkeithhill\posh-git
> _
```
The following prompt function allows you to set a max length for the current path:
```
Import-Module posh-git
$global:GitPromptSettings.BeforeText = '['
$global:GitPromptSettings.AfterText  = '] '
function prompt {
    $origLastExitCode = $LASTEXITCODE
    Write-VcsStatus

    $maxPathLength = 40
    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($curPath.Length -gt $maxPathLength) {
        $curPath = '...' + $curPath.SubString($curPath.Length - $maxPathLength + 3)
    }

    Write-Host $curPath -ForegroundColor Green
    $LASTEXITCODE = $origLastExitCode
    "$('>' * ($nestedPromptLevel + 1)) "
}
```
This gives us a prompt with a current path that is never greater than 40 characters.
```
[rkeithhill/more-readme-tweaks +0 ~1 -0 | +0 ~1 -0 !] ...sers\Keith\GitHub\rkeithhill\posh-git
> _
```
For more in-depth information on PowerShell prompts, see the online PowerShell help topic [about_prompts](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_prompts).

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
  * ↑ = The local branch is ahead of the remote branch; a 'git push' is required to update the remote branch (`BranchAheadStatus`)
  * ↓ = The local branch is behind the remote branch; a 'git pull' is required to update the local branch (`BranchBehindStatus`)
  * ↕ = The local branch is both ahead and behind the remote branch; a rebase of the local branch is required before pushing local changes to the remote branch (`BranchBehindAndAheadStatus`)
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
