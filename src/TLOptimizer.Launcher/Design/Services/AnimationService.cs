using System.Drawing;
using System.Windows.Forms;
using Timer = System.Windows.Forms.Timer;

namespace TLOptimizer.Launcher.Design.Services;

/// <summary>
/// Serviço de animações para WinForms — transições suaves baseadas em Timer.
/// </summary>
public static class AnimationService
{
    private static readonly List<Animation> _activeAnimations = new();
    private static readonly object _lock = new();
    private static Timer? _timer;

    /// <summary>
    /// Inicia animação de propriedade (Location, Size, Opacity via BackColor alpha, etc).
    /// </summary>
    public static void Animate(Control control, string propertyName, object from, object to,
        int duration = Tokens.Motion.Normal, Easing easing = Easing.EaseOutCubic,
        Action? onComplete = null)
    {
        if (control.IsDisposed || control.Disposing) return;

        var anim = new Animation
        {
            Control = control,
            PropertyName = propertyName,
            From = from,
            To = to,
            Duration = duration,
            Easing = easing,
            OnComplete = onComplete,
            StartTime = Environment.TickCount64
        };

        lock (_lock)
        {
            _activeAnimations.Add(anim);
            EnsureTimer();
        }
    }

    /// <summary>
    /// Anima Location (slide).
    /// </summary>
    public static void Slide(Control control, Point from, Point to,
        int duration = Tokens.Motion.Normal, Easing easing = Easing.EaseOutCubic,
        Action? onComplete = null)
    {
        control.Location = from;
        Animate(control, "Location", from, to, duration, easing, onComplete);
    }

    /// <summary>
    /// Anima Size (expand/collapse).
    /// </summary>
    public static void Resize(Control control, Size from, Size to,
        int duration = Tokens.Motion.Normal, Easing easing = Easing.EaseOutCubic,
        Action? onComplete = null)
    {
        control.Size = from;
        Animate(control, "Size", from, to, duration, easing, onComplete);
    }

    /// <summary>
    /// Anima cor de fundo (fade).
    /// </summary>
    public static void FadeColor(Control control, Color from, Color to,
        int duration = Tokens.Motion.Fast, Easing easing = Easing.EaseOutCubic,
        Action? onComplete = null)
    {
        control.BackColor = from;
        Animate(control, "BackColor", from, to, duration, easing, onComplete);
    }

    /// <summary>
    /// Anima Opacidade simulada via BackColor alpha (para controles que suportam).
    /// </summary>
    public static void FadeOpacity(Control control, byte fromAlpha, byte toAlpha,
        int duration = Tokens.Motion.Normal, Easing easing = Easing.EaseOutCubic,
        Action? onComplete = null)
    {
        var from = Color.FromArgb(fromAlpha, control.BackColor);
        var to = Color.FromArgb(toAlpha, control.BackColor);
        Animate(control, "BackColor", from, to, duration, easing, onComplete);
    }

    /// <summary>
    /// Para todas as animações de um controle.
    /// </summary>
    public static void Stop(Control control)
    {
        lock (_lock)
        {
            _activeAnimations.RemoveAll(a => a.Control == control);
        }
    }

    /// <summary>
    /// Para todas as animações.
    /// </summary>
    public static void StopAll()
    {
        lock (_lock)
        {
            _activeAnimations.Clear();
        }
    }

    private static void EnsureTimer()
    {
        if (_timer != null) return;

        _timer = new Timer { Interval = 16 }; // ~60fps
        _timer.Tick += (_, _) => Tick();
        _timer.Start();
    }

    private static void Tick()
    {
        var now = Environment.TickCount64;
        var completed = new List<Animation>();

        lock (_lock)
        {
            foreach (var anim in _activeAnimations)
            {
                if (anim.Control.IsDisposed || anim.Control.Disposing)
                {
                    completed.Add(anim);
                    continue;
                }

                float t = (float)(now - anim.StartTime) / anim.Duration;
                if (t >= 1f)
                {
                    ApplyValue(anim.Control, anim.PropertyName, anim.To);
                    completed.Add(anim);
                }
                else
                {
                    float eased = Ease(t, anim.Easing);
                    var current = Interpolate(anim.From, anim.To, eased);
                    ApplyValue(anim.Control, anim.PropertyName, current);
                }
            }

            foreach (var c in completed)
                _activeAnimations.Remove(c);

            if (_activeAnimations.Count == 0)
            {
                _timer?.Stop();
                _timer?.Dispose();
                _timer = null;
            }
        }

        foreach (var c in completed)
            c.OnComplete?.Invoke();
    }

    private static void ApplyValue(Control control, string propertyName, object value)
    {
        try
        {
            var prop = control.GetType().GetProperty(propertyName);
            if (prop != null && prop.CanWrite)
                prop.SetValue(control, value);
        }
        catch { /* ignore */ }
    }

    private static object Interpolate(object from, object to, float t)
    {
        if (from is Point pf && to is Point pt)
            return Interpolation.Lerp(pf, pt, t);
        if (from is Size sf && to is Size st)
            return Interpolation.Lerp(sf, st, t);
        if (from is Rectangle rf && to is Rectangle rt)
            return Interpolation.Lerp(rf, rt, t);
        if (from is Color cf && to is Color ct)
            return Interpolation.Lerp(cf, ct, t);
        if (from is int if_ && to is int it)
            return Interpolation.Lerp(if_, it, t);
        if (from is float ff && to is float ft)
            return Interpolation.Lerp(ff, ft, t);
        return to;
    }

    private static float Ease(float t, Easing easing)
    {
        return easing switch
        {
            Easing.Linear => t,
            Easing.EaseInCubic => t * t * t,
            Easing.EaseOutCubic => 1 - (float)Math.Pow(1 - t, 3),
            Easing.EaseInOutCubic => t < 0.5f ? 4 * t * t * t : 1 - (float)Math.Pow(-2 * t + 2, 3) / 2,
            Easing.EaseOutExpo => t >= 1 ? 1 : 1 - (float)Math.Pow(2, -10 * t),
            Easing.EaseOutBack => 1 + (float)Math.Pow(t - 1, 3) * (1.70158f + 1),
            _ => 1 - (float)Math.Pow(1 - t, 3)
        };
    }

    // --- Interpolation helpers ---
    private static class Interpolation
    {
        public static float Lerp(float a, float b, float t) => a + (b - a) * t;
        public static int Lerp(int a, int b, float t) => (int)Math.Round(Lerp((float)a, (float)b, t));
        public static Color Lerp(Color a, Color b, float t)
        {
            t = Clamp(t);
            return Color.FromArgb(Lerp(a.A, b.A, t), Lerp(a.R, b.R, t), Lerp(a.G, b.G, t), Lerp(a.B, b.B, t));
        }
        public static Point Lerp(Point a, Point b, float t) => new Point(Lerp(a.X, b.X, t), Lerp(a.Y, b.Y, t));
        public static Size Lerp(Size a, Size b, float t) => new Size(Lerp(a.Width, b.Width, t), Lerp(a.Height, b.Height, t));
        public static Rectangle Lerp(Rectangle a, Rectangle b, float t) => new Rectangle(Lerp(a.X, b.X, t), Lerp(a.Y, b.Y, t), Lerp(a.Width, b.Width, t), Lerp(a.Height, b.Height, t));
        private static float Clamp(float v) => Math.Max(0f, Math.Min(1f, v));
    }

    // --- Tipos internos ---
    private sealed class Animation
    {
        public Control Control { get; init; } = null!;
        public string PropertyName { get; init; } = "";
        public object From { get; init; } = null!;
        public object To { get; init; } = null!;
        public int Duration { get; init; }
        public Easing Easing { get; init; }
        public long StartTime { get; set; }
        public Action? OnComplete { get; init; }
    }

    public enum Easing
    {
        Linear,
        EaseInCubic,
        EaseOutCubic,
        EaseInOutCubic,
        EaseOutExpo,
        EaseOutBack
    }
}