<#
	The following code is used to add hints to git tab completion
	It's called in GitTabExpansion.ps1 / Expand-GitCommand
#>

# This caches the hints to reduce command executions
$script:paramHints = @{}

<#
	.DESCRIPTION
	Returns a short help for the questioned git mode or $null if no help is available
	.PARAMETER Mode
	the mode for which the help is needed
#>
function Get-GITModeHint {
	param (
		[String] $Mode
	)

	$Command="git"

	# Ensure the "command key" is present
	if (-not $script:paramHints.containsKey($Command)) { $script:paramHints.add($Command, @{}) }
	# Populate the "mode branch" if empty
	if (-not $script:paramHints.$Command.containsKey("*")) {
		$helpStrings = Invoke-Utf8ConsoleCommand { & $Command --no-pager help -a 2>&1 }
		$modeTable = @{}
		foreach ($line in $helpStrings) {
			if ($line -match "\s{3,3}([^\s]*)\s+(.*)") {
				$modeTable.add($matches[1], $matches[2])
			}
		}
		$script:paramHints.$Command.add("*", $modeTable)
	}

	# Create the results
	if ($script:paramHints.$Command."*".containsKey($Mode))
	{
		return @($Mode, $script:paramHints.$Command."*".$Mode)
	} else {
		return $null
	}
}

<#
	.DESCRIPTION
	Returns a short help for the provided option or $null if no help is available
	.PARAMETER Mode
	The mode of git (e.g. commit)
	.PARAMETER Parameter
	The actual parameter, for which the help is needed
#>
function Get-GITParameterHint {
	param (
		[String] $Mode,
		[String] $Parameter
	)

	$Command="git"

	# Ensure the "command key" is present
	if (-not $script:paramHints.containsKey($Command)) { $script:paramHints.add($Command, @{}) }
	# Populate the "mode branch" if empty
	if (-not $script:paramHints.$Command.containsKey($Mode)) {
		$helpStrings = Invoke-Utf8ConsoleCommand { & $Command -C "$($env:temp)" --no-pager $Mode -h 2>&1 }
		$preProcessedStrings = @()
		# Preprocessing
		foreach ($line in $helpStrings)
		{
			switch -RegEx ($line) {
				"^\s{4,4}(-.*)$" {
					# this is a line defining a parameter
					$preProcessedStrings += "$($Matches[1])"
				}
				"^\s{25,25}(\s.*)$" {
					# this line belongs to the parameter description of the line before
					$preProcessedStrings[-1] = "$($preProcessedStrings[-1])$($Matches[1])"
				}
			}
		}
		$helpTable = [HashTable]::New(0, [StringComparer]::Ordinal)
		foreach ($line in $preProcessedStrings)
		{
			switch -RegEx ($line) {
				# -p, --param   This is the parameter p
				# -p, --[no-]param   This is the parameter p
				"^(-.), --(?:\[no-\]){0,1}([^\s\[]+)\s+([^<]*)$" {
					$helpTable.add($matches[1], @(($matches[1] +" ("+ $matches[2] +")"), $matches[3]))
					$helpTable.add("--"+$matches[2], @(("--"+ $matches[2]), $matches[3]))
					break
				}
				# --param   This is the parameter p
				# --[no-]param   This is the parameter p
				"^--(?:\[no-\]){0,1}([^\s\[]+)\s+([^<]*)$" {
					$helpTable.add("--"+$matches[1], @(("--"+ $matches[1]), $matches[2]))
					break
				}
				# -p   This is the parameter p
				"^(-[^-])\s+([^<]*)$" {
					$helpTable.add($matches[1], @($matches[1], $matches[2]))
					break
				}
				# -p, --param <file>     This is the parameter p
				# -p, --[no-]param <file>     This is the parameter p
				"^(-.), --(?:\[no-\]){0,1}([^\s\[]+)\s(<[^>]*>)\s+(.*)$" {
					$helpTable.add($matches[1], @(($matches[1] +" ("+ $matches[2] +")"), ($matches[3]+" | "+$matches[4])))
					$helpTable.add("--"+$matches[2], @(("--"+ $matches[2]), ($matches[3]+" | "+$matches[4])))
					break
				}
				# --param <file>     This is the parameter p
				# --[no-]param <file>     This is the parameter p
				"^--(?:\[no-\]){0,1}([^\s\[]+)\s(<[^>]*>)\s+(.*)$" {
					$helpTable.add("--"+$matches[1], @(("--"+ $matches[1]), ($matches[2]+" | "+$matches[3])))
					break
				}
				# -p <file>     This is the parameter p
				"^(-[^-])\s(<[^>]*>)\s+(.*)$" {
					$helpTable.add($matches[1], @($matches[1], ($matches[2]+" | "+$matches[3])))
					break
				}
				# -p, --param[=foo]     This is the parameter p
				# -p, --[no-]param[=foo]     This is the parameter p
				"^(-.), --(?:\[no-\]){0,1}([^\s\[]+)(\[[^\]]*\])\s+(.*)$" {
					$helpTable.add($matches[1], @(($matches[1] +" ("+ $matches[2] +")"), ($matches[3]+" | "+$matches[4])))
					$helpTable.add("--"+$matches[2], @(("--"+ $matches[2]), ($matches[3]+" | "+$matches[4])))
					break
				}
				# --param[=foo]     This is the parameter p
				# --[no-]param[=foo]     This is the parameter p
				"^--(?:\[no-\]){0,1}([^\s\[]+)(\[[^\]]*\])\s+(.*)$" {
					$helpTable.add("--"+$matches[1], @(("--"+ $matches[1]), ($matches[2]+" | "+$matches[3])))
					break
				}
				# -p[=foo]     This is the parameter p
				"^(-[^-])(\[[^\]]*\])\s+(.*)$" {
					$helpTable.add($matches[1], @($matches[1], ($matches[2]+" | "+$matches[3])))
					break
				}
			}
		}
		$script:paramHints.$Command.add($Mode, $helpTable)
	}

	# Create the results
	if ($script:paramHints.$Command.$Mode.containsKey($Parameter))
	{
		return @(($script:paramHints.$Command.$Mode.$Parameter)[0], ($script:paramHints.$Command.$Mode.$Parameter)[1])
	} else {
		return $null
	}
}

<#
	.DESCRIPTION
	The function takes the original command line and already defined possible completions; it will add the hints depending on the context
	.PARAMETER Command
	The originating command line
	.PARAMETER PossibleParams
	The possible parameters as a string array
#>
function Add-HintsToParams {
	param (
		[String] $Command,
		[String[]] $PossibleParams
	)

	$cmdParts = $Command.split()

	# We are only handling git at the moment
	if ($Command -notmatch "^$(Get-AliasPattern git) (.*)") { return $PossibleParams }

	# Determing git mode, which is the first parameter without dashes, but not the last one, which is "" or an incomplete parameter
	$cmdMode = $null
	for ($i=1; $i -lt $cmdParts.length-1; $i++) {
		if (-not $cmdParts[$i].StartsWith("-")) {
			$cmdMode = $cmdParts[$i]
			break
		}
	}

	$newTabCompletions = @()
	if ($cmdMode) {
		# we're searching a parameter for mode $cmdMode
		foreach ($p in $PossibleParams) {
		$desc = Get-GITParameterHint -Mode $cmdMode -Parameter $p
			if ($desc) {
				$newTabCompletions += [System.Management.Automation.CompletionResult]::new($p, $desc[0], 'ParameterValue', $desc[1])
			} else {
				$newTabCompletions += $p
			}
		}
	} else {
		# at the moment, we have no command mode in the command line and are looking for a mode
		foreach ($m in $PossibleParams) {
			$desc = Get-GITModeHint -Mode $m
			if ($desc) {
				$newTabCompletions += [System.Management.Automation.CompletionResult]::new($m, $desc[0], 'ParameterValue', $desc[1])
			} else {
				$newTabCompletions += $m
			}
		}
	}
	return $newTabCompletions
}
