# TortoiseGit 

function private:Get-TortoiseGitPath {
  if ((Test-Path "C:\Program Files\TortoiseGit\bin\TortoiseGitProc.exe") -eq $true) {
    # TortoiseGit 1.8.0 renamed TortoiseProc to TortoiseGitProc.
    return "C:\Program Files\TortoiseGit\bin\TortoiseGitProc.exe"
  }

  return "C:\Program Files\TortoiseGit\bin\TortoiseProc.exe"
}

$Global:TortoiseGitSettings = new-object PSObject -Property @{
  TortoiseGitPath = (Get-TortoiseGitPath)
}

function tgit {
   if($args) {
    if($args[0] -eq "help") {
      # Replace the built-in help behaviour with just a list of commands
      $tortoiseGitCommands
      return    
    }

    $newArgs = @()
    $newArgs += "/command:" + $args[0]
    
    $cmd = $args[0]
    
    if($args.length -gt 1) {
      $args[1..$args.length] | % { $newArgs += $_ }
    }
      
    & $Global:TortoiseGitSettings.TortoiseGitPath $newArgs
  }
}

$tortoiseGitCommands = @(
"about",
"log",
"commit",
"add",
"revert",
"cleanup" ,
"resolve",
"switch",
"export",
"merge",
"settings",
"remove",
"rename",
"diff",
"conflicteditor",
"help",
"ignore",
"blame",
"cat",
"createpatch",
"pull",
"push",
"rebase",
"stashsave",
"stashapply",
"subadd",
"subupdate",
"subsync",
"reflog",
"refbrowse",
"sync",
"repostatus"
) | sort
