A set of PowerShell scripts which provide Git/PowerShell integration

 - Prompt for Git repositories:
   The prompt within Git repositories can show the current branch and the state of files (additions, modifications, deletions) within.
 - Tab completion:
   Provides tab completion for common commands when using git.  
   E.g. `git ch<tab>` --> `git checkout`
   
Usage
-----

See profile.example.ps1 as to how you can integrate the tab completion and/or git prompt into your own profile. You can also choose whether advanced git commands are shown in the tab expansion or only simple/common commands. Default is simple.

Installing
----------

posh-git requires you to modify/create your Powershell Profile. 
 - Put all posh-git files in your C:\Users\<username>\Documents\WindowsPowerShell folder (create it if it doesn't exist)
 - Rename profile.example.ps1 to Microsoft.PowerShell_profile.ps1 
 - If you already have a PowerShell_profile.ps1 you can add the code from profile.example.ps1 to it and it should work fine.
 - posh-git requires you to set the executionpolicy to remotesigned in order to function. Execute (with admin privileges):
	Set-ExecutionPolicy RemoteSigned 
	(More Info on ExecutionPolicy: http://technet.microsoft.com/en-us/library/ee176949.aspx)

Based on work by:

 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
