using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design.Services;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Caixa de busca moderna — placeholder animado, botão clear, atalho Ctrl+K, debounce.
/// </summary>
public class TLSearchBox : Control
{
    private readonly TextBox _innerTextBox;
    private readonly Timer _debounceTimer = new Timer { Interval = 300 };
    private string _placeholder = "Buscar...";
    private bool _focused;
    private bool _hasText;
    private float _placeholderOpacity = 1f;
    private Timer? _placeholderAnimTimer;
    private bool _initialized;

    public event EventHandler<TextChangedEventArgs>? SearchTextChanged;
    public event EventHandler? SearchCleared;

    public TLSearchBox()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        _innerTextBox = new TextBox
        {
            BorderStyle = BorderStyle.None,
            Font = Font,
            ForeColor = Tokens.Color.TextPrimary,
            BackColor = Tokens.Color.BgCard,
            Location = new Point(Tokens.Space.LG, (Height - Font.Height) / 2),
            Width = Width - Tokens.Space.LG * 2 - 36,
            Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right,
            TabStop = true
        };
        _innerTextBox.TextChanged += (_, _) =>
        {
            _hasText = !string.IsNullOrWhiteSpace(_innerTextBox.Text);
            UpdatePlaceholderAnimation();
            _debounceTimer.Stop();
            _debounceTimer.Start();
        };
        _innerTextBox.GotFocus += (_, _) => { _focused = true; Invalidate(); };
        _innerTextBox.LostFocus += (_, _) => { _focused = false; Invalidate(); };
        _innerTextBox.KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Escape)
            {
                Clear();
                e.Handled = true;
            }
        };

        Controls.Add(_innerTextBox);

        Size = new Size(280, 40);
        MinimumSize = new Size(200, 36);
        Font = Tokens.Font.Create(Tokens.Font.MD);
        BackColor = Tokens.Color.BgCard;
        ForeColor = Tokens.Color.TextPrimary;

        _debounceTimer.Tick += (_, _) =>
        {
            _debounceTimer.Stop();
            SearchTextChanged?.Invoke(this, new TextChangedEventArgs(_innerTextBox.Text));
        };

        // Atalho global Ctrl+K para foco
        KeyDown += (_, e) =>
        {
            if (e.Control && e.KeyCode == Keys.K)
            {
                _innerTextBox.Focus();
                e.Handled = true;
            }
        };

        _initialized = true;
    }

    [Category("TL Design")]
    public string Placeholder
    {
        get => _placeholder;
        set { _placeholder = value; Invalidate(); }
    }

    [Browsable(false)]
    public new string Text
    {
        get => _innerTextBox.Text;
        set { _innerTextBox.Text = value; _hasText = !string.IsNullOrWhiteSpace(value); Invalidate(); }
    }

    [Browsable(false)]
    public new Font Font
    {
        get => base.Font;
        set
        {
            base.Font = value;
            _innerTextBox.Font = value;
            Invalidate();
        }
    }

    public void Clear()
    {
        _innerTextBox.Clear();
        _hasText = false;
        SearchCleared?.Invoke(this, EventArgs.Empty);
        Invalidate();
    }

    public void FocusSearch() => _innerTextBox.Focus();

    private void UpdatePlaceholderAnimation()
    {
        _placeholderAnimTimer?.Stop();
        _placeholderAnimTimer?.Dispose();

        var target = (_focused || _hasText) ? 0f : 1f;
        var start = _placeholderOpacity;
        var startTime = Environment.TickCount64;
        const int duration = 150;

        _placeholderAnimTimer = new Timer { Interval = 16 };
        _placeholderAnimTimer.Tick += (_, _) =>
        {
            float t = (float)(Environment.TickCount64 - startTime) / duration;
            if (t >= 1f)
            {
                _placeholderOpacity = target;
                _placeholderAnimTimer?.Stop();
                _placeholderAnimTimer?.Dispose();
                _placeholderAnimTimer = null;
            }
            else
            {
                float eased = 1 - (float)Math.Pow(1 - t, 3);
                _placeholderOpacity = start + (target - start) * eased;
            }
            Invalidate();
        };
        _placeholderAnimTimer.Start();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        if (!_initialized) return;

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

        // Search icon
        var iconSize = 20;
        var iconX = Tokens.Space.MD;
        var iconY = (Height - iconSize) / 2;
        var icon = IconService.GetImage(Symbol.Search, iconSize, IconService.IconWeight.Regular,
            _focused ? Tokens.Color.AccentPrimary : Tokens.Color.TextMuted);
        g.DrawImage(icon, iconX, iconY, iconSize, iconSize);

        // Placeholder text
        if (_placeholderOpacity > 0.01f && !_hasText)
        {
            var placeholderColor = Color.FromArgb(
                (int)(_placeholderOpacity * Tokens.Color.TextMuted.A),
                Tokens.Color.TextMuted);
            var textRect = new Rectangle(
                iconX + iconSize + Tokens.Space.SM,
                0,
                Width - iconX - iconSize - Tokens.Space.MD - 36,
                Height);
            TextRenderer.DrawText(g, _placeholder, Font, textRect, placeholderColor,
                TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine |
                TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
        }

        // Clear button (X)
        if (_hasText)
        {
            var clearSize = 20;
            var clearX = Width - clearSize - Tokens.Space.MD;
            var clearY = (Height - clearSize) / 2;
            var clearRect = new Rectangle(clearX, clearY, clearSize, clearSize);

            var clearColor = _focused ? Tokens.Color.TextSecondary : Tokens.Color.TextMuted;
            var clearIcon = IconService.GetImage(Symbol.Close, clearSize, IconService.IconWeight.Regular, clearColor);
            g.DrawImage(clearIcon, clearRect);

            // Guarda rect para hit test
            _clearRect = clearRect;
        }
        else
        {
            _clearRect = Rectangle.Empty;
        }

        // Ajusta textbox interno
        _innerTextBox.Location = new Point(iconX + iconSize + Tokens.Space.SM, (Height - _innerTextBox.Height) / 2);
        _innerTextBox.Width = Width - iconX - iconSize - Tokens.Space.SM - 36 - Tokens.Space.MD;
        _innerTextBox.ForeColor = ForeColor;
    }

    private Rectangle _clearRect = Rectangle.Empty;

    protected override void OnMouseClick(MouseEventArgs e)
    {
        base.OnMouseClick(e);
        if (!_clearRect.IsEmpty && _clearRect.Contains(e.Location))
        {
            Clear();
        }
        else
        {
            _innerTextBox.Focus();
        }
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        if (!_initialized) return;
        _innerTextBox.Width = Width - Tokens.Space.LG * 2 - 36;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _debounceTimer?.Stop();
            _debounceTimer?.Dispose();
            _placeholderAnimTimer?.Stop();
            _placeholderAnimTimer?.Dispose();
        }
        base.Dispose(disposing);
    }
}

public class TextChangedEventArgs : EventArgs
{
    public string Text { get; }
    public TextChangedEventArgs(string text) => Text = text;
}