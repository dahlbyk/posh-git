# posh-git Release History

## 1.0.0-beta3 - March 10, 2019

### Removed

- BREAKING: Removed SSH agent functionality from `posh-git` and put into another module focused solely on
  Git SSH support. See [posh-sshell](https://github.com/dahlbyk/posh-sshell).
  ([#338](https://github.com/dahlbyk/posh-git/issues/338))
  ([PR #585](https://github.com/dahlbyk/posh-git/pull/585))
- BREAKING: Removed `PoshGitTextSpan.CustomAnsi` property - now just put your custom VT sequences in the
  `PoshGitTextSpan.Text` property. Be sure to terminate your VT sequences with `"$([char]27)[0m"` or
  ``` "`e[0m" ``` on PowerShell Core.
  ([PR #616](https://github.com/dahlbyk/posh-git/pull/616))

### Added

- Added `Remove-GitBranch` command. Partially addresses #79.
  These commands currently only delete local branches.
  ([#79](https://github.com/dahlbyk/posh-git/issues/79))
  ([PR #663](https://github.com/dahlbyk/posh-git/pull/663))
- Added support for vsts-cli Git integration.
  ([#549](https://github.com/dahlbyk/posh-git/issues/549))
  ([PR #581](https://github.com/dahlbyk/posh-git/pull/581))
  Thanks David Gardiner (@flcdrg)
- Enhance prompt function to show username/hostname in SSH connection. Adds `Get-PromptConnectionInfo` command.
  ([#591](https://github.com/dahlbyk/posh-git/issues/591))
  ([PR #595](https://github.com/dahlbyk/posh-git/pull/595))
- Show Rebase Progress (plus `|REVERTING`).
  ([#102](https://github.com/dahlbyk/posh-git/issues/102))
  ([PR #599](https://github.com/dahlbyk/posh-git/pull/599))
- Set `$Env:COLUMNS` on prompt if necessary.
  ([PR #607](https://github.com/dahlbyk/posh-git/pull/607))
- Tab-completion for `git log --stat`, `git log --patch` and `git diff --staged`.
  ([PR #620](https://github.com/dahlbyk/posh-git/pull/620))
  Thanks Vasily Korytov (@chillum)
- Tab-completion for `git update-git-for-windows` on Windows Git >= 2.16.2.
  ([PR #642](https://github.com/dahlbyk/posh-git/pull/642))
- `New-GitPromptSettings` to provide an easy way to create a `PoshGitPromptSettings` object which can be used to
  reset to the default settings.
  ([PR #659](https://github.com/dahlbyk/posh-git/pull/659))

### Changed

- Eliminate traiing `=` on the tab-completion of `--force-with-lease=`.
  ([PR #622](https://github.com/dahlbyk/posh-git/pull/622))
  Thanks Chuck Lu (@chucklu)
- Expand `PathStatusSeparator` string when composing prompt. This allows you to use string interpolation in the
  `$GitPromptSettings.PathStatusSeparator.Text` setting.
  ([PR #630](https://github.com/dahlbyk/posh-git/pull/630))
  Thanks Jason Shirk (@lzybkr)

### Fixed

- `WindowTitle` set by user overwritten by module.  No longer updates Window title if `WindowTitle` setting set to `$null`.
  ([#594](https://github.com/dahlbyk/posh-git/issues/594))
  ([PR #597](https://github.com/dahlbyk/posh-git/pull/597))
- `Write-VcsStatus` behaving differently.  When `AnsiConsole -eq $false`, `Write-VcsStatus` must not emit any strings.
  ([#612](https://github.com/dahlbyk/posh-git/issues/612))
  ([PR #617](https://github.com/dahlbyk/posh-git/pull/617))
- On Windows PowerShell, defer `Add-Type` until `Set-ConsoleMode` executed. This improves module load time.
  ([#637](https://github.com/dahlbyk/posh-git/issues/637))
  ([PR #638](https://github.com/dahlbyk/posh-git/pull/638))
  ([PR #662](https://github.com/dahlbyk/posh-git/pull/662))
- How do you manually install this? Added manual instructions for git clone of posh-git to README.md.
  ([#648](https://github.com/dahlbyk/posh-git/issues/648))
  ([PR #649](https://github.com/dahlbyk/posh-git/pull/649))
  Thanks Kyle Spier-Swenson (@MrStonedOne)

## 1.0.0-beta2 - May 13, 2018

The 1.0.0 release is targeted specifically at Windows PowerShell 5.x and (cross-platform) PowerShell Core 6.x, both of
which support classes, enabling the enhanced structure of `$GitPromptSettings`,
and writing prompt strings using [ANSI escape sequences][ansi-esc-code] /
[Console Virtual Terminal Sequences][console-vt-seq] (supported since Windows 10 version 1511).

Consequently, this release introduces BREAKING changes with 0.x.
If you are still on Windows PowerShell 2.0, 3.0 or 4.0, please continue to use the 0.x version of posh-git.

### Changed

- Renamed `$GitPromptSettings` values
  - `BeforeText` to `BeforeStatus`
  - `DelimText` to `DelimStatus`
  - `AfterText` to `AfterStatus`
  - `BeforeIndexText` to `BeforeIndex`
  - `BeforeStashText` to `BeforeStash`
  - `AfterStashText` to `AfterStash`
- Split `$GirPromptSettings.DefaultPromptSuffix` and `$GitPromptSettings.DefaultPromptDebugSuffix` into:
  1. `DefaultPromptBeforeSuffix` (`''`)
  2. `DefaultPromptDebug` (`' [DBG]:'`), which is rendered if a debugger is attached
  3. `DefaultPromptSuffix` (`'$(">" * ($nestedPromptLevel + 1)) '`), which is rendered last
     (or returned from `prompt`, for terminals that don't support escape sequences)
- Renamed `$GitPromptSettings.EnableWindowTitle` to `$GitPromptSettings.WindowTitle` with significant improvements:
  - `$Host.UI.RawUI.WindowTitle` is now set on every `prompt`, not just when inside a Git repo.
  - To prevent setting `WindowTitle`, set `$GitPromptSettigs.WindowTitle` to `$null`.
  - The `WindowTitle` update has been moved from the `Write-GitStatus` command to the built-in `prompt` function.
  - `$GitPromptSettings.WindowTitle` is now fully customizable:
    - As a `string`, it will be processed with [`ExpandString`][invokecommand-expandstring].
    - As a `ScriptBlock` (default), it will be executed with two parameters: `$GitStatus` and `$IsAdmin`.
- When a color setting is specified by a `string` (color name), it is parsed as an HTML color
  (on platforms that support `System.Drawing.ColorTranslator`) before being parsed as a `ConsoleColor`.
  To force using `ConsoleColors`, use static member syntax (e.g. `[ConsoleColor]::Cyan`).
  ([PR #536](https://github.com/dahlbyk/posh-git/pull/536))
- `PoshGitVcsPrompt` errors now show details if `$GitPromptSettings.Debug`
  ([PR #560](https://github.com/dahlbyk/posh-git/pull/560))

### Added

- New command `Get-PromptPath` which formats the path displayed in the prompt and window title.
  This command honors `$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory`.
  - A path exactly matching `$HOME` is now shown in full, rather than abbreviated to `~`
    ([PR #567](https://github.com/dahlbyk/posh-git/pull/567))
- New `$GitPromptSettings` values (default):
  - `PathStatusSeparator` (` `)
  - `DefaultPromptPath` (`'$(Get-PromptPath)'`)
  - `DefaultPromptWriteStatusFirst` (`$false`)
  - `DefaultPromptTimingFormat` (`' {0}ms'`)
- `RepoName` property has been addded to the `$global:GitStatus` object returned by `Get-GitStatus`.
- Added `$GitPromptSettings.UntrackedFilesMode`;
  accepted values are `$null` (inherit `status.showUntrackedFiles`), "all", "no", and "normal"
  ([#556](https://github.com/dahlbyk/posh-git/pull/556))
  ([PR #557](https://github.com/dahlbyk/posh-git/pull/557))
  Thanks David Snedecor (@TheSned)
- Exported `Expand-GitCommand` for use with custom tab expansion
  ([#562](https://github.com/dahlbyk/posh-git/pull/562))
  ([PR #563](https://github.com/dahlbyk/posh-git/pull/563))

### Fixed

- Fixed `$GitPromptSettings.EnablePromptStatus` should not affect `Get-GitStatus` by adding `-Force` parameter.
  ([#475](https://github.com/dahlbyk/posh-git/issues/475))
  ([PR #535](https://github.com/dahlbyk/posh-git/pull/535))
- Fixed PowerShell Core bug where we were using `Get-Content -Encoding Byte` when processing profile scripts during
  Chocolatey install/uninstall. That encoding doesn't exist in PowerShell Core.
  Switched to `Get-Content -AsByteStream` on PowerShell Core.
  ([PR #532](https://github.com/dahlbyk/posh-git/pull/532))
- Fixed ANSI rendering bug: when both `ForegroundColor` and `BackgroundColor` colors are `$null` (default),
  we were emitting an unnecessary terminating escape sequence `"$([char]27)[0m"`.
  ([PR #532](https://github.com/dahlbyk/posh-git/pull/532))
- Fixed issue where setting `ForegroundColor` or `BackgroundColor` to 0 (Black) rendered the default color instead.
- Updated Git subcommand lists
  ([#561](https://github.com/dahlbyk/posh-git/issues/561))
  ([PR #571](https://github.com/dahlbyk/posh-git/pull/571))

## 1.0.0-beta1 - January 10, 2018

### Removed

- Drop support for PowerShell 2.0
  ([#163](https://github.com/dahlbyk/posh-git/issues/163))
  ([PR #427](https://github.com/dahlbyk/posh-git/pull/427))
- Drop support for PowerShell 3.0 and 4.0
  ([#328](https://github.com/dahlbyk/posh-git/issues/328))
  ([PR #513](https://github.com/dahlbyk/posh-git/pull/513))
- Remove public `Enable-GitColors`, `Get-AliasPattern`, `Get-GitBranch` and `Invoke-NullCoalescing` and its `??` alias
  ([#93](https://github.com/dahlbyk/posh-git/issues/93))
  ([PR #427](https://github.com/dahlbyk/posh-git/pull/427))

### Changed

- Changed the `$GitPromptSettings` hashtable to a stongly typed object.
  Here is one example of the impact of this change:

  ```powershell
  $GitPromptSettings.LocalWorkingStatusSymbol = '#'
  $GitPromptSettings.LocalWorkingStatusForegroundColor = [ConsoleColor]::DarkRed
  ```

  Changes to:

  ```powershell
  $GitPromptSettings.LocalWorkingStatusSymbol.Text = '#'
  $GitPromptSettings.LocalWorkingStatusSymbol.ForegroundColor = [ConsoleColor]::DarkRed
  ```

- Changed `Write-VcsStatus`, `Write-GitStatus` and `Write-Prompt` to return a string rather than write to host when
  the host supports ANSI escape sequences.

### Added

- Implement support for ANSI escape sequences for colored output - support System.ConsoleColor, System.Drawing.HtmlColor
  (if available on the platform) and 24-bit color.  NOTE: this is a breaking change since `Write-VcsStatus`,
  `Write-GitStatus` and `Write-Prompt` will now return a string rather than write to the host when the host supports
  ANSI escape sequences.
  ([#304](https://github.com/dahlbyk/posh-git/pull/304))
  ([#447](https://github.com/dahlbyk/posh-git/pull/447))
  ([#455](https://github.com/dahlbyk/posh-git/pull/455))
- $GitPromptSettings is now a strongly typed object using PS classes
  ([#344](https://github.com/dahlbyk/posh-git/issues/344))
  ([PR #513](https://github.com/dahlbyk/posh-git/pull/513))
- Provide more granular commands than just `Write-GitStatus`.
  ([#345](https://github.com/dahlbyk/posh-git/issues/345))
  ([PR #513](https://github.com/dahlbyk/posh-git/pull/513))
  We now export the commands that `Write-GitStatus` uses internally which are:
  - Write-GitBranchName
  - Write-GitBranchStatus
  - Write-GitIndexStatus
  - Write-GitStashCount
  - Write-GitWorkingDirStatus
  - Write-GitWorkingDirStatusSummary

### Fixed

- Fixed Get-AuthenticodeSignature not on PS Core.
  ([PR #487](https://github.com/dahlbyk/posh-git/pull/487))
- Provide DefaultPromptPrefixColor and DefaultPromptSuffixColor options
  ([#474](https://github.com/dahlbyk/posh-git/issues/474))
  ([PR #520](https://github.com/dahlbyk/posh-git/pull/520))
- Fixed posh-git prompt makes PowerShell transcripts less readable
  ([#282](https://github.com/dahlbyk/posh-git/issues/282))
  ([PR #447](https://github.com/dahlbyk/posh-git/pull/447))

## 0.7.3 - April 19, 2018

- posh-git now exports the variable `$GitPromptScriptBlock` which contains the code for the default prompt.
  ([#501](https://github.com/dahlbyk/posh-git/issues/501))
  ([PR #513](https://github.com/dahlbyk/posh-git/pull/513))

  If you need to execute your own logic in your own prompt function but still want to display the default posh-git
  prompt, you can execute this scriptblock from your prompt function e.g.:

  ```powershell
  # profile.ps1
  function prompt {
    Set-NodeVersion
    &$GitPromptScriptBlock
  }
  Import-Module posh-git
  ```

- Fixed 'Write-Prompt' to be able use Black as foreground color.
  ([#470](https://github.com/dahlbyk/posh-git/pull/470))
  ([PR #468](https://github.com/dahlbyk/posh-git/pull/468))
  Thanks Vladimir Poleh (@vladimir-poleh)
- Pass "git.exe" instead of "git" to Get-Command.
  ([PR #478](https://github.com/dahlbyk/posh-git/pull/478))
  ([PR #479](https://github.com/dahlbyk/posh-git/pull/479))
  Thanks Mike Sigsworth (@mikesigs)
- Squash ssh agent warnings if `-Quiet`.
  ([PR #484](https://github.com/dahlbyk/posh-git/pull/484))
  Thanks Refael Ackermann (@refack)
- Fixed directory names that contain [brackets] cause GitPrompt to fail.
  ([PR #502](https://github.com/dahlbyk/posh-git/pull/502))
  Thanks Duncan Smart (@duncansmart)
- Added `Add-PoshGitToProfile -AllUsers` support
  ([PR #504](https://github.com/dahlbyk/posh-git/pull/504))
- Fixed duplicated branch completion for git checkout
  ([#505](https://github.com/dahlbyk/posh-git/issues/505))
  ([PR #506](https://github.com/dahlbyk/posh-git/pull/506))
  ([PR #512](https://github.com/dahlbyk/posh-git/pull/512))
  Thanks Christoph Bergmeister (@bergmeister)
- Fixed PSScriptAnalyzer warnings in the source
  ([PR #509](https://github.com/dahlbyk/posh-git/pull/509))
  Thanks Christoph Bergmeister (@bergmeister)
- Fixed errors added to $Error collection by `Get-GitStatus` command
  ([#500](https://github.com/dahlbyk/posh-git/issues/500))
  ([PR #514](https://github.com/dahlbyk/posh-git/pull/514))
- Added custom path rendering in prompt
  ([#469](https://github.com/dahlbyk/posh-git/issues/469))
  ([PR #520](https://github.com/dahlbyk/posh-git/pull/520))
- Clean up wording for work dir local status in help file
  ([PR #516](https://github.com/dahlbyk/posh-git/pull/516))
- Added `$GitPromptSettings.AdminTitlePrefixText` (default: `'Administrator: '`)
  ([#537](https://github.com/dahlbyk/posh-git/pull/537))
  ([PR #538](https://github.com/dahlbyk/posh-git/pull/538))
  Thanks Eric Jorgensen (@nebosite)
- Added `$GitPromptSettings.UntrackedFilesMode`;
  accepted values are `$null` (inherit `status.showUntrackedFiles`), "all", "no", and "normal"
  ([#556](https://github.com/dahlbyk/posh-git/pull/556))
  ([PR #557](https://github.com/dahlbyk/posh-git/pull/557))
  Thanks David Snedecor (@TheSned)
- `PoshGitVcsPrompt` errors now show details if `$GitPromptSettings.Debug`
  ([PR #560](https://github.com/dahlbyk/posh-git/pull/560))
- Exported `Expand-GitCommand` for use with custom tab expansion
  ([#562](https://github.com/dahlbyk/posh-git/pull/562))
  ([PR #563](https://github.com/dahlbyk/posh-git/pull/563))
- Add code coverage to Coveralls.io
  ([#416](https://github.com/dahlbyk/posh-git/pull/416))
  ([PR #461](https://github.com/dahlbyk/posh-git/pull/461))
  Thanks Jan De Dobbeleer (@JanJoris)

## 0.7.1 - March 14, 2017

- Fixed tab completion issues with duplicate aliases
  ([#164](https://github.com/dahlbyk/posh-git/issues/164))
  ([#421](https://github.com/dahlbyk/posh-git/issues/421))
  ([PR #422](https://github.com/dahlbyk/posh-git/pull/422))
- `Add-PoshGitToProfile` will no longer modify a signed `$PROFILE` script; it also learned `-Confirm`
  ([PR #428](https://github.com/dahlbyk/posh-git/pull/428))
- Overwrite pre-0.7 posh-git prompt on import
  ([PR #425](https://github.com/dahlbyk/posh-git/pull/425))
- Fix Chocolatey deprecation warning with dependency on 0.9.10
  ([PR #426](https://github.com/dahlbyk/posh-git/pull/426))
- Don't rerun Pageant if there are no keys to add
  ([PR #441](https://github.com/dahlbyk/posh-git/pull/441))
- Improve (and hide for Chocolatey) profile.example.ps1 deprecation messaging
  ([#442](https://github.com/dahlbyk/posh-git/issues/442))
  ([PR #444](https://github.com/dahlbyk/posh-git/pull/444))
- Quote tab completion for remote names containing special characters
  ([PR #446](https://github.com/dahlbyk/posh-git/pull/446))
- Fix signed $PROFILE detection for PowerShell v2
  ([#448](https://github.com/dahlbyk/posh-git/issues/448))
  ([PR #450](https://github.com/dahlbyk/posh-git/pull/450))
- Create $PROFILE parent directory if missing
  ([PR #449](https://github.com/dahlbyk/posh-git/pull/449))
  ([PR #452](https://github.com/dahlbyk/posh-git/pull/452))
- Add -verbose parameter to install.ps1
  ([PR #451](https://github.com/dahlbyk/posh-git/pull/451))
- Write-Prompt now correctly handles $null color parameters;
  the prompt now also uses DefaultForegroundColor when appropriate
  ([PR #454](https://github.com/dahlbyk/posh-git/pull/454))
- Add error handling to Write-GitStatus
  ([PR #170](https://github.com/dahlbyk/posh-git/pull/170))
  ([PR #453](https://github.com/dahlbyk/posh-git/pull/453))

## 0.7.0 - February 14, 2017

This release has focused on improving the "getting started" experience by adding an `Add-PoshGitToProfile` command that
modifies the user's PowerShell profile script to import the posh-git module whenever PowerShell starts.
When posh-git is imported, it will automatically install a posh-git prompt that displays Git status summary information.
Work was also done to improve performance of `Get-GitStatus` when inside large Git repositories.
Work was begun to eliminate some obvious crashes on PowerShell on .NET Core but more work remains to be done.

- Performance of `Get-GitStatus` on large repos has been improved
  ([PR #319](https://github.com/dahlbyk/posh-git/pull/319))
- Fix prompt and tab completion with non-ASCII characters
  ([#64](https://github.com/dahlbyk/posh-git/issues/64))
  ([PR #223](https://github.com/dahlbyk/posh-git/pull/223))
  ([PR #359](https://github.com/dahlbyk/posh-git/pull/359))
  ([#374](https://github.com/dahlbyk/posh-git/issues/374))
  ([#389](https://github.com/dahlbyk/posh-git/issues/389))
  ([PR #397](https://github.com/dahlbyk/posh-git/pull/397))
  ([PR #403](https://github.com/dahlbyk/posh-git/pull/403))
- Fix incorrect tab expansion for `git push --option <remote>`
  ([#234](https://github.com/dahlbyk/posh-git/issues/234))
  ([PR #379](https://github.com/dahlbyk/posh-git/pull/379))
- Fix support for bare repository
  ([#291](https://github.com/dahlbyk/posh-git/issues/291))
  ([PR #370](https://github.com/dahlbyk/posh-git/pull/370))
- Fix syntax error on setenv calls
  ([PR #297](https://github.com/dahlbyk/posh-git/pull/297))
- Fix temp path issue with ~ in 8.3 filenames
  ([#298](https://github.com/dahlbyk/posh-git/issues/298))
  ([PR #299](https://github.com/dahlbyk/posh-git/pull/299))
- Fix problem on open source PowerShell, missing `WindowsPrincipal`/`WindowsIdentity`
  ([#301](https://github.com/dahlbyk/posh-git/issues/301))
  ([PR #312](https://github.com/dahlbyk/posh-git/pull/312))
- Fix/simplify Chocolatey install and add uninstall
  ([#358](https://github.com/dahlbyk/posh-git/issues/358))
- Remove invalid branch from tab expansion when `HEAD` is detached
  ([PR #367](https://github.com/dahlbyk/posh-git/pull/367))
- Fix PowerShell Core error on `EnvironmentVariableTarget`
  ([#317](https://github.com/dahlbyk/posh-git/issues/317))
  ([#369](https://github.com/dahlbyk/posh-git/issues/369))
  ([PR #318](https://github.com/dahlbyk/posh-git/pull/318))
- Fewer errors generated in global `$Error` collection
  ([PR #370](https://github.com/dahlbyk/posh-git/pull/370))
- Remove error thrown by `git symbolic-ref` and `git describe`
  ([PR #307](https://github.com/dahlbyk/posh-git/pull/307))
- Export command Write-VcsStatus to improve module auto-loading
  ([PR #284](https://github.com/dahlbyk/posh-git/pull/284))
- Update module import so that it sets the prompt function *iff* the user does not have a customized prompt function
  ([#217](https://github.com/dahlbyk/posh-git/issues/217))
  ([PR #349](https://github.com/dahlbyk/posh-git/pull/349))
- Update profile.example.ps1 to remove prompt function and tweak how module is imported
  ([PR #349](https://github.com/dahlbyk/posh-git/pull/349))
- Add tab completion for AVH git-flow commands
  ([PR #231](https://github.com/dahlbyk/posh-git/pull/231))
- Add new commmand Add-PoshGitToProfile
  ([PR #361](https://github.com/dahlbyk/posh-git/pull/361))
- Add about_posh-git help topic
  ([PR #298](https://github.com/dahlbyk/posh-git/pull/287))
- Add new settings for default posh-git prompt:
  - `DefaultPromptPrefix`
    ([PR #393](https://github.com/dahlbyk/posh-git/pull/393))
  - `DefaultPromptSuffix` (default includes nested prompt level,
    ([PR #363](https://github.com/dahlbyk/posh-git/pull/363)))
  - `DefaultPromptDebugSuffix`
  - `DefaultPromptEnableTiming`
    ([PR #371](https://github.com/dahlbyk/posh-git/pull/371))
  - `DefaultPromptAbbreviateHomeDirectory`
    ([#386](https://github.com/dahlbyk/posh-git/issues/386))
- Add ahead/behind count to prompt
  ([PR #256](https://github.com/dahlbyk/posh-git/pull/256))
  - Add `BranchBehindAndAheadDisplay` setting to control count display (Full (default), Compact, Minimal)
- Fix empty `Git-SshPath` issue
  ([PR #268](https://github.com/dahlbyk/posh-git/pull/268))
- Add new settings for prompt status summary text: `FileAddedText`, `FileModifiedText`, `FileRemovedText` and `FileConflictText`
  ([PR #277](https://github.com/dahlbyk/posh-git/pull/277))
- Add tags to 'push' tab-completion
  ([PR #286](https://github.com/dahlbyk/posh-git/pull/286))
- Add new branch status to indicate upstream is gone
  ([PR #326](https://github.com/dahlbyk/posh-git/pull/326))
- Add tab completion support for shorthand force-push syntax (`git push <remote> +<tab>`)
  ([#173](https://github.com/dahlbyk/posh-git/issues/173))
  ([PR #174](https://github.com/dahlbyk/posh-git/pull/174))
  ([PR #343](https://github.com/dahlbyk/posh-git/pull/343))
- Add tab completion of unique remote branch names for `git checkout <tab>`
  ([#177](https://github.com/dahlbyk/posh-git/issues/177))
  ([PR #251](https://github.com/dahlbyk/posh-git/pull/251))
  ([PR #352](https://github.com/dahlbyk/posh-git/pull/352))
- Add `git worktree` tab completion
  ([PR #366](https://github.com/dahlbyk/posh-git/pull/366))
- Add alias support for TortoiseGit commands
  ([PR #394](https://github.com/dahlbyk/posh-git/pull/394))
- Add support for tab-completion of Git parameters, long and short
  ([PR #395](https://github.com/dahlbyk/posh-git/pull/395))
- Switch `$GitPromptSettings` type from `PSObject` to `PSCustomObject`. On PowerShell v5 and higher, this preserves the definition order of properties in `$GitPromptSettings` making it easier to find properties.
- Fix prompt status in worktree
  ([#407](https://github.com/dahlbyk/posh-git/issues/407))
  ([PR #408](https://github.com/dahlbyk/posh-git/pull/408))
- Quote tab completion for items containing special characters
  ([#293](https://github.com/dahlbyk/posh-git/issues/293))
  ([PR #413](https://github.com/dahlbyk/posh-git/pull/413))

## Thank You

Thank you to the following folks who contributed their time and scripting skills to make posh-git better:

- Keith Hill (@rkeithhill)
  - [Pester test infrastructure](https://github.com/dahlbyk/posh-git/commits/master/test?author=rkeithhill)
  - Triage of open issues and PRs
  - Many README and help improvements
  - Many of the fixes enumerated above
- Marcus Reid (@cmarcusreid)
  - Use [GitStatusCache](https://github.com/cmarcusreid/git-status-cache) when it's installed
    ([PR #208](https://github.com/dahlbyk/posh-git/pull/208))
  - Report UpstreamGone from GitStatusCache response
    ([PR #372](https://github.com/dahlbyk/posh-git/pull/372))
- Jason Shirk (@lzybkr)
  - Speed up `Get-GitStatus`
    ([PR #319](https://github.com/dahlbyk/posh-git/pull/319))
  - Use `PSCustomObject` case for sorted output of `$GitPromptSettings`
    ([PR #382](https://github.com/dahlbyk/posh-git/pull/382))
- Ralf Müller (@seamlessintegrations)
  - Add support for tab-completion of Git parameters
    ([PR #395](https://github.com/dahlbyk/posh-git/pull/395))
- Aksel Kvitberg (@Flueworks)
  - Add Worktree tab completion
    ([PR #366](https://github.com/dahlbyk/posh-git/pull/366))
- Eric Amodio (@eamodio)
  - Add aliasing support for TortoiseGit commands
    ([PR #394](https://github.com/dahlbyk/posh-git/pull/394))
- Kevin Shaw (@shawmanz32na)
  - Add DefaultPromptAbbreviateHomeDirectory setting
    ([PR #387](https://github.com/dahlbyk/posh-git/pull/387))
- KanjiBates (@KanjiBates)
  - Fix link to git-scm.com in README.md
    ([PR #396](https://github.com/dahlbyk/posh-git/pull/396))
- Joel Rowley (@hjoelr)
  - Fix syntax error on setenv calls
    ([PR #297](https://github.com/dahlbyk/posh-git/pull/297))
- Hui Sun (@JimAmuro)
  - Fix [#298](https://github.com/dahlbyk/posh-git/issues/298) remove-item error after startup
    ([PR #299](https://github.com/dahlbyk/posh-git/pull/299))
- Josh (@joshgo)
  - Add tags to 'push' tab-completion
    ([PR #286](https://github.com/dahlbyk/posh-git/pull/286))
- Rebecca Turner (@9999years)
  - Add new settings for prompt FileAddedText, FileModifiedText, FileRemovedText and FileConflictText
    ([PR #277](https://github.com/dahlbyk/posh-git/pull/277))
- Jack (@Jackbennett)
  - Export command Write-VcsStatus to improve module auto-loading
    ([PR #284](https://github.com/dahlbyk/posh-git/pull/284))
- Brendan Forster (@shiftkey)
  - Improvements to README.md
    ([PR #273](https://github.com/dahlbyk/posh-git/pull/273))
    ([PR #274](https://github.com/dahlbyk/posh-git/pull/274))
- Paul Marston (@paulmarsy)
  - Update README.md to reflect recent changes to the Git prompt
    ([PR #221](https://github.com/dahlbyk/posh-git/pull/221))
  - Add error handling to Write-VcsStatus
    ([PR #170](https://github.com/dahlbyk/posh-git/pull/170))
- INOMATA Kentaro (@matarillo)
  - Fix branch names using UTF8 characters do not display correctly
    ([PR #223](https://github.com/dahlbyk/posh-git/pull/223))
- Luis Vita (@Ivita)
  - Fix typo in git commit parameter --amend in tab exansion
    ([PR #405](https://github.com/dahlbyk/posh-git/pull/405))
- Skeept (@skeept)
  - Fix debug prompt breaking posh-git prompt on PowerShell v4
    ([PR #406](https://github.com/dahlbyk/posh-git/pull/406))
- @theaquamarine
  - Fix [#249](https://github.com/dahlbyk/posh-git/issues/249), handling of multiple Pageant keys
    ([PR #255](https://github.com/dahlbyk/posh-git/pull/255))
- Jan De Dobbeleer (@JanJoris)
  - Remove errors thrown by `git symbolic-ref` and `git describe`
    ([PR #307](https://github.com/dahlbyk/posh-git/pull/307))
- Dan Smith (@dozius)
  - Add tab completion for AVH git-flow commands
    ([PR #231](https://github.com/dahlbyk/posh-git/pull/231))
- @drawfour
  - Add ahead/behind count to prompt
    ([PR #256](https://github.com/dahlbyk/posh-git/pull/256))
- Dan Turner (@dan-turner)
  - Add tab completion support for shorthand force-push syntax (`git push <remote> +<tab>`)
    ([PR #174](https://github.com/dahlbyk/posh-git/pull/174))
- Mark Hillebrand (@mah)
  - Add tab completion of unique remote branch names for `git checkout <tab>`
    ([PR #251](https://github.com/dahlbyk/posh-git/pull/251))
- Jeff Yates (@somewhatabstract)
  - Don't rerun Pageant if there are no keys to add
    ([PR #441](https://github.com/dahlbyk/posh-git/pull/441))
- Tolga Balci (@tolgabalci)
  - Create $PROFILE parent directory if missing
    ([PR #449](https://github.com/dahlbyk/posh-git/pull/449))
  - Add -verbose parameter to install.ps1
    ([PR #451](https://github.com/dahlbyk/posh-git/pull/451))

[ansi-esc-code]:   https://en.wikipedia.org/wiki/ANSI_escape_code
[console-vt-seq]:  https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
[invokecommand-expandstring]: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.commandinvocationintrinsics.expandstring
