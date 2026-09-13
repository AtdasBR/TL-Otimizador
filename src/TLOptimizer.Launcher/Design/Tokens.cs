using System.Drawing;
using System.Drawing.Drawing2D;

namespace TLOptimizer.Launcher.Design;

/// <summary>
/// Design System Tokens — Single source of truth for all visual values.
/// Sincronizado com Theme/Theme.xaml do WPF Installer.
/// </summary>
public static class Tokens
{
    // ============================================================
    // COLOR PALETTE (Dark Theme v1)
    // ============================================================
    public static class Color
    {
        // Background layers
        public static readonly System.Drawing.Color BgPrimary     = FromHex("#0A0A0C");
        public static readonly System.Drawing.Color BgPanel       = FromHex("#141418");
        public static readonly System.Drawing.Color BgCard        = FromHex("#1A1A20");
        public static readonly System.Drawing.Color BgHover       = FromHex("#1E3A5F");
        public static readonly System.Drawing.Color BgPressed     = FromHex("#152A45");
        public static readonly System.Drawing.Color BgOverlay     = FromHex("#000000CC"); // 80% black

        // Accent colors
        public static readonly System.Drawing.Color AccentPrimary   = FromHex("#0067C0");
        public static readonly System.Drawing.Color AccentHover     = FromHex("#0078D4");
        public static readonly System.Drawing.Color AccentPressed   = FromHex("#005A9E");
        public static readonly System.Drawing.Color AccentSuccess   = FromHex("#3CBE5A");
        public static readonly System.Drawing.Color AccentWarning   = FromHex("#E6BE3C");
        public static readonly System.Drawing.Color AccentDanger    = FromHex("#DC4646");
        public static readonly System.Drawing.Color AccentInfo      = FromHex("#0099BC");

        // Borders
        public static readonly System.Drawing.Color BorderSubtle    = FromHex("#2A2A30");
        public static readonly System.Drawing.Color BorderDefault   = FromHex("#3C3C42");
        public static readonly System.Drawing.Color BorderFocus     = FromHex("#0067C0");
        public static readonly System.Drawing.Color BorderError     = FromHex("#DC4646");

        // Text
        public static readonly System.Drawing.Color TextPrimary     = FromHex("#FFFFFF");
        public static readonly System.Drawing.Color TextSecondary   = FromHex("#A0A0A8");
        public static readonly System.Drawing.Color TextMuted       = FromHex("#68686E");
        public static readonly System.Drawing.Color TextInverse     = FromHex("#0A0A0C");
        public static readonly System.Drawing.Color TextOnAccent    = FromHex("#FFFFFF");
        public static readonly System.Drawing.Color TextOnWarning   = FromHex("#0A0A0C");

        // Status semantic
        public static readonly System.Drawing.Color StatusSuccess   = FromHex("#3CBE5A");
        public static readonly System.Drawing.Color StatusWarning   = FromHex("#E6BE3C");
        public static readonly System.Drawing.Color StatusDanger    = FromHex("#DC4646");
        public static readonly System.Drawing.Color StatusInfo      = FromHex("#0099BC");
        public static readonly System.Drawing.Color StatusNeutral   = FromHex("#68686E");

        // Risk badges
        public static readonly System.Drawing.Color RiskSafe        = FromHex("#3CBE5A");
        public static readonly System.Drawing.Color RiskModerate    = FromHex("#E6BE3C");
        public static readonly System.Drawing.Color RiskRisky       = FromHex("#DC4646");

        private static System.Drawing.Color FromHex(string hex)
            => System.Drawing.ColorTranslator.FromHtml(hex);
    }

    // ============================================================
    // SPACING SCALE (4px base)
    // ============================================================
    public static class Space
    {
        public const int XS  = 4;   // 4px
        public const int SM  = 8;   // 8px
        public const int MD  = 12;  // 12px
        public const int LG  = 16;  // 16px
        public const int XL  = 20;  // 20px
        public const int XXL = 24;  // 24px
        public const int XXXL = 32; // 32px
        public const int XXXXL = 40; // 40px
        public const int XXXXXL = 48; // 48px
    }

    // ============================================================
    // BORDER RADIUS
    // ============================================================
    public static class Radius
    {
        public const int None  = 0;
        public const int XS    = 4;   // 4px
        public const int SM    = 6;   // 6px
        public const int MD    = 8;   // 8px
        public const int LG    = 12;  // 12px
        public const int XL    = 16;  // 16px
        public const int Full  = 9999; // Pill
    }

    // ============================================================
    // TYPOGRAPHY
    // ============================================================
    public static class Font
    {
        public const string Family = "Segoe UI";

        public static readonly (float Size, FontStyle Style, int LineHeight) XS   = (11f, FontStyle.Regular, 16);
        public static readonly (float Size, FontStyle Style, int LineHeight) SM   = (12f, FontStyle.Regular, 18);
        public static readonly (float Size, FontStyle Style, int LineHeight) MD   = (13f, FontStyle.Regular, 20);
        public static readonly (float Size, FontStyle Style, int LineHeight) LG   = (14f, FontStyle.Regular, 22);
        public static readonly (float Size, FontStyle Style, int LineHeight) XL   = (16f, FontStyle.Regular, 24);
        public static readonly (float Size, FontStyle Style, int LineHeight) XXL  = (20f, FontStyle.Bold, 28);
        public static readonly (float Size, FontStyle Style, int LineHeight) XXXL = (24f, FontStyle.Bold, 32);
        public static readonly (float Size, FontStyle Style, int LineHeight) Display = (32f, FontStyle.Regular, 40);

        public static System.Drawing.Font Create(in (float Size, FontStyle Style, int LineHeight) t)
            => new System.Drawing.Font(Family, t.Size, t.Style, System.Drawing.GraphicsUnit.Pixel);
    }

    // ============================================================
    // SHADOWS (simulated via layered borders in WinForms)
    // ============================================================
    public static class Shadow
    {
        // WinForms não tem sombra nativa — usamos bordas em camadas
        public static readonly System.Drawing.Color Shadow1 = System.Drawing.Color.FromArgb(20, 0, 0, 0);   // sutil
        public static readonly System.Drawing.Color Shadow2 = System.Drawing.Color.FromArgb(40, 0, 0, 0);   // média
        public static readonly System.Drawing.Color Shadow3 = System.Drawing.Color.FromArgb(60, 0, 0, 0);   // forte
    }

    // ============================================================
    // ANIMATION
    // ============================================================
    public static class Motion
    {
        public const int Fast       = 100; // ms
        public const int Normal     = 150; // ms
        public const int Slow       = 250; // ms
        public const int Easing     = 2;   // 0=linear, 1=ease-in, 2=ease-out, 3=ease-in-out
    }

    // ============================================================
    // Z-INDEX (layer order)
    // ============================================================
    public static class ZIndex
    {
        public const int Base      = 0;
        public const int Dropdown  = 100;
        public const int Sticky    = 200;
        public const int Modal     = 1000;
        public const int Toast     = 1100;
        public const int Tooltip   = 1200;
    }

    // ============================================================
    // ICON SIZES
    // ============================================================
    public static class IconSize
    {
        public const int XS  = 12;
        public const int SM  = 16;
        public const int MD  = 20;
        public const int LG  = 24;
        public const int XL  = 28;
        public const int XXL = 32;
        public const int XXXL = 40;
    }

    // ============================================================
    // COMPONENT DEFAULTS
    // ============================================================
    public static class Component
    {
        // Button
        public static readonly Padding ButtonPadding = new Padding(Space.LG, Space.SM, Space.LG, Space.SM);
        public static readonly Size ButtonMinSize = new Size(80, 36);

        // Card
        public static readonly Padding CardPadding = new Padding(Space.LG);
        public static readonly Size CardDefaultSize = new Size(260, 96);

        // Input
        public static readonly Padding InputPadding = new Padding(Space.MD, Space.SM, Space.MD, Space.SM);
        public static readonly Size InputHeight = new Size(0, 40);

        // Modal
        public static readonly Size ModalDefault = new Size(480, 440);
        public static readonly Size ModalMin = new Size(400, 320);
        public static readonly Padding ModalPadding = new Padding(Space.XXL);
    }

    // ============================================================
    // HELPERS
    // ============================================================
    public static class Helpers
    {
        /// <summary>Converte hex string para Color (ex: "#0067C0" ou "0067C0")</summary>
        public static System.Drawing.Color Hex(string hex)
        {
            if (!hex.StartsWith("#")) hex = "#" + hex;
            return System.Drawing.ColorTranslator.FromHtml(hex);
        }

        /// <summary>Clareia uma cor (0.0 a 1.0)</summary>
        public static System.Drawing.Color Lighten(System.Drawing.Color c, float amount)
        {
            float r = c.R / 255f;
            float g = c.G / 255f;
            float b = c.B / 255f;
            r = Math.Min(1f, r + amount);
            g = Math.Min(1f, g + amount);
            b = Math.Min(1f, b + amount);
            return System.Drawing.Color.FromArgb(c.A, (int)(r * 255), (int)(g * 255), (int)(b * 255));
        }

        /// <summary>Escurece uma cor (0.0 a 1.0)</summary>
        public static System.Drawing.Color Darken(System.Drawing.Color c, float amount)
        {
            float r = c.R / 255f;
            float g = c.G / 255f;
            float b = c.B / 255f;
            r = Math.Max(0f, r - amount);
            g = Math.Max(0f, g - amount);
            b = Math.Max(0f, b - amount);
            return System.Drawing.Color.FromArgb(c.A, (int)(r * 255), (int)(g * 255), (int)(b * 255));
        }

        /// <summary>Muda opacidade (0-255)</summary>
        public static System.Drawing.Color WithAlpha(System.Drawing.Color c, int alpha)
            => System.Drawing.Color.FromArgb(Math.Clamp(alpha, 0, 255), c.R, c.G, c.B);

        /// <summary>Contraste relativo (WCAG)</summary>
        public static double ContrastRatio(System.Drawing.Color fg, System.Drawing.Color bg)
        {
            double L1 = Luminance(fg);
            double L2 = Luminance(bg);
            return (Math.Max(L1, L2) + 0.05) / (Math.Min(L1, L2) + 0.05);
        }

        private static double Luminance(System.Drawing.Color c)
        {
            double R = c.R / 255.0;
            double G = c.G / 255.0;
            double B = c.B / 255.0;
            R = R <= 0.03928 ? R / 12.92 : Math.Pow((R + 0.055) / 1.055, 2.4);
            G = G <= 0.03928 ? G / 12.92 : Math.Pow((G + 0.055) / 1.055, 2.4);
            B = B <= 0.03928 ? B / 12.92 : Math.Pow((B + 0.055) / 1.055, 2.4);
            return 0.2126 * R + 0.7152 * G + 0.0722 * B;
        }

        /// <summary>Retorna preto ou branco para melhor contraste sobre o background</summary>
        public static System.Drawing.Color ContrastText(System.Drawing.Color bg)
            => ContrastRatio(System.Drawing.Color.White, bg) >= ContrastRatio(System.Drawing.Color.Black, bg) ? System.Drawing.Color.White : System.Drawing.Color.Black;
    }
}