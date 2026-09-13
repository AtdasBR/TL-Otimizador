using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Components;

/// <summary>
/// Progress ring (circular) — indeterminate ou determinate.
/// Tamanhos sm/md/lg, cor customizável, animação suave.
/// </summary>
public enum TLProgressRingSize
{
    Small,
    Medium,
    Large
}

public class TLProgressRing : Control
{
    private float _value; // 0 a 1
    private bool _indeterminate;
    private TLProgressRingSize _size = TLProgressRingSize.Medium;
    private Timer? _spinTimer;
    private float _spinAngle;
    private Color _progressColor = Tokens.Color.AccentPrimary;
    private Color _trackColor = Tokens.Color.BorderSubtle;

    public TLProgressRing()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);

        Size = new Size(32, 32);
        TabStop = false;

        _spinTimer = new Timer { Interval = 50 };
        _spinTimer.Tick += (_, _) =>
        {
            if (_indeterminate)
            {
                _spinAngle += 12f;
                if (_spinAngle >= 360f) _spinAngle -= 360f;
                Invalidate();
            }
        };
    }

    [Category("TL Design"), DefaultValue(0f)]
    public float Value
    {
        get => _value;
        set
        {
            _value = Math.Clamp(value, 0f, 1f);
            _indeterminate = false;
            Invalidate();
        }
    }

    [Category("TL Design"), DefaultValue(false)]
    public bool Indeterminate
    {
        get => _indeterminate;
        set
        {
            _indeterminate = value;
            if (value) _spinTimer?.Start(); else _spinTimer?.Stop();
            Invalidate();
        }
    }

    [Category("TL Design"), DefaultValue(TLProgressRingSize.Medium)]
    public TLProgressRingSize RingSize
    {
        get => _size;
        set { _size = value; UpdateSize(); Invalidate(); }
    }

    [Category("TL Design")]
    public Color ProgressColor
    {
        get => _progressColor;
        set { _progressColor = value; Invalidate(); }
    }

    [Category("TL Design")]
    public Color TrackColor
    {
        get => _trackColor;
        set { _trackColor = value; Invalidate(); }
    }

    private void UpdateSize()
    {
        var (d, stroke) = _size switch
        {
            TLProgressRingSize.Small => (20, 2f),
            TLProgressRingSize.Large => (48, 4f),
            _ => (32, 3f)
        };
        Size = new Size(d, d);
        _strokeWidth = stroke;
    }

    private float _strokeWidth = 3f;

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var bounds = ClientRectangle;
        var center = new PointF(bounds.Width / 2f, bounds.Height / 2f);
        var radius = Math.Min(bounds.Width, bounds.Height) / 2f - _strokeWidth;

        // Track
        using (var pen = new Pen(_trackColor, _strokeWidth)
        { StartCap = LineCap.Round, EndCap = LineCap.Round })
        {
            g.DrawEllipse(pen, center.X - radius, center.Y - radius, radius * 2, radius * 2);
        }

        if (_indeterminate)
        {
            // Arc animado
            float sweep = 90f;
            float start = _spinAngle;

            using (var pen = new Pen(_progressColor, _strokeWidth)
            { StartCap = LineCap.Round, EndCap = LineCap.Round })
            {
                g.DrawArc(pen,
                    center.X - radius, center.Y - radius, radius * 2, radius * 2,
                    start, sweep);
            }
        }
        else
        {
            // Arc proporcional ao valor
            float sweep = 360f * _value;
            float start = -90f; // Topo

            using (var pen = new Pen(_progressColor, _strokeWidth)
            { StartCap = LineCap.Round, EndCap = LineCap.Round })
            {
                if (_value > 0)
                    g.DrawArc(pen,
                        center.X - radius, center.Y - radius, radius * 2, radius * 2,
                        start, sweep);
            }

            // Texto de porcentagem (apenas Large)
            if (_size == TLProgressRingSize.Large)
            {
                var text = $"{(int)(_value * 100)}%";
                using var font = Tokens.Font.Create(Tokens.Font.MD);
                var size = g.MeasureString(text, font);
                g.DrawString(text, font, new SolidBrush(Tokens.Color.TextPrimary),
                    center.X - size.Width / 2, center.Y - size.Height / 2);
            }
        }
    }

    public void SetValue(float value, bool animated = false)
    {
        if (!animated)
        {
            Value = value;
            return;
        }

        // Anima transição
        float start = _value;
        float target = Math.Clamp(value, 0f, 1f);
        const int duration = 300;
        var startTime = Environment.TickCount64;

        var timer = new Timer { Interval = 16 };
        timer.Tick += (_, _) =>
        {
            float t = (float)(Environment.TickCount64 - startTime) / duration;
            if (t >= 1f)
            {
                _value = target;
                timer.Stop();
                timer.Dispose();
            }
            else
            {
                float eased = 1 - (float)Math.Pow(1 - t, 3);
                _value = start + (target - start) * eased;
            }
            Invalidate();
        };
        timer.Start();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _spinTimer?.Stop();
            _spinTimer?.Dispose();
        }
        base.Dispose(disposing);
    }
}