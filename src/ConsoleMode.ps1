# Hack! https://gist.github.com/lzybkr/f2059cb2ee8d0c13c65ab933b75e998c

# Always skip setting the console mode on non-Windows platforms.
if (($PSVersionTable.PSVersion.Major -ge 6) -and !$IsWindows) {
    function Set-ConsoleMode {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
        param()
    }

    return
}

$consoleModeSource = @"
using System;
using System.Runtime.InteropServices;

public class NativeConsoleMethods
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetStdHandle(int handleId);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool GetConsoleMode(IntPtr hConsoleOutput, out uint dwMode);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetConsoleMode(IntPtr hConsoleOutput, uint dwMode);

    public static uint GetConsoleMode(bool input = false)
    {
        var handle = GetStdHandle(input ? -10 : -11);
        uint mode;
        if (GetConsoleMode(handle, out mode))
        {
            return mode;
        }
        return 0xffffffff;
    }

    public static uint SetConsoleMode(bool input, uint mode)
    {
        var handle = GetStdHandle(input ? -10 : -11);
        if (SetConsoleMode(handle, mode))
        {
            return GetConsoleMode(input);
        }
        return 0xffffffff;
    }
}
"@

[Flags()]
enum ConsoleModeInputFlags
{
    ENABLE_PROCESSED_INPUT             = 0x0001
    ENABLE_LINE_INPUT                  = 0x0002
    ENABLE_ECHO_INPUT                  = 0x0004
    ENABLE_WINDOW_INPUT                = 0x0008
    ENABLE_MOUSE_INPUT                 = 0x0010
    ENABLE_INSERT_MODE                 = 0x0020
    ENABLE_QUICK_EDIT_MODE             = 0x0040
    ENABLE_EXTENDED_FLAGS              = 0x0080
    ENABLE_AUTO_POSITION               = 0x0100
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0200
}

[Flags()]
enum ConsoleModeOutputFlags
{
    ENABLE_PROCESSED_OUTPUT            = 0x0001
    ENABLE_WRAP_AT_EOL_OUTPUT          = 0x0002
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
}

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

    begin {
        # Module import is speeded up by deferring the Add-Type until the first time this function is called.
        # Add the NativeConsoleMethods type but only once per session.
        if (!('NativeConsoleMethods' -as [System.Type])) {
            Add-Type $consoleModeSource
        }
    }

    end {
        if ($ANSI)
        {
            $outputMode = [NativeConsoleMethods]::GetConsoleMode($false)
            $null = [NativeConsoleMethods]::SetConsoleMode($false, $outputMode -bor [ConsoleModeOutputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)

            if ($StandardInput)
            {
                $inputMode = [NativeConsoleMethods]::GetConsoleMode($true)
                $null = [NativeConsoleMethods]::SetConsoleMode($true, $inputMode -bor [ConsoleModeInputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)
            }
        }
        else
        {
            [NativeConsoleMethods]::SetConsoleMode($StandardInput, $Mode)
        }
    }
}
