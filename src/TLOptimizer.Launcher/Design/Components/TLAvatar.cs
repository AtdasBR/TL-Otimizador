using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Avatar — logo PNG, fallback com inicial colorida, status badge opcional.
/// Tamanhos sm/md/lg/xl, borda opcional.
/// </summary>
public enum TLAvatarSize
{
    Small,
    Medium,
    Large,
    XLarge
}

public class TLAvatar : Control
{
    private Image? _image;
    private char _initial = '?';
    private string _seed = "";
    private TLAvatarSize _size = TLAvatarSize.Medium;
    private bool _hasBorder = false;
    private Color _borderColor = Tokens.Color.AccentPrimary;
    private float _borderWidth = 2f;
    private bool _statusBadge = false;
    private Color _statusColor = Tokens.Color.AccentSuccess;
    private TLAvatarSize _statusSize = TLAvatarSize.Small;

    public TLAvatar()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        TabStop = false;
        UpdateSize();
    }

    [Category("TL Design")]
    public Image? Image
    {
        get => _image;
        set { _image = value; Invalidate(); }
    }

    [Category("TL Design"), DefaultValue('?')]
    public char Initial
    {
        get => _initial;
        set { _initial = value; Invalidate(); }
    }

    [Category("TL Design")]
    public string Seed
    {
        get => _seed;
        set { _seed = value; Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(TLAvatarSize.Medium)]
    public TLAvatarSize AvatarSize
    {
        get => _size;
        set { _size = value; UpdateSize(); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(false)]
    public bool HasBorder
    {
        get => _hasBorder;
        set { _hasBorder = value; Invalidate(); }
    }

    [Category("TL Design")]
    public Color BorderColor
    {
        get => _borderColor;
        set { _borderColor = value; Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(2f)]
    public float BorderWidth
    {
        get => _borderWidth;
        set { _borderWidth = Math.Max(1f, value); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(false)]
    public bool StatusBadge
    {
        get => _statusBadge;
        set { _statusBadge = value; Invalidate(); }
    }

    [Category("TL Design")]
    public Color StatusColor
    {
        get => _statusColor;
        set { _statusColor = value; Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(TLAvatarSize.Small)]
    public TLAvatarSize StatusSize
    {
        get => _statusSize;
        set { _statusSize = value; Invalidate(); }
    }

    public void SetFromPackageId(string packageId, string? logoPath = null)
    {
        _seed = packageId;
        _initial = packageId.Length > 0 ? char.ToUpper(packageId[0]) : '?';

        if (!string.IsNullOrEmpty(logoPath) && File.Exists(logoPath))
        {
            try
            {
                _image = System.Drawing.Image.FromFile(logoPath);
            }
            catch { _image = null; }
        }
        else
        {
            _image = null;
        }
        Invalidate();
    }

    private void UpdateSize()
    {
        var (d, fontSize) = _size switch
        {
            TLAvatarSize.Small => (28, 10f),
            TLAvatarSize.Large => (56, 22f),
            TLAvatarSize.XLarge => (80, 32f),
            _ => (40, 16f)
        };
        Size = new Size(d, d);
        Font = new Font(Tokens.Font.Family, fontSize, FontStyle.Bold, GraphicsUnit.Pixel);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        var bounds = ClientRectangle;
        var diameter = Math.Min(bounds.Width, bounds.Height);
        var rect = new Rectangle(
            (bounds.Width - diameter) / 2,
            (bounds.Height - diameter) / 2,
            diameter, diameter);

        // Background
        using (var path = GraphicsExtensions.RoundedRect(rect, diameter / 2))
        {
            if (_image != null)
            {
                g.SetClip(path);
                g.DrawImage(_image, rect);
                g.ResetClip();
            }
            else
            {
                // Cor baseada no hash do seed
                var hash = (_seed + _initial).GetHashCode();
                var hue = Math.Abs(hash % 360);
                var color = HsvToRgb(hue, 0.55f, 0.75f);
                var darkColor = HsvToRgb(hue, 0.65f, 0.55f);

                using var brush = new LinearGradientBrush(rect, color, darkColor, LinearGradientMode.ForwardDiagonal);
                g.FillPath(brush, path);
            }

            // Borda opcional
            if (_hasBorder)
            {
                using var pen = new Pen(_borderColor, _borderWidth) { Alignment = PenAlignment.Inset };
                g.DrawPath(pen, path);
            }

            // Inicial (se sem imagem)
            if (_image == null)
            {
                var text = _initial.ToString().ToUpper();
                var size = g.MeasureString(text, Font);
                g.DrawString(text, Font, new SolidBrush(Color.White),
                    (bounds.Width - size.Width) / 2f,
                    (bounds.Height - size.Height) / 2f);
            }
        }

        // Status badge
        if (_statusBadge)
        {
            var badgeDiameter = _statusSize switch
            {
                TLAvatarSize.Small => 10,
                TLAvatarSize.Medium => 14,
                TLAvatarSize.Large => 18,
                _ => 12
            };

            var badgeRect = new Rectangle(
                bounds.Right - badgeDiameter + 2,
                bounds.Bottom - badgeDiameter + 2,
                badgeDiameter, badgeDiameter);

            using (var path = GraphicsExtensions.RoundedRect(badgeRect, badgeDiameter / 2))
            {
                using var brush = new SolidBrush(_statusColor);
                g.FillPath(brush, path);

                // Anel branco ao redor
                using var pen = new Pen(Color.White, 2f);
                g.DrawPath(pen, path);
            }
        }
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
}