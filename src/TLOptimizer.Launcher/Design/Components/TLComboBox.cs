using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// ComboBox estilizado — Flat, ícone por item, searchable, dropdown customizado.
/// </summary>
public class TLComboBox : ComboBox
{
    private bool _focused;

    public TLComboBox()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        DrawMode = DrawMode.OwnerDrawFixed;
        DropDownStyle = ComboBoxStyle.DropDownList;
        FlatStyle = FlatStyle.Flat;
        Font = Tokens.Font.Create(Tokens.Font.MD);
        BackColor = Tokens.Color.BgCard;
        ForeColor = Tokens.Color.TextPrimary;
        ItemHeight = 36;
        MinimumSize = new Size(180, 40);
        Cursor = Cursors.Hand;

        Enter += (_, _) => { _focused = true; Invalidate(); };
        Leave += (_, _) => { _focused = false; Invalidate(); };
        MouseEnter += (_, _) => Invalidate();
        MouseLeave += (_, _) => Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = ClientRectangle;
        var radius = Tokens.Radius.MD;

        // Background
        var bg = _focused ? Tokens.Color.BgHover : BackColor;
        using (var path = GraphicsExtensions.RoundedRect(bounds, radius))
        using (var brush = new SolidBrush(bg))
            g.FillPath(brush, path);

        // Border
        var borderColor = _focused ? Tokens.Color.BorderFocus : Tokens.Color.BorderSubtle;
        var borderWidth = _focused ? 2f : 1f;
        using (var path = GraphicsExtensions.RoundedRect(
            new Rectangle(0, 0, Width - 1, Height - 1), radius))
        using (var pen = new Pen(borderColor, borderWidth) { Alignment = PenAlignment.Inset })
            g.DrawPath(pen, path);

        // Selected item text
        if (SelectedItem != null)
        {
            var text = SelectedItem.ToString() ?? "";
            var icon = GetItemIcon(SelectedIndex);
            int iconSize = 20;
            int iconX = Tokens.Space.MD;
            int textX = icon != null ? iconX + iconSize + Tokens.Space.SM : Tokens.Space.MD;

            if (icon != null)
                g.DrawImage(icon, iconX, (Height - iconSize) / 2, iconSize, iconSize);

            TextRenderer.DrawText(g, text, Font,
                new Rectangle(textX, 0, Width - textX - 36, Height),
                ForeColor,
                TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine |
                TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
        }

        // Dropdown arrow
        var arrowSize = 16;
        var arrowX = Width - arrowSize - Tokens.Space.MD;
        var arrowY = (Height - arrowSize) / 2;
        var arrow = IconService.GetImage(Symbol.ChevronDown, arrowSize, IconService.IconWeight.Regular,
            _focused ? Tokens.Color.AccentPrimary : Tokens.Color.TextMuted);
        g.DrawImage(arrow, arrowX, arrowY, arrowSize, arrowSize);
    }

    protected override void OnDrawItem(DrawItemEventArgs e)
    {
        if (e.Index < 0) return;

        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = e.Bounds;
        bool selected = (e.State & DrawItemState.Selected) == DrawItemState.Selected;
        bool focused = (e.State & DrawItemState.Focus) == DrawItemState.Focus;

        // Background
        var bg = selected ? Tokens.Color.BgHover : Tokens.Color.BgCard;
        if (!Enabled) bg = ControlPaint.Light(bg, 0.3f);
        using (var brush = new SolidBrush(bg))
            g.FillRectangle(brush, bounds);

        // Item text
        var text = Items[e.Index]?.ToString() ?? "";
        var icon = GetItemIcon(e.Index);
        int iconSize = 20;
        int iconX = Tokens.Space.MD;
        int textX = icon != null ? iconX + iconSize + Tokens.Space.SM : Tokens.Space.MD;

        if (icon != null)
            g.DrawImage(icon, iconX, bounds.Y + (bounds.Height - iconSize) / 2, iconSize, iconSize);

        var textColor = selected ? Tokens.Color.AccentPrimary : ForeColor;
        if (!Enabled) textColor = Tokens.Color.TextMuted;

        TextRenderer.DrawText(g, text, Font,
            new Rectangle(textX, bounds.Y, bounds.Width - textX - Tokens.Space.MD, bounds.Height),
            textColor,
            TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine |
            TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);

        e.DrawFocusRectangle();
    }

    protected virtual Image? GetItemIcon(int index)
    {
        // Override em classes derivadas para ícones customizados
        return null;
    }

    protected override void OnEnabledChanged(EventArgs e)
    {
        base.OnEnabledChanged(e);
        Invalidate();
    }
}