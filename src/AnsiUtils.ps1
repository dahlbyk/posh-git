# enum ColorMode {
#     ColorModeDefaultColor
#     ColorModeConsole
#     ColorMode256
#     ColorMode24Bit
# }

# enum AnsiTextOption {
#     Default         = 0   # Returns all attributes to the default state prior to modification
#     Bold            = 1   # Applies brightness/intensity flag to foreground color
#     Underline       = 4   # Adds underline
#     NoUnderline     = 24  # Removes underline
#     Negative        = 7   # Swaps foreground and background colors
#     Positive        = 27  # Returns foreground/background to normal
#     FgBlack         = 30  # Applies non-bold/bright black to foreground
#     FgRed           = 31  # Applies non-bold/bright red to foreground
#     FgGreen         = 32  # Applies non-bold/bright green to foreground
#     FgYellow        = 33  # Applies non-bold/bright yellow to foreground
#     FgBlue          = 34  # Applies non-bold/bright blue to foreground
#     FgMagenta       = 35  # Applies non-bold/bright magenta to foreground
#     FgCyan          = 36  # Applies non-bold/bright cyan to foreground
#     FgWhite         = 37  # Applies non-bold/bright white to foreground
#     FgExtended      = 38  # Applies extended color value to the foreground (see details below)
#     FgDefault       = 39  # Applies only the foreground portion of the defaults (see 0)
#     BgBlack         = 40  # Applies non-bold/bright black to background
#     BgRed           = 41  # Applies non-bold/bright red to background
#     BgGreen         = 42  # Applies non-bold/bright green to background
#     BgYellow        = 43  # Applies non-bold/bright yellow to background
#     BgBlue          = 44  # Applies non-bold/bright blue to background
#     BgMagenta       = 45  # Applies non-bold/bright magenta to background
#     BgCyan          = 46  # Applies non-bold/bright cyan to background
#     BgWhite         = 47  # Applies non-bold/bright white to background
#     BgExtended      = 48  # Applies extended color value to the background (see details below)
#     BgDefault       = 49  # Applies only the background portion of the defaults (see 0)
#     FgBrightBlack   = 90  # Applies bold/bright black to foreground
#     FgBrightRed     = 91  # Applies bold/bright red to foreground
#     FgBrightGreen   = 92  # Applies bold/bright green to foreground
#     FgBrightYellow  = 93  # Applies bold/bright yellow to foreground
#     FgBrightBlue    = 94  # Applies bold/bright blue to foreground
#     FgBrightMagenta = 95  # Applies bold/bright magenta to foreground
#     FgBrightCyan    = 96  # Applies bold/bright cyan to foreground
#     FgBrightWhite   = 97  # Applies bold/bright white to foreground
#     BgBrightBlack   = 100 # Applies bold/bright black to background
#     BgBrightRed     = 101 # Applies bold/bright red to background
#     BgBrightGreen   = 102 # Applies bold/bright green to background
#     BgBrightYellow  = 103 # Applies bold/bright yellow to background
#     BgBrightBlue    = 104 # Applies bold/bright blue to background
#     BgBrightMagenta = 105 # Applies bold/bright magenta to background
#     BgBrightCyan    = 106 # Applies bold/bright cyan to background
#     BgBrightWhite   = 107 # Applies bold/bright white to background
# }

# class Ansi {
#     hidden static $ConsoleColorToAnsi = @(
#         30 # Black
#         34 # DarkBlue
#         32 # DarkGreen
#         36 # DarkCyan
#         31 # DarkRed
#         35 # DarkMagenta
#         33 # DarkYellow
#         37 # Gray
#         90 # DarkGray
#         94 # Blue
#         92 # Green
#         96 # Cyan
#         91 # Red
#         95 # Magenta
#         93 # Yellow
#         97 # White
#     )

#     static [bool] HostSupportsAnsi() {
#         return $global:Host.UI.SupportsVirtualTerminal
#     }

#     # TODO: Not sure we need this.
#     static [bool] HostSupports24BitColor() {
#         # On Windows, if we are on 10.0.15048.0 (or whatever the CU update's version number is) 24bit color is supported.
#         # On Linux/macOS, need to figure out how to determine this.
#         return $false
#     }

#     static [string] GetAnsiSequence([Color]$color, [bool]$IsForeground) {
#         $ansiSeq = ""
#         $sgrSubSeq256 = "5"
#         $sgrSubSeqRgb = "2"
#         [int]$extended = if ($IsForeground) { [AnsiTextOption]::FgExtended } else { [AnsiTextOption]::BgExtended }

#         switch ($color.ColorMode()) {
#             ([ColorMode]::ColorModeConsole) {
#                 $ansiValue = [Ansi]::ConsoleColorToAnsi[$color.ConsoleColor()]
#                 if (!$IsForeground) {
#                     $ansiValue += 10
#                 }
#                 $ansiSeq = $ansiValue
#                 break
#             }
#             ([ColorMode]::ColorMode256) {
#                 $colorIndex = $color.Color256Index()
#                 $ansiSeq = "$extended;$sgrSubSeq256;$colorIndex"
#                 break
#             }
#             ([ColorMode]::ColorMode24Bit) {
#                 $r = $color.Red()
#                 $g = $color.Green()
#                 $b = $color.Blue()
#                 $ansiSeq = "$extended;$sgrSubSeqRgb;$r;$g;$b"
#                 break
#             }
#             ([ColorMode]::ColorModeDefaultColor) {
#                 [int]$defaultColor = if ($IsForeground) { [AnsiTextOption]::FgDefault } else { [AnsiTextOption]::BgDefault }
#                 $ansiSeq = "$defaultColor"
#                 break
#             }
#             default {
#                 throw "Unexpected ColorMode '$($color.ColorMode())'"
#             }
#         }

#         return $ansiSeq;
#     }

#     static [string] GetAnsiSequence([TextSpan]$TextSpan) {
#         return [Ansi]::GetAnsiSequence($TextSpan.Text, $TextSpan.ForegroundColor, $TextSpan.BackgroundColor)
#     }

#     static [string] GetAnsiSequence([string]$Text, [Color]$ForegroundColor, [Color]$BackgroundColor) {
#         $ESC = [char]0x1B

#         $fgSeq = [Ansi]::GetAnsiSequence($ForegroundColor, $true)
#         $bgSeq = [Ansi]::GetAnsiSequence($BackgroundColor, $false)
#         $def = [int][AnsiTextOption]::Default

#         $ansiSeq = "$ESC[${fgSeq};${bgSeq}m${Text}$ESC[${def}m"
#         return $ansiSeq
#     }
# }

# class Color {
#     hidden [ColorMode]$mode
#     hidden [int]$value

#     # Use this constructor to specify the default color
#     Color() {
#         $this.mode = [ColorMode]::ColorModeDefaultColor
#         $this.value = -1
#     }

#     Color([Color]$color) {
#         $this.mode = $color.mode
#         $this.value = $color.value
#     }

#     Color([System.ConsoleColor]$consoleColor) {
#         $this.mode = [ColorMode]::ColorModeConsole
#         $this.value = [int]$consoleColor
#     }

#     Color([byte]$color256Index) {
#         $this.mode = [ColorMode]::ColorMode256
#         $this.value = $color256Index
#     }

#     Color([byte]$red, [byte]$green, [byte]$blue) {
#         $this.mode = [ColorMode]::ColorMode24Bit
#         $this.value = ($red -shl 16) + ($green -shl 8) + $blue
#     }

#     Color([int]$rgb) {
#         $this.mode = [ColorMode]::ColorMode24Bit
#         $this.value = $rgb -band 0x00FFFFFF
#     }

#     [ColorMode] ColorMode() {
#         return $this.mode
#     }

#     [System.ConsoleColor] ConsoleColor() {
#         if ($this.mode -ne [ColorMode]::ColorModeConsole) {
#             throw "ConsoleColor() is only valid when ColorMode is ColorModeConsole."
#         }
#         return [System.ConsoleColor]$this.value
#     }

#     [byte] Color256Index() {
#         if ($this.mode -ne [ColorMode]::ColorMode256) {
#             throw "Color256Index() is only valid when ColorMode is ColorMode256."
#         }
#         return [byte]$this.value
#     }

#     [int] Rgb() {
#         if ($this.mode -ne [ColorMode]::ColorMode24Bit) {
#             throw "Rgb() is only valid when ColorMode is ColorMode24Bit."
#         }
#         return $this.value
#     }

#     [byte] Red() {
#         if ($this.mode -ne [ColorMode]::ColorMode24Bit) {
#             throw "Red() is only valid when ColorMode is ColorMode24Bit."
#         }
#         return ($this.value -band 0x00FF0000) -shr 16
#     }

#     [byte] Green() {
#         if ($this.mode -ne [ColorMode]::ColorMode24Bit) {
#             throw "Green() is only valid when ColorMode is ColorMode24Bit."
#         }
#         return ($this.value -band 0x0000FF00) -shr 8
#     }

#     [byte] Blue() {
#         if ($this.mode -ne [ColorMode]::ColorMode24Bit) {
#             throw "Blue() is only valid when ColorMode is ColorMode24Bit."
#         }
#         return ($this.value -band 0x000000FF)
#     }
# }

# class TextSpan {
#     [string]$Text
#     [Color]$BackgroundColor
#     [Color]$ForegroundColor

#     TextSpan([string]$text) {
#         $this.Text = $text
#         $this.ForegroundColor = [Color]::new()
#         $this.BackgroundColor = [Color]::new()
#     }

#     TextSpan([string]$text, [Color]$foregroundColor) {
#         $this.Text = $text
#         $this.ForegroundColor = $foregroundColor
#         $this.BackgroundColor = [Color]::new()
#     }

#     TextSpan([string]$text, [Color]$foregroundColor, [Color]$backgroundColor) {
#         $this.Text = $text
#         $this.ForegroundColor = $foregroundColor
#         $this.BackgroundColor = $backgroundColor
#     }
# }
