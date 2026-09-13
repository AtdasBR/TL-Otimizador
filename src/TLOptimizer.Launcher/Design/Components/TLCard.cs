using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Card estilizado — Default, Elevated, Outlined.
/// Suporta hover lift, click action, padding interno, elevação configurável.
/// </summary>
public enum TLCardVariant
{
    Default,
    Elevated,
    Outlined
}

public class TLCard : Panel
{
    private TLCardVariant _variant = TLCardVariant.Default;
    private int _elevation = 1;
    private int _radius = Tokens.Radius.LG;
    private bool _hoverLift = true;
    private int _liftPixels = 2;
    private Point _originalLocation;
    private bool _selected;
    private Color? _selectedBorderColor;

    public TLCard()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        BackColor = Tokens.Color.BgCard;
        Padding = Tokens.Component.CardPadding;
        Margin = new Padding(0, 0, Tokens.Space.LG, Tokens.Space.LG);
        Cursor = Cursors.Hand;
        MinimumSize = new Size(200, 80);

        _originalLocation = Location;

        MouseEnter += (_, _) =>
        {
            if (!_hoverLift || !Enabled) return;
            Location = new Point(_originalLocation.X, _originalLocation.Y - _liftPixels);
            Invalidate();
        };
        MouseLeave += (_, _) =>
        {
            if (!_hoverLift || !Enabled) return;
            Location = _originalLocation;
            Invalidate();
        };
        MouseDown += (_, _) => { if (Enabled) Invalidate(); };
        MouseUp += (_, _) => { if (Enabled) Invalidate(); };
    }

    [Category("TL Design"), DefaultValue(TLCardVariant.Default)]
    public TLCardVariant Variant
    {
        get => _variant;
        set { _variant = value; Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(1)]
    public int Elevation
    {
        get => _elevation;
        set { _elevation = Math.Clamp(value, 0, 3); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(Tokens.Radius.LG)]
    public int Radius
    {
        get => _radius;
        set { _radius = Math.Max(0, value); Invalidate(); }
    }

    [Category("TL Design"), DefaultValue(true)]
    public bool HoverLift
    {
        get => _hoverLift;
        set => _hoverLift = value;
    }

    [Category("TL Design"), DefaultValue(2)]
    public int LiftPixels
    {
        get => _liftPixels;
        set => _liftPixels = Math.Max(0, value);
    }

    [Category("TL Design"), DefaultValue(false)]
    public bool Selected
    {
        get => _selected;
        set { _selected = value; _selectedBorderColor = value ? Tokens.Color.AccentPrimary : null; Invalidate(); }
    }

    [Category("TL Design")]
    public Color? SelectedBorderColor
    {
        get => _selectedBorderColor;
        set { _selectedBorderColor = value; Invalidate(); }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = new Rectangle(0, 0, Width - 1, Height - 1);

        // Sombra/elevation
        g.DrawElevation(bounds, _radius, _elevation);

        // Background
        using var path = GraphicsExtensions.RoundedRect(bounds, _radius);
        g.SetClip(path);
        using (var brush = new SolidBrush(BackColor))
            g.FillPath(brush, path);
        g.ResetClip();

        // Top glass highlight (apenas elevated/default)
        if (_variant != TLCardVariant.Outlined)
            g.FillCardTopGlass(bounds, _radius);

        // Border
        Color borderColor;
        float borderWidth = 1f;

        if (_selected && _selectedBorderColor.HasValue)
        {
            borderColor = _selectedBorderColor.Value;
            borderWidth = 2f;
        }
        else if (_variant == TLCardVariant.Outlined)
        {
            borderColor = Enabled ? Tokens.Color.BorderDefault : Tokens.Color.BorderSubtle;
        }
        else if (ClientRectangle.Contains(PointToClient(MousePosition)) && Enabled)
        {
            borderColor = Tokens.Color.BorderFocus;
        }
        else
        {
            borderColor = Tokens.Color.BorderSubtle;
        }

        if (_variant == TLCardVariant.Outlined || _selected || ClientRectangle.Contains(PointToClient(MousePosition)))
        {
            using var pen = new Pen(borderColor, borderWidth) { Alignment = PenAlignment.Inset };
            g.DrawPath(pen, path);
        }
    }

    protected override void OnLocationChanged(EventArgs e)
    {
        if (!_hoverLift || !MouseButtons.HasFlag(MouseButtons.Left))
            _originalLocation = Location;
        base.OnLocationChanged(e);
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        // Atualiza location original se não estiver em hover lift
        if (!_hoverLift || Location.Y == _originalLocation.Y)
            _originalLocation = Location;
    }
}