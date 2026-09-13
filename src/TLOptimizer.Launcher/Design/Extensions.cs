using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

namespace TLOptimizer.Launcher.Design;

/// <summary>
/// Graphics extensions e helpers para renderização consistente.
/// </summary>
public static class GraphicsExtensions
{
    // ============================================================
    // ROUNDED RECTANGLES
    // ============================================================

    /// <summary>Cria GraphicsPath com cantos arredondados.</summary>
    public static GraphicsPath RoundedRect(Rectangle bounds, int radius)
    {
        var path = new GraphicsPath();
        int d = radius * 2;
        if (d > bounds.Width) d = bounds.Width;
        if (d > bounds.Height) d = bounds.Height;

        path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
        path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
        path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    /// <summary>Cria GraphicsPath com cantos arredondados individuais.</summary>
    public static GraphicsPath RoundedRect(Rectangle bounds, int tl, int tr, int br, int bl)
    {
        var path = new GraphicsPath();
        int d;

        // Top-left
        d = tl * 2; if (d > bounds.Width) d = bounds.Width; if (d > bounds.Height) d = bounds.Height;
        path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);

        // Top-right
        d = tr * 2; if (d > bounds.Width) d = bounds.Width; if (d > bounds.Height) d = bounds.Height;
        path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);

        // Bottom-right
        d = br * 2; if (d > bounds.Width) d = bounds.Width; if (d > bounds.Height) d = bounds.Height;
        path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);

        // Bottom-left
        d = bl * 2; if (d > bounds.Width) d = bounds.Width; if (d > bounds.Height) d = bounds.Height;
        path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);

        path.CloseFigure();
        return path;
    }

    // ============================================================
    // SHADOWS (simulated via layered drawing)
    // ============================================================

    /// <summary>Desenha sombra simulada atrás de um retângulo arredondado.</summary>
    public static void DrawShadow(this Graphics g, Rectangle bounds, int radius, Color shadowColor, int offset = 2, int blur = 4)
    {
        using var shadowPath = RoundedRect(
            new Rectangle(bounds.X + offset, bounds.Y + offset, bounds.Width, bounds.Height),
            radius);

        // Simula blur desenhando múltiplas camadas com opacidade decrescente
        for (int i = blur; i > 0; i--)
        {
            int alpha = (int)(shadowColor.A * (1.0 - i / (float)(blur + 1)) * 0.3);
            if (alpha < 5) continue;

            using var pen = new Pen(Color.FromArgb(alpha, shadowColor), i * 2);
            pen.Alignment = PenAlignment.Inset;
            g.DrawPath(pen, shadowPath);
        }
    }

    /// <summary>Desenha elevação (elevation) com múltiplas sombras.</summary>
    public static void DrawElevation(this Graphics g, Rectangle bounds, int radius, int elevation)
    {
        // Elevation 1: sombra sutil
        if (elevation >= 1)
            DrawShadow(g, bounds, radius, Tokens.Shadow.Shadow1, 1, 2);

        // Elevation 2: sombra média
        if (elevation >= 2)
            DrawShadow(g, bounds, radius, Tokens.Shadow.Shadow2, 3, 4);

        // Elevation 3: sombra forte
        if (elevation >= 3)
            DrawShadow(g, bounds, radius, Tokens.Shadow.Shadow3, 6, 8);
    }

    // ============================================================
    // GRADIENTS
    // ============================================================

    /// <summary>Preenche com gradiente linear vertical.</summary>
    public static void FillLinearVertical(this Graphics g, Rectangle bounds, Color start, Color end)
    {
        using var brush = new LinearGradientBrush(bounds, start, end, LinearGradientMode.Vertical);
        g.FillRectangle(brush, bounds);
    }

    /// <summary>Preenche com gradiente linear horizontal.</summary>
    public static void FillLinearHorizontal(this Graphics g, Rectangle bounds, Color start, Color end)
    {
        using var brush = new LinearGradientBrush(bounds, start, end, LinearGradientMode.Horizontal);
        g.FillRectangle(brush, bounds);
    }

    /// <summary>Preenche topo do card com gradiente sutil (glass effect).</summary>
    public static void FillCardTopGlass(this Graphics g, Rectangle bounds, int radius, int height = 12)
    {
        var glassRect = new Rectangle(bounds.X, bounds.Y, bounds.Width, height);
        using var path = RoundedRect(glassRect, radius);
        using var brush = new LinearGradientBrush(glassRect,
            Color.FromArgb(40, 255, 255, 255),
            Color.FromArgb(0, 255, 255, 255),
            LinearGradientMode.Vertical);
        g.FillPath(brush, path);
    }

    // ============================================================
    // BORDERS & STROKES
    // ============================================================

    /// <summary>Desenha borda arredondada.</summary>
    public static void DrawRoundedBorder(this Graphics g, Rectangle bounds, int radius, Color color, float width = 1f)
    {
        using var path = RoundedRect(new Rectangle(
            bounds.X + (int)(width / 2),
            bounds.Y + (int)(width / 2),
            bounds.Width - (int)width,
            bounds.Height - (int)width), radius);

        using var pen = new Pen(color, width) { Alignment = PenAlignment.Center };
        g.DrawPath(pen, path);
    }

    /// <summary>Desenha borda com cantos individuais.</summary>
    public static void DrawRoundedBorder(this Graphics g, Rectangle bounds, int tl, int tr, int br, int bl, Color color, float width = 1f)
    {
        using var path = RoundedRect(
            new Rectangle(bounds.X + (int)(width / 2), bounds.Y + (int)(width / 2),
                bounds.Width - (int)width, bounds.Height - (int)width),
            tl, tr, br, bl);

        using var pen = new Pen(color, width) { Alignment = PenAlignment.Center };
        g.DrawPath(pen, path);
    }

    // ============================================================
    // TEXT RENDERING
    // ============================================================

    /// <summary>Desenha texto com ellipsis automático.</summary>
    public static void DrawTextEllipsis(this Graphics g, string text, Font font, Color color, Rectangle bounds,
        StringFormat? format = null)
    {
        format ??= new StringFormat
        {
            Trimming = StringTrimming.EllipsisCharacter,
            FormatFlags = StringFormatFlags.NoWrap,
            Alignment = StringAlignment.Near,
            LineAlignment = StringAlignment.Center
        };

        using var brush = new SolidBrush(color);
        g.DrawString(text, font, brush, bounds, format);
    }

    /// <summary>Mede texto com limite de largura.</summary>
    public static SizeF MeasureText(this Graphics g, string text, Font font, int maxWidth)
    {
        var format = new StringFormat { FormatFlags = StringFormatFlags.NoWrap };
        return g.MeasureString(text, font, maxWidth, format);
    }

    // ============================================================
    // IMAGE HELPERS
    // ============================================================

    /// <summary>Redimensiona imagem mantendo aspect ratio (high quality).</summary>
    public static Image ResizeImage(Image source, int maxWidth, int maxHeight)
    {
        var ratio = Math.Min((float)maxWidth / source.Width, (float)maxHeight / source.Height);
        int newW = (int)(source.Width * ratio);
        int newH = (int)(source.Height * ratio);

        var dest = new Bitmap(newW, newH);
        dest.SetResolution(source.HorizontalResolution, source.VerticalResolution);

        using var g = Graphics.FromImage(dest);
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.SmoothingMode = SmoothingMode.HighQuality;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.DrawImage(source, 0, 0, newW, newH);

        return dest;
    }

    /// <summary>Cria bitmap circular a partir de imagem (para avatars).</summary>
    public static Bitmap CreateCircularImage(Image source, int diameter)
    {
        var resized = ResizeImage(source, diameter, diameter);
        var bmp = new Bitmap(diameter, diameter);
        bmp.SetResolution(resized.HorizontalResolution, resized.VerticalResolution);

        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;

        using var path = RoundedRect(new Rectangle(0, 0, diameter, diameter), diameter / 2);
        g.SetClip(path);
        g.DrawImage(resized, 0, 0, diameter, diameter);
        g.ResetClip();

        // Borda sutil
        using var pen = new Pen(Tokens.Color.BorderSubtle, 1);
        g.DrawEllipse(pen, 0.5f, 0.5f, diameter - 1, diameter - 1);

        return bmp;
    }

    /// <summary>Gera avatar com inicial colorida (fallback quando não há logo).</summary>
    public static Bitmap GenerateInitialAvatar(char initial, int diameter, string seed = "")
    {
        var bmp = new Bitmap(diameter, diameter);
        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        // Cor baseada no hash do seed/nome
        var hash = (seed + initial).GetHashCode();
        var hue = Math.Abs(hash % 360);
        var color = HsvToRgb(hue, 0.55f, 0.75f);
        var darkColor = HsvToRgb(hue, 0.65f, 0.55f);

        // Background gradient
        using var brush = new LinearGradientBrush(new Rectangle(0, 0, diameter, diameter),
            color, darkColor, LinearGradientMode.ForwardDiagonal);
        g.FillEllipse(brush, 0, 0, diameter, diameter);

        // Inicial
        var fontSize = diameter * 0.42f;
        using var font = new Font(Tokens.Font.Family, fontSize, FontStyle.Bold, GraphicsUnit.Pixel);
        using var textBrush = new SolidBrush(Color.White);
        var text = initial.ToString().ToUpper();
        var size = g.MeasureString(text, font);
        g.DrawString(text, font, textBrush,
            (diameter - size.Width) / 2f,
            (diameter - size.Height) / 2f);

        return bmp;
    }

    private static Color HsvToRgb(double h, double s, double v)
    {
        int hi = (int)(h / 60) % 6;
        double f = h / 60 - hi;
        double p = v * (1 - s);
        double q = v * (1 - f * s);
        double t = v * (1 - (1 - f) * s);

        double r, g, b;
        switch (hi)
        {
            case 0: r = v; g = t; b = p; break;
            case 1: r = q; g = v; b = p; break;
            case 2: r = p; g = v; b = t; break;
            case 3: r = p; g = q; b = v; break;
            case 4: r = t; g = p; b = v; break;
            default: r = v; g = p; b = q; break;
        }
        return Color.FromArgb((int)(r * 255), (int)(g * 255), (int)(b * 255));
    }

    // ============================================================
    // CONTROL EXTENSIONS
    // ============================================================

    /// <summary>Habilita DoubleBuffered via reflection (para FlowLayoutPanel, etc).</summary>
    public static void EnableDoubleBuffer(this Control control)
    {
        typeof(Control).GetProperty("DoubleBuffered",
            System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)?
            .SetValue(control, true);
    }

    /// <summary>Aplica estilo de card padrão a um Painel.</summary>
    public static void ApplyCardStyle(this Panel panel, int elevation = 1, int? radius = null)
    {
        panel.BackColor = Tokens.Color.BgCard;
        panel.Padding = Tokens.Component.CardPadding;
        radius ??= Tokens.Radius.LG;

        panel.Paint -= Panel_Paint_Card; // evita duplicar
        panel.Paint += Panel_Paint_Card;

        void Panel_Paint_Card(object? s, PaintEventArgs e)
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            var bounds = new Rectangle(0, 0, panel.Width - 1, panel.Height - 1);
            var r = radius.Value;

            // Sombra/elevation
            g.DrawElevation(bounds, r, elevation);

            // Card background
            using var path = RoundedRect(bounds, r);
            g.SetClip(path);
            using var bg = new SolidBrush(panel.BackColor);
            g.FillPath(bg, path);
            g.ResetClip();

            // Top glass highlight
            g.FillCardTopGlass(bounds, r);

            // Borda
            g.DrawRoundedBorder(bounds, r, Tokens.Color.BorderSubtle, 1f);
        }

        panel.EnableDoubleBuffer();
    }

    /// <summary>Aplica hover lift a um controle.</summary>
    public static void AddHoverLift(this Control control, int liftPixels = 2, Color? hoverBackColor = null)
    {
        var originalLocation = control.Location;
        var originalBackColor = control.BackColor;
        var targetBackColor = hoverBackColor ?? Tokens.Color.BgHover;

        control.MouseEnter += (_, _) =>
        {
            control.Location = new Point(originalLocation.X, originalLocation.Y - liftPixels);
            if (hoverBackColor.HasValue) control.BackColor = targetBackColor;
            control.Invalidate();
        };

        control.MouseLeave += (_, _) =>
        {
            control.Location = originalLocation;
            if (hoverBackColor.HasValue) control.BackColor = originalBackColor;
            control.Invalidate();
        };

        // Propaga para filhos
        foreach (Control child in control.Controls)
            child.AddHoverLift(liftPixels, hoverBackColor);
    }

    /// <summary>Adiciona indicação de foco acessível.</summary>
    public static void AddFocusRing(this Control control, Color? color = null)
    {
        var ringColor = color ?? Tokens.Color.BorderFocus;

        control.Paint += (_, e) =>
        {
            if (control.Focused)
            {
                var bounds = new Rectangle(0, 0, control.Width - 1, control.Height - 1);
                var r = Tokens.Radius.SM;
                using var path = RoundedRect(bounds, r);
                using var pen = new Pen(ringColor, 2f);
                e.Graphics.DrawPath(pen, path);
            }
        };

        control.GotFocus += (_, _) => control.Invalidate();
        control.LostFocus += (_, _) => control.Invalidate();
    }
}

// ============================================================
// INTERPOLATION HELPERS (para animações)
// ============================================================

public static class Interpolation
{
    public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp(t);
    public static int Lerp(int a, int b, float t) => (int)Math.Round(Lerp((float)a, (float)b, t));
    public static Color Lerp(Color a, Color b, float t)
    {
        t = Clamp(t);
        return Color.FromArgb(
            Lerp(a.A, b.A, t),
            Lerp(a.R, b.R, t),
            Lerp(a.G, b.G, t),
            Lerp(a.B, b.B, t));
    }

    public static Point Lerp(Point a, Point b, float t)
        => new Point(Lerp(a.X, b.X, t), Lerp(a.Y, b.Y, t));

    public static Rectangle Lerp(Rectangle a, Rectangle b, float t)
        => new Rectangle(Lerp(a.X, b.X, t), Lerp(a.Y, b.Y, t), Lerp(a.Width, b.Width, t), Lerp(a.Height, b.Height, t));

    public static float Clamp(float v, float min = 0f, float max = 1f) => Math.Max(min, Math.Min(max, v));

    // Easing functions
    public static float EaseOutCubic(float t) => 1 - MathF.Pow(1 - t, 3);
    public static float EaseInOutCubic(float t) => t < 0.5f ? 4 * t * t * t : 1 - MathF.Pow(-2 * t + 2, 3) / 2;
    public static float EaseOutExpo(float t) => t >= 1 ? 1 : 1 - MathF.Pow(2, -10 * t);
}