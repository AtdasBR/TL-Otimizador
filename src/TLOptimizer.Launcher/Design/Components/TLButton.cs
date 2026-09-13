using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Botão estilizado — Primary, Secondary, Ghost, Danger, Outline.
/// Suporta ícone (Fluent UI), loading state, tamanho responsivo.
/// </summary>
public enum TLButtonVariant
{
    Primary,
    Secondary,
    Ghost,
    Danger,
    Outline
}

public enum TLButtonSize
{
    Small,
    Medium,
    Large
}

public class TLButton : Button
{
    private TLButtonVariant _variant = TLButtonVariant.Primary;
    private TLButtonSize _size = TLButtonSize.Medium;
    private Symbol? _icon;
    private IconService.IconWeight _iconWeight = IconService.IconWeight.Regular;
    private bool _loading;
    private string? _originalText;
    private Timer? _loadingTimer;
    private int _loadingFrame;

    public TLButton()
    {
        FlatStyle = FlatStyle.Flat;
        FlatAppearance.BorderSize = 0;
        Font = Tokens.Font.Create(Tokens.Font.MD);
        ForeColor = Tokens.Color.TextPrimary;
        BackColor = Tokens.Color.AccentPrimary;
        Cursor = Cursors.Hand;
        AutoSize = false;
        Size = new Size(120, 40);
        MinimumSize = new Size(80, 36);
        Padding = new Padding(Tokens.Space.LG, Tokens.Space.SM, Tokens.Space.LG, Tokens.Space.SM);
        TextAlign = ContentAlignment.MiddleCenter;
        ImageAlign = ContentAlignment.MiddleLeft;
        TextImageRelation = TextImageRelation.ImageBeforeText;

        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        ApplyVariant();

        MouseEnter += (_, _) => { if (!Enabled || _loading) return; Invalidate(); };
        MouseLeave += (_, _) => { if (!Enabled || _loading) return; Invalidate(); };
        MouseDown += (_, _) => { if (!Enabled || _loading) return; Invalidate(); };
        MouseUp += (_, _) => { if (!Enabled || _loading) return; Invalidate(); };
    }

    [Category("TL Design"), DefaultValue(TLButtonVariant.Primary)]
    public TLButtonVariant Variant
    {
        get => _variant;
        set { _variant = value; ApplyVariant(); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(TLButtonSize.Medium)]
    public TLButtonSize ButtonSize
    {
        get => _size;
        set { _size = value; UpdateSize(); Invalidate(); }
    }

    [Category("TL Design")]
    public Symbol? Icon
    {
        get => _icon;
        set { _icon = value; UpdateIcon(); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(IconService.IconWeight.Regular)]
    public IconService.IconWeight IconWeight
    {
        get => _iconWeight;
        set { _iconWeight = value; UpdateIcon(); Invalidate(); }
    }

    [Browsable(false)]
    public bool Loading
    {
        get => _loading;
        set
        {
            if (_loading == value) return;
            _loading = value;
            if (value) StartLoading();
            else StopLoading();
        }
    }

    public void SetLoading(bool loading) => Loading = loading;

    private void ApplyVariant()
    {
        switch (_variant)
        {
            case TLButtonVariant.Primary:
                BackColor = Tokens.Color.AccentPrimary;
                ForeColor = Tokens.Color.TextOnAccent;
                FlatAppearance.BorderSize = 0;
                break;
            case TLButtonVariant.Secondary:
                BackColor = Tokens.Color.BgCard;
                ForeColor = Tokens.Color.TextPrimary;
                FlatAppearance.BorderSize = 1;
                FlatAppearance.BorderColor = Tokens.Color.BorderDefault;
                break;
            case TLButtonVariant.Ghost:
                BackColor = Color.Transparent;
                ForeColor = Tokens.Color.TextSecondary;
                FlatAppearance.BorderSize = 0;
                break;
            case TLButtonVariant.Danger:
                BackColor = Tokens.Color.AccentDanger;
                ForeColor = Tokens.Color.TextOnAccent;
                FlatAppearance.BorderSize = 0;
                break;
            case TLButtonVariant.Outline:
                BackColor = Color.Transparent;
                ForeColor = Tokens.Color.AccentPrimary;
                FlatAppearance.BorderSize = 1;
                FlatAppearance.BorderColor = Tokens.Color.AccentPrimary;
                break;
        }
    }

    private void UpdateSize()
    {
        var (hPad, vPad, height, font) = _size switch
        {
            TLButtonSize.Small => (Tokens.Space.MD, Tokens.Space.XS, 32, Tokens.Font.Create(Tokens.Font.SM)),
            TLButtonSize.Large => (Tokens.Space.XL, Tokens.Space.MD, 48, Tokens.Font.Create(Tokens.Font.LG)),
            _ => (Tokens.Space.LG, Tokens.Space.SM, 40, Tokens.Font.Create(Tokens.Font.MD))
        };
        Padding = new Padding(hPad, vPad, hPad, vPad);
        MinimumSize = new Size(72, height);
        Height = height;
        Font = font;
    }

    private void UpdateIcon()
    {
        if (_icon.HasValue)
        {
            var iconSize = _size == TLButtonSize.Small ? 16 : (_size == TLButtonSize.Large ? 24 : 20);
            Image = IconService.GetImage(_icon.Value, iconSize, _iconWeight, ForeColor);
            TextImageRelation = TextImageRelation.ImageBeforeText;
        }
        else
        {
            Image = null;
        }
    }

    private void StartLoading()
    {
        _originalText = Text;
        Text = "";
        Enabled = false;
        _loadingFrame = 0;
        _loadingTimer = new Timer { Interval = 80 };
        _loadingTimer.Tick += (_, _) => { _loadingFrame = (_loadingFrame + 1) % 12; Invalidate(); };
        _loadingTimer.Start();
    }

    private void StopLoading()
    {
        _loadingTimer?.Stop();
        _loadingTimer?.Dispose();
        _loadingTimer = null;
        Text = _originalText ?? "";
        Enabled = true;
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = ClientRectangle;
        var radius = Tokens.Radius.MD;

        // Background
        Color bgColor = BackColor;
        if (!Enabled && !_loading)
            bgColor = ControlPaint.Light(bgColor, 0.3f);
        else if (_loading)
            bgColor = ControlPaint.Dark(bgColor, 0.1f);
        else if (ClientRectangle.Contains(PointToClient(MousePosition)))
        {
            if (Capture) bgColor = ControlPaint.Dark(bgColor, 0.15f);
            else bgColor = ControlPaint.Light(bgColor, 0.1f);
        }

        using var path = GraphicsExtensions.RoundedRect(bounds, radius);
        g.SetClip(path);
        using (var brush = new SolidBrush(bgColor))
            g.FillPath(brush, path);
        g.ResetClip();

        // Border
        if (FlatAppearance.BorderSize > 0)
        {
            using var pen = new Pen(FlatAppearance.BorderColor, FlatAppearance.BorderSize)
            { Alignment = PenAlignment.Inset };
            g.DrawPath(pen, path);
        }

        // Loading spinner
        if (_loading)
        {
            DrawLoadingSpinner(g, bounds, radius);
            return;
        }

        // Icon + Text
        if (Image != null)
        {
            var imgRect = new Rectangle(
                (bounds.Width - Image.Width) / 2 - (string.IsNullOrEmpty(Text) ? 0 : 8),
                (bounds.Height - Image.Height) / 2,
                Image.Width, Image.Height);
            g.DrawImage(Image, imgRect);
        }

        if (!string.IsNullOrEmpty(Text))
        {
            var textBounds = bounds;
            if (Image != null) textBounds.X += Image.Width + 8;
            TextRenderer.DrawText(g, Text, Font, textBounds, ForeColor,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter |
                TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
        }
    }

    private void DrawLoadingSpinner(Graphics g, Rectangle bounds, int radius)
    {
        var center = new Point(bounds.Width / 2, bounds.Height / 2);
        var spinnerRadius = Math.Min(bounds.Width, bounds.Height) / 4;
        var penWidth = 3f;

        using var pen = new Pen(ForeColor, penWidth)
        { StartCap = LineCap.Round, EndCap = LineCap.Round };

        for (int i = 0; i < 12; i++)
        {
            float angle = (i * 30f + _loadingFrame * 30f) % 360f;
            float alpha = 1f - i / 12f;
            using var framePen = new Pen(Color.FromArgb((int)(alpha * 255), ForeColor), penWidth)
            { StartCap = LineCap.Round, EndCap = LineCap.Round };

            var rad = angle * MathF.PI / 180f;
            var x1 = center.X + (spinnerRadius - penWidth) * MathF.Cos(rad);
            var y1 = center.Y + (spinnerRadius - penWidth) * MathF.Sin(rad);
            var x2 = center.X + spinnerRadius * MathF.Cos(rad);
            var y2 = center.Y + spinnerRadius * MathF.Sin(rad);

            g.DrawLine(framePen, x1, y1, x2, y2);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _loadingTimer?.Stop();
            _loadingTimer?.Dispose();
        }
        base.Dispose(disposing);
    }
}