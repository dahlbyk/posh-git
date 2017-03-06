# Hack! https://gist.github.com/lzybkr/f2059cb2ee8d0c13c65ab933b75e998c

function Set-ConsoleMode
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(ParameterSetName = "ANSI")]
        [switch]
        $ANSI,

        [Parameter(ParameterSetName = "Mode")]
        [uint32]
        $Mode,

        [switch]
        $StandardInput
    )

    if ($PSVersionTable.PSEdition -eq 'Core') {
        return
    }

    if ($ANSI)
    {
        $outputMode = [PoshGit.NativeConsoleMethods]::GetConsoleMode($false)
        $null = [PoshGit.NativeConsoleMethods]::SetConsoleMode($false, $outputMode -bor [PoshGit.ConsoleModeOutputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)

        if ($StandardInput)
        {
            $inputMode = [PoshGit.NativeConsoleMethods]::GetConsoleMode($true)
            $null = [PoshGit.NativeConsoleMethods]::SetConsoleMode($true, $inputMode -bor [PoshGit.ConsoleModeInputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        }
    }
    else
    {
        [PoshGit.NativeConsoleMethods]::SetConsoleMode($StandardInput, $Mode)
    }
}
