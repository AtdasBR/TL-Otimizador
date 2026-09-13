using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Badge estilizado — Risk (3 níveis), Status, Category.
/// Tamanhos sm/md/lg, pill ou rounded.
/// </summary>
public enum TLBadgeKind
{
    Risk,
    Status,
    Category
}

public enum TLBadgeSize
{
    Small,
    Medium,
    Large
}

public enum TLRiskLevel
{
    Safe,
    Moderate,
    Risky
}

public enum TLStatusKind
{
    Success,
    Warning,
    Danger,
    Info,
    Neutral
}

public class TLBadge : Label
{
    private TLBadgeKind _kind = TLBadgeKind.Category;
    private TLBadgeSize _size = TLBadgeSize.Medium;
    private TLRiskLevel _risk = TLRiskLevel.Safe;
    private TLStatusKind _status = TLStatusKind.Neutral;
    private string _category = "";

    public TLBadge()
    {
        AutoSize = false;
        TextAlign = ContentAlignment.MiddleCenter;
        Font = Tokens.Font.Create(Tokens.Font.XS);
        Padding = new Padding(Tokens.Space.SM, 0, Tokens.Space.SM, 0);
        MinimumSize = new Size(0, 20);
    }

    [Category("TL Design"), DefaultValue(TLBadgeKind.Category)]
    public TLBadgeKind Kind
    {
        get => _kind;
        set { _kind = value; UpdateAppearance(); }
    }

    [Category("TL Design"), DefaultValue(TLBadgeSize.Medium)]
    public TLBadgeSize BadgeSize
    {
        get => _size;
        set { _size = value; UpdateAppearance(); }
    }

    [Category("TL Design"), DefaultValue(TLRiskLevel.Safe)]
    public TLRiskLevel Risk
    {
        get => _risk;
        set { _risk = value; if (_kind == TLBadgeKind.Risk) UpdateAppearance(); }
    }

    [Category("TL Design"), DefaultValue(TLStatusKind.Neutral)]
    public TLStatusKind Status
    {
        get => _status;
        set { _status = value; if (_kind == TLBadgeKind.Status) UpdateAppearance(); }
    }

    [Category("TL Design")]
    public string Category
    {
        get => _category;
        set { _category = value; if (_kind == TLBadgeKind.Category) UpdateAppearance(); }
    }

    private void UpdateAppearance()
    {
        var (bg, fg, radius, font, hPad, vPad, minH) = _size switch
        {
            TLBadgeSize.Small => (Color.Empty, Color.Empty, Tokens.Radius.Full, Tokens.Font.Create(Tokens.Font.XS), Tokens.Space.XS, 0, 16),
            TLBadgeSize.Large => (Color.Empty, Color.Empty, Tokens.Radius.MD, Tokens.Font.Create(Tokens.Font.SM), Tokens.Space.MD, Tokens.Space.XS, 24),
            _ => (Color.Empty, Color.Empty, Tokens.Radius.Full, Tokens.Font.Create(Tokens.Font.XS), Tokens.Space.SM, 0, 20)
        };

        Font = font;
        Padding = new Padding(hPad, vPad, hPad, vPad);
        MinimumSize = new Size(0, minH);

        Color bgColor, fgColor;

        switch (_kind)
        {
            case TLBadgeKind.Risk:
                bgColor = _risk switch
                {
                    TLRiskLevel.Safe => Tokens.Color.RiskSafe,
                    TLRiskLevel.Moderate => Tokens.Color.RiskModerate,
                    _ => Tokens.Color.RiskRisky
                };
                fgColor = _risk == TLRiskLevel.Moderate ? Tokens.Color.TextOnWarning : Tokens.Color.TextOnAccent;
                Text = _risk.ToString().ToUpper();
                break;

            case TLBadgeKind.Status:
                bgColor = _status switch
                {
                    TLStatusKind.Success => Tokens.Color.AccentSuccess,
                    TLStatusKind.Warning => Tokens.Color.AccentWarning,
                    TLStatusKind.Danger => Tokens.Color.AccentDanger,
                    TLStatusKind.Info => Tokens.Color.AccentInfo,
                    _ => Tokens.Color.StatusNeutral
                };
                fgColor = _status == TLStatusKind.Warning ? Tokens.Color.TextOnWarning : Tokens.Color.TextOnAccent;
                Text = _status.ToString().ToUpper();
                break;

            case TLBadgeKind.Category:
            default:
                bgColor = Tokens.Color.BgHover;
                fgColor = Tokens.Color.TextSecondary;
                Text = _category.ToUpper();
                break;
        }

        BackColor = bgColor;
        ForeColor = fgColor;
        BorderStyle = BorderStyle.None;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        // Label já desenha texto centralizado com AutoSize=false
        base.OnPaint(e);

        // Desenha background arredondado
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = ClientRectangle;
        var radius = _size == TLBadgeSize.Large ? Tokens.Radius.MD : Tokens.Radius.Full;

        using var path = GraphicsExtensions.RoundedRect(bounds, radius);
        using var brush = new SolidBrush(BackColor);
        g.FillPath(brush, path);
    }
}