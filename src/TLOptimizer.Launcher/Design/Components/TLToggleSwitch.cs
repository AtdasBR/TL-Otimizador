using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Toggle switch moderno — animado, acessível (keyboard), label sincronizado.
/// </summary>
public class TLToggleSwitch : Control
{
    private bool _checked;
    private float _thumbPosition; // 0 a 1
    private Timer? _animationTimer;
    private Label? _label;
    private string _onText = "Ligado";
    private string _offText = "Desligado";

    public TLToggleSwitch()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);

        Size = new Size(56, 28);
        MinimumSize = new Size(44, 24);
        TabStop = true;
        Cursor = Cursors.Hand;
        _thumbPosition = 0f;

        Click += (_, _) => Toggle();
        KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Space || e.KeyCode == Keys.Enter)
            {
                Toggle();
                e.Handled = true;
            }
        };
        GotFocus += (_, _) => Invalidate();
        LostFocus += (_, _) => Invalidate();
    }

    [Category("TL Design"), DefaultValue(false)]
    public bool Checked
    {
        get => _checked;
        set
        {
            if (_checked == value) return;
            _checked = value;
            AnimateTo(value ? 1f : 0f);
            UpdateLabel();
            OnCheckedChanged(EventArgs.Empty);
        }
    }

    [Category("TL Design")]
    public string OnText
    {
        get => _onText;
        set { _onText = value; UpdateLabel(); }
    }

    [Category("TL Design")]
    public string OffText
    {
        get => _offText;
        set { _offText = value; UpdateLabel(); }
    }

    [Category("TL Design")]
    public Label? Label
    {
        get => _label;
        set
        {
            _label = value;
            UpdateLabel();
        }
    }

    public event EventHandler? CheckedChanged;

    protected virtual void OnCheckedChanged(EventArgs e) => CheckedChanged?.Invoke(this, e);

    private void Toggle()
    {
        Checked = !_checked;
    }

    private void AnimateTo(float target)
    {
        if (_animationTimer != null) return;

        float start = _thumbPosition;
        const int duration = 150; // ms
        var startTime = Environment.TickCount64;

        _animationTimer = new Timer { Interval = 16 };
        _animationTimer.Tick += (_, _) =>
        {
            float t = (float)(Environment.TickCount64 - startTime) / duration;
            if (t >= 1f)
            {
                _thumbPosition = target;
                _animationTimer?.Stop();
                _animationTimer?.Dispose();
                _animationTimer = null;
            }
            else
            {
                // Ease out cubic
                float eased = 1 - (float)Math.Pow(1 - t, 3);
                _thumbPosition = start + (target - start) * eased;
            }
            Invalidate();
        };
        _animationTimer.Start();
    }

    private void UpdateLabel()
    {
        if (_label != null)
        {
            _label.Text = _checked ? _onText : _offText;
            _label.ForeColor = _checked ? Tokens.Color.AccentSuccess : Tokens.Color.TextMuted;
        }
    }

    public void SetLabel(Label label, string onText = "Ligado", string offText = "Desligado")
    {
        _label = label;
        _onText = onText;
        _offText = offText;
        UpdateLabel();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var trackRect = new Rectangle(0, (Height - 20) / 2, Width - 4, 20);
        var thumbSize = trackRect.Height - 4;
        var thumbX = (int)(trackRect.X + 2 + _thumbPosition * (trackRect.Width - thumbSize - 4));

        // Track
        var trackColor = _checked ? Tokens.Color.AccentSuccess : Tokens.Color.BorderDefault;
        if (!Enabled) trackColor = ControlPaint.Light(trackColor, 0.5f);

        using (var path = GraphicsExtensions.RoundedRect(trackRect, trackRect.Height / 2))
        using (var brush = new SolidBrush(trackColor))
            g.FillPath(brush, path);

        // Thumb
        var thumbRect = new Rectangle(thumbX, trackRect.Y + 2, thumbSize, thumbSize);
        var thumbColor = Enabled ? Color.White : Tokens.Color.TextMuted;

        using (var path = GraphicsExtensions.RoundedRect(thumbRect, thumbSize / 2))
        {
            // Shadow
            if (Enabled)
            {
                using var shadowBrush = new SolidBrush(Color.FromArgb(30, 0, 0, 0));
                var shadowRect = new Rectangle(thumbRect.X + 1, thumbRect.Y + 1, thumbSize, thumbSize);
                using var shadowPath = GraphicsExtensions.RoundedRect(shadowRect, thumbSize / 2);
                g.FillPath(shadowBrush, shadowPath);
            }

            using var brush = new SolidBrush(thumbColor);
            g.FillPath(brush, path);
        }

        // Focus ring
        if (Focused)
        {
            var focusRect = new Rectangle(0, 0, Width - 1, Height - 1);
            using var path = GraphicsExtensions.RoundedRect(focusRect, Tokens.Radius.SM);
            using var pen = new Pen(Tokens.Color.BorderFocus, 2f);
            g.DrawPath(pen, path);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _animationTimer?.Stop();
            _animationTimer?.Dispose();
        }
        base.Dispose(disposing);
    }
}