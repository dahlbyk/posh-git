A set of PowerShell scripts which provide Git/PowerShell integration

 - Prompt for Git repositories:
   The prompt within Git repositories can show the current branch and the state of files (additions, modifications, deletions) within.
 - Tab completion:
   Provides tab completion for common commands when using git.  
   E.g. `git ch<tab>` --> `git checkout`
   
Usage
-----

See profile.example.ps1 as to how you can integrate the tab completion and/or git prompt into your own profile. You can also choose whether advanced git commands are shown in the tab expansion or only simple/common commands. Default is simple.

Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/