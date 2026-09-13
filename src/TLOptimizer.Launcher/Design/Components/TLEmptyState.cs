using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Estado vazio — ilustração SVG, título, descrição, botão de ação opcional.
/// </summary>
public class TLEmptyState : Panel
{
    private Image? _illustration;
    private string _title = "Nenhum resultado";
    private string _description = "Tente ajustar sua busca ou filtros.";
    private TLButton? _actionButton;

    public TLEmptyState()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        BackColor = Color.Transparent;
        Dock = DockStyle.Fill;
        Padding = new Padding(Tokens.Space.XXXL);
    }

    [Category("TL Design")]
    public Image? Illustration
    {
        get => _illustration;
        set { _illustration = value; Invalidate(); }
    }

    [Category("TL Design")]
    public string Title
    {
        get => _title;
        set { _title = value; Invalidate(); }
    }

    [Category("TL Design")]
    public string Description
    {
        get => _description;
        set { _description = value; Invalidate(); }
    }

    [Category("TL Design")]
    public TLButton? ActionButton
    {
        get => _actionButton;
        set
        {
            if (_actionButton != null)
                Controls.Remove(_actionButton);

            _actionButton = value;
            if (_actionButton != null)
            {
                _actionButton.Variant = TLButtonVariant.Primary;
                _actionButton.ButtonSize = TLButtonSize.Medium;
                Controls.Add(_actionButton);
            }
            Invalidate();
        }
    }

    public void SetIllustrationFromSymbol(Symbol symbol, int size = 80, Color? color = null)
    {
        _illustration = IconService.GetImage(symbol, size, IconService.IconWeight.Regular, color ?? Tokens.Color.TextMuted);
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        var bounds = ClientRectangle;
        var contentWidth = Math.Min(bounds.Width - Padding.Left - Padding.Right, 400);

        // Calcula layout
        int y = Padding.Top;
        int centerX = bounds.Width / 2;

        // Ilustração
        if (_illustration != null)
        {
            int illuSize = Math.Min(_illustration.Width, contentWidth);
            int illuX = centerX - illuSize / 2;
            g.DrawImage(_illustration, illuX, y, illuSize, illuSize);
            y += illuSize + Tokens.Space.XXL;
        }

        // Título
        using (var titleFont = Tokens.Font.Create(Tokens.Font.XXL))
        {
            var titleSize = g.MeasureString(_title, titleFont, contentWidth);
            int titleX = centerX - (int)(titleSize.Width / 2);
            g.DrawString(_title, titleFont, new SolidBrush(Tokens.Color.TextPrimary), titleX, y);
            y += (int)titleSize.Height + Tokens.Space.MD;
        }

        // Descrição
        using (var descFont = Tokens.Font.Create(Tokens.Font.MD))
        {
            var descSize = g.MeasureString(_description, descFont, contentWidth);
            int descX = centerX - (int)(descSize.Width / 2);
            g.DrawString(_description, descFont, new SolidBrush(Tokens.Color.TextSecondary), descX, y);
            y += (int)descSize.Height + Tokens.Space.XXL;
        }

        // Botão de ação
        if (_actionButton != null)
        {
            _actionButton.Size = new Size(
                Math.Min(_actionButton.PreferredSize.Width + Tokens.Space.XXL, contentWidth / 2),
                _actionButton.Height);
            _actionButton.Location = new Point(centerX - _actionButton.Width / 2, y);
            _actionButton.Visible = true;
        }
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        Invalidate();
    }
}