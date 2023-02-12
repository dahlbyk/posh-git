$script:badMessages = @('fatal: unrecognized argument', 'error: unknown option', 'error: invalid option', 'error: unknown switch')
$script:VerboseCommands = $false
$script:VerboseErrors = $false

function SetVerbosityForParamValidation($verboseCommands = $false, $verboseErrors = $false) {
    $script:VerboseCommands = $verboseCommands
    $script:VerboseErrors = $verboseErrors
}

function GetErrorStream($command) {
    Invoke-Expression $("& $command 2>''")  -ErrorVariable errStream
    return $errStream
}

function ConvertErrorToString($errorStream) {
    if ($null -eq $errorStream) {
        return ""
    }

    $type = $errorStream.GetType()

    if ($type -eq [System.String]) {
        return $errorStream
    }

    if ($type -eq [System.Management.Automation.ErrorRecord]) {
        return $errorStream.Exception.Message
    }

    if ($type -ne [System.Object[]]) {
        throw "Can't match type of result $type"
    }

    $element = $errorStream[0]
    $elementType = $element.GetType()

    if ($elementType -eq [System.String]) {
        return $element
    }
    if ($elementType -eq [System.Management.Automation.ErrorRecord]) {
        return $element.Exception.Message
    }

    throw "Can't match type of element $elementType"
}

function IsStreamContainsInvalidParamsErrors($errorStream) {
    if ($null -eq $errorStream) {
        return $false
    }

    $streamOutput = ConvertErrorToString -errorStream $errorStream

    foreach ($errorText in $badMessages) {
        if ($streamOutput.StartsWith($errorText)) {
            return $true
        }
    }

    return $false
}

function GetInvalidParams($subcommand, $paramsPrefix, $paramsToSkip = @()) {
    $command = $('git ' + $subcommand + ' ' + $paramsPrefix)
    $gitStatus = Get-GitStatus
    $completions = & $module GitTabExpansionInternal $command $gitStatus
    $invalidCompletions = @()

    foreach ($completion in $completions) {
        if ($paramsToSkip -contains $completion) {
            continue
        }

        $commandUnderTest = "$gitbin $subcommand $completion"

        if ($script:VerboseCommands) {
            Write-Host $commandUnderTest
        }

        $commandErrorOutput = GetErrorStream -command $commandUnderTest
        $hasErrors = IsStreamContainsInvalidParamsErrors -errorStream $commandErrorOutput

        if ($script:VerboseErrors) {
            $printableError = ConvertErrorToString -errorStream $commandErrorOutput
            Write-Host $printableError -ForegroundColor Red
        }

        if ($hasErrors) {
            $invalidCompletions += $completion
        }
    }

    return $invalidCompletions
}

function GetInvalidLongParams($subcommand, $paramsToSkip = @()) {
    return GetInvalidParams -subcommand $subcommand -paramsPrefix '--' -paramsToSkip $paramsToSkip
}

function GetInvalidShortParams($subcommand, $paramsToSkip = @()) {
    return GetInvalidParams -subcommand $subcommand -paramsPrefix '-' -paramsToSkip $paramsToSkip
}
