using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace PoshGit {
    public enum ColorMode {
        DefaultColor,
        ConsoleColor,
        XTerm256,
        Rgb
    }

    public enum AnsiTextOption {
        Default         = 0,   // Returns all attributes to the default state prior to modification
        Bold            = 1,   // Applies brightness/intensity flag to foreground color
        Underline       = 4,   // Adds underline
        NoUnderline     = 24,  // Removes underline
        Negative        = 7,   // Swaps foreground and background colors
        Positive        = 27,  // Returns foreground/background to normal
        FgBlack         = 30,  // Applies non-bold/bright black to foreground
        FgRed           = 31,  // Applies non-bold/bright red to foreground
        FgGreen         = 32,  // Applies non-bold/bright green to foreground
        FgYellow        = 33,  // Applies non-bold/bright yellow to foreground
        FgBlue          = 34,  // Applies non-bold/bright blue to foreground
        FgMagenta       = 35,  // Applies non-bold/bright magenta to foreground
        FgCyan          = 36,  // Applies non-bold/bright cyan to foreground
        FgWhite         = 37,  // Applies non-bold/bright white to foreground
        FgExtended      = 38,  // Applies extended color value to the foreground (see details below)
        FgDefault       = 39,  // Applies only the foreground portion of the defaults (see 0)
        BgBlack         = 40,  // Applies non-bold/bright black to background
        BgRed           = 41,  // Applies non-bold/bright red to background
        BgGreen         = 42,  // Applies non-bold/bright green to background
        BgYellow        = 43,  // Applies non-bold/bright yellow to background
        BgBlue          = 44,  // Applies non-bold/bright blue to background
        BgMagenta       = 45,  // Applies non-bold/bright magenta to background
        BgCyan          = 46,  // Applies non-bold/bright cyan to background
        BgWhite         = 47,  // Applies non-bold/bright white to background
        BgExtended      = 48,  // Applies extended color value to the background (see details below)
        BgDefault       = 49,  // Applies only the background portion of the defaults (see 0)
        FgBrightBlack   = 90,  // Applies bold/bright black to foreground
        FgBrightRed     = 91,  // Applies bold/bright red to foreground
        FgBrightGreen   = 92,  // Applies bold/bright green to foreground
        FgBrightYellow  = 93,  // Applies bold/bright yellow to foreground
        FgBrightBlue    = 94,  // Applies bold/bright blue to foreground
        FgBrightMagenta = 95,  // Applies bold/bright magenta to foreground
        FgBrightCyan    = 96,  // Applies bold/bright cyan to foreground
        FgBrightWhite   = 97,  // Applies bold/bright white to foreground
        BgBrightBlack   = 100, // Applies bold/bright black to background
        BgBrightRed     = 101, // Applies bold/bright red to background
        BgBrightGreen   = 102, // Applies bold/bright green to background
        BgBrightYellow  = 103, // Applies bold/bright yellow to background
        BgBrightBlue    = 104, // Applies bold/bright blue to background
        BgBrightMagenta = 105, // Applies bold/bright magenta to background
        BgBrightCyan    = 106, // Applies bold/bright cyan to background
        BgBrightWhite   = 107, // Applies bold/bright white to background
    }

    public static class Ansi {
        public static Dictionary<string, int> ConsoleColorToAnsi = new Dictionary<string, int>() {
            {"Black",       30},
            {"DarkBlue",    34},
            {"DarkGreen",   32},
            {"DarkCyan",    36},
            {"DarkRed",     31},
            {"DarkMagenta", 35},
            {"DarkYellow",  33},
            {"Gray",        37},
            {"DarkGray",    90},
            {"Blue",        94},
            {"Green",       92},
            {"Cyan",        96},
            {"Red",         91},
            {"Magenta",     95},
            {"Yellow",      93},
            {"White",       97}
        };

        public static string GetAnsiSequence(Color color, bool isForeground)
        {
            var extended = (int)(isForeground ? AnsiTextOption.FgExtended : AnsiTextOption.BgExtended);
            var sgrSubSeq256 = "5";
            var sgrSubSeqRgb = "2";

            switch (color.ColorMode)
            {
                case ColorMode.ConsoleColor:
                    string consoleColorName = Enum.GetName(typeof(ConsoleColor), color.ConsoleColor);
                    int ansiValue = ConsoleColorToAnsi[consoleColorName];
                    ansiValue += isForeground ? 0 : 10;
                    return ansiValue.ToString();

                case ColorMode.XTerm256:
                    byte index = color.XTerm256Index;
                    var xtermAnsiSeq = String.Format("{0};{1};{2}", extended, sgrSubSeq256, index);
                    return xtermAnsiSeq;

                case ColorMode.Rgb:
                    var rgbAnsiSeq = String.Format("{0};{1};{2};{3};{4}", extended, sgrSubSeqRgb, color.Red, color.Green, color.Blue);
                    return rgbAnsiSeq;

                case ColorMode.DefaultColor:
                    var defaultColor = (int)(isForeground ? AnsiTextOption.FgDefault : AnsiTextOption.BgDefault);
                    return defaultColor.ToString();

                default:
                    throw new ArgumentException("Unexpected ColorMode value " + color.ColorMode.ToString());
            }
        }

        public static string GetAnsiSequence(TextSpan textSpan)
        {
            if (!String.IsNullOrWhiteSpace(textSpan.CustomAnsiSeq)) {
                // TODO: what if someone wants custom ansi after the text?
                return String.Format("{0}{1}{2}m", textSpan.CustomAnsiSeq, textSpan.Text, (int)AnsiTextOption.Default);
            }

            return GetAnsiSequence(textSpan.Text, textSpan.ForegroundColor, textSpan.BackgroundColor);
        }

        public static string GetAnsiSequence(string text, Color foregroundColor, Color backgroundColor)
        {
            string ansiSeq;
            string fgSeq = GetAnsiSequence(foregroundColor, true);
            string bgSeq = GetAnsiSequence(backgroundColor, false);

            if ((foregroundColor.ColorMode == ColorMode.DefaultColor) &&
                (backgroundColor.ColorMode == ColorMode.DefaultColor))
            {
                ansiSeq = text;
            }
            else if (foregroundColor.ColorMode == ColorMode.DefaultColor)
            {
                ansiSeq = String.Format("\x1b[{0}m{1}\x1b[{2}m", bgSeq, text, (int)AnsiTextOption.Default);
            }
            else if (backgroundColor.ColorMode == ColorMode.DefaultColor)
            {
                ansiSeq = String.Format("\x1b[{0}m{1}\x1b[{2}m", fgSeq, text, (int)AnsiTextOption.Default);
            }
            else
            {
                ansiSeq = String.Format("\x1b[{0}m\x1b[{1}m{2}\x1b[{3}m", fgSeq, bgSeq, text, (int)AnsiTextOption.Default);
            }

            return ansiSeq;
        }
    }

    public class Color
    {
        private ColorMode _mode;
        private int _value;

        // Use this constructor to specify the default color
        public Color()
        {
            _mode = ColorMode.DefaultColor;
            _value = -1;
        }

        public Color(Color color)
        {
            _mode = color._mode;
            _value = color._value;
        }

        public Color(ConsoleColor consoleColor)
        {
            _mode = ColorMode.ConsoleColor;
            _value = (int)consoleColor;
        }

        public Color(string consoleColorName)
        {
            ConsoleColor consoleColor;
            if (Enum.TryParse<ConsoleColor>(consoleColorName, true, out consoleColor))
            {
                _mode = ColorMode.ConsoleColor;
                _value = (int)consoleColor;
            }
            else
            {
                throw new ArgumentException("Unrecognized ConsoleColor name " + consoleColorName);
            }
        }

        public Color(byte xterm256Index)
        {
            _mode = ColorMode.XTerm256;
            _value = xterm256Index;
        }

        public Color(byte red, byte green, byte blue)
        {
            _mode = ColorMode.Rgb;
            _value = (red << 16) + (green << 8) + blue;
        }

        public Color(int rgb) {
            _mode = ColorMode.Rgb;
            _value = rgb & 0x00FFFFFF;
        }

        public ColorMode ColorMode
        {
            get { return _mode; }
        }

        public ConsoleColor ConsoleColor
        {
            get
            {
                if (_mode != ColorMode.ConsoleColor)
                {
                    throw new InvalidOperationException("ConsoleColor is only valid when ColorMode is set to ConsoleColor.");
                }

                return (ConsoleColor)_value;
            }
        }

        public byte XTerm256Index
        {
            get
            {
                if (_mode != ColorMode.XTerm256)
                {
                    throw new InvalidOperationException("XTerm256Index is only valid when ColorMode is set to XTerm256.");
                }

                return (byte)_value;
            }
        }

        public int Rgb
        {
            get
            {
                VerifyColorModeRgb();
                return _value;
            }
        }

        public byte Red
        {
            get
            {
                VerifyColorModeRgb();
                return (byte)((_value & 0x00FF0000) >> 16);
            }
        }

        public byte Green
        {
            get
            {
                VerifyColorModeRgb();
                return (byte)((_value & 0x0000FF00) >> 8);
            }
        }

        public byte Blue
        {
            get
            {
                VerifyColorModeRgb();
                return (byte)(_value & 0x000000FF);
            }
        }

        public override string ToString() {
            switch (_mode) {
                case ColorMode.ConsoleColor:
                    return Enum.GetName(typeof(ConsoleColor), _value);

                case ColorMode.XTerm256:
                    return "XTerm256: " + _value.ToString();

                case ColorMode.Rgb:
                    return String.Format("RGB: 0x{0:X8}", _value);

                case ColorMode.DefaultColor:
                    return "<DefaultColor>";
            }

            return base.ToString();
        }

        private void VerifyColorModeRgb()
        {
            if (_mode != ColorMode.Rgb)
            {
                throw new InvalidOperationException("Rgb is only valid when ColorMode is set to Rgb.");
            }
        }
    }

    public class TextSpan {
        private string _text;
        private string _customAnsiSeq;
        private Color _backgroundColor;
        private Color _foregroundColor;
        private Color _foregroundBrightColor;

        public TextSpan(TextSpan textSpan)
        : this(textSpan.Text, textSpan.ForegroundColor, textSpan.ForegroundBrightColor, textSpan.BackgroundColor)
        {
        }

        public TextSpan(string text)
        : this(text, new Color(), new Color())
        {
        }

        public TextSpan(string text, Color foregroundColor)
        : this(text, foregroundColor, new Color())
        {
        }

        public TextSpan(string text, string foregroundConsoleColorName, Color backgroundColor)
        : this(text, new Color(foregroundConsoleColorName), backgroundColor)
        {
        }

        public TextSpan(string text, string foregroundConsoleColorName, string foregroundBrightConsoleColorName, Color backgroundColor)
        : this(text, new Color(foregroundConsoleColorName), new Color(foregroundBrightConsoleColorName), backgroundColor)
        {
        }

        public TextSpan(string text, Color foregroundColor, Color backgroundColor)
        : this(text, foregroundColor, new Color(), backgroundColor)
        {
        }

        public TextSpan(string text, Color foregroundColor, Color foregroundBrigthColor, Color backgroundColor)
        {
            _text = text;
            _foregroundColor = foregroundColor;
            _foregroundBrightColor = foregroundBrigthColor;
            _backgroundColor = backgroundColor;
            _customAnsiSeq = string.Empty;
        }

        public TextSpan(string text, string customAnsiSeq)
        {
            _text = text;
            _customAnsiSeq = customAnsiSeq;
        }

        public string Text
        {
            get { return _text; }
            set { _text = value ?? string.Empty; }
        }

        public string CustomAnsiSeq
        {
            get { return _customAnsiSeq; }
            set { _customAnsiSeq = value ?? string.Empty; }
        }

        public Color BackgroundColor
        {
            get { return _backgroundColor; }
            set { _backgroundColor = value ?? new Color(); }
        }

        public Color ForegroundColor
        {
            get { return _foregroundColor; }
            set { _foregroundColor = value ?? new Color(); }
        }

        public Color ForegroundBrightColor
        {
            get { return _foregroundBrightColor; }
            set { _foregroundBrightColor = value ?? new Color(); }
        }

        public override string ToString()
        {
            if (String.IsNullOrWhiteSpace(_customAnsiSeq))
            {
                if (_foregroundBrightColor.ColorMode == ColorMode.DefaultColor)
                {
                    return String.Format("'{0}', fg:{1}, bg:{2}", _text, _foregroundColor, _backgroundColor);
                }

                return String.Format("'{0}', fg:{1}, fgB:{2}, bg:{3}", _text, _foregroundColor, _foregroundBrightColor, _backgroundColor);
            }
            else
            {
                return String.Format("'{0}', ansi:{1}", _text, _customAnsiSeq);
            }
        }
    }

    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false)]
    public sealed class ColorTransformAttribute : ArgumentTransformationAttribute
    {
        public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        {
            if (inputData == null)
            {
                return new Color();
            }

            if (inputData is Color)
            {
                return inputData;
            }

            if (inputData is ConsoleColor)
            {
                return new Color((ConsoleColor)inputData);
            }

            if (inputData is string)
            {
                var consoleColorName = (string)inputData;
                return new Color(consoleColorName);
            }

            if (inputData is byte)
            {
                var index = (byte)inputData;
                if (index < 16)
                {
                    var consoleColor = (ConsoleColor)index;
                    return new Color(consoleColor);
                }
                else
                {
                    return new Color(index);
                }
            }

            if (inputData is int)
            {
                var rgb = (int)inputData;
                return new Color(rgb);
            }

            throw new PSArgumentException("Could not transform type '" + inputData.GetType().FullName + "' to PoshGit.Color");
        }

        public override bool TransformNullOptionalParameters
        {
            get { return true; }
        }
    }
}
