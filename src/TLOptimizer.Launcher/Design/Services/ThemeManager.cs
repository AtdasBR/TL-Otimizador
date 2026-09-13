using System.Drawing;
using System.Text.Json;

namespace TLOptimizer.Launcher.Design.Services;

/// <summary>
/// Gerencia tema da aplicação — persiste preferência, aplica cores, notifica mudanças.
/// </summary>
public static class ThemeManager
{
    private static readonly string _themeFile = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "TLOptimizer", "theme.json");

    private static Theme _currentTheme = Theme.Dark;
    private static readonly List<Action<Theme>> _subscribers = new();
    private static readonly object _lock = new();

    public static Theme Current => _currentTheme;

    public static event Action<Theme>? ThemeChanged;

    /// <summary>
    /// Inicializa — carrega tema salvo ou usa padrão.
    /// </summary>
    public static void Initialize()
    {
        Load();
        Apply(_currentTheme);
    }

    /// <summary>
    /// Define tema atual e persiste.
    /// </summary>
    public static void SetTheme(Theme theme)
    {
        if (_currentTheme == theme) return;

        lock (_lock)
        {
            _currentTheme = theme;
            Save();
            Apply(theme);
            ThemeChanged?.Invoke(theme);
            foreach (var sub in _subscribers)
                sub(theme);
        }
    }

    /// <summary>
    /// Alterna entre Dark/Light (futuro).
    /// </summary>
    public static void Toggle()
    {
        SetTheme(_currentTheme == Theme.Dark ? Theme.Light : Theme.Dark);
    }

    /// <summary>
    /// Inscreve para notificações de mudança de tema.
    /// </summary>
    public static IDisposable Subscribe(Action<Theme> handler)
    {
        lock (_lock)
        {
            _subscribers.Add(handler);
        }
        return new Unsubscriber(() =>
        {
            lock (_lock)
            {
                _subscribers.Remove(handler);
            }
        });
    }

    /// <summary>
    /// Aplica cores do tema aos Tokens (runtime).
    /// </summary>
    private static void Apply(Theme theme)
    {
        // Tokens são readonly — em vez de mutar, componentes leem de ThemeManager.Current
        // Esta função existe para extensibilidade futura (ex: temas customizados)
        _ = theme; // evita warning
    }

    private static void Load()
    {
        try
        {
            if (File.Exists(_themeFile))
            {
                var json = File.ReadAllText(_themeFile);
                var data = JsonSerializer.Deserialize<ThemeData>(json);
                if (data != null && Enum.TryParse<Theme>(data.Name, out var t))
                    _currentTheme = t;
            }
        }
        catch { _currentTheme = Theme.Dark; }
    }

    private static void Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_themeFile)!);
            var json = JsonSerializer.Serialize(new ThemeData { Name = _currentTheme.ToString() });
            File.WriteAllText(_themeFile, json);
        }
        catch { /* ignore */ }
    }

    private sealed class ThemeData
    {
        public string Name { get; set; } = "Dark";
    }

    private sealed class Unsubscriber : IDisposable
    {
        private readonly Action _unsub;
        public Unsubscriber(Action unsub) => _unsub = unsub;
        public void Dispose() => _unsub();
    }
}

/// <summary>
/// Temas disponíveis.
/// </summary>
public enum Theme
{
    Dark,
    Light // Preparado para futuro
}

/// <summary>
/// Paleta de cores por tema (extensível).
/// </summary>
public static class ThemePalette
{
    public static IReadOnlyDictionary<string, Color> Get(Theme theme)
    {
        return theme switch
        {
            Theme.Light => LightColors,
            _ => DarkColors
        };
    }

    // Dark Theme (padrão atual)
    private static readonly Dictionary<string, Color> DarkColors = new()
    {
        ["bg-primary"]     = Tokens.Color.BgPrimary,
        ["bg-panel"]       = Tokens.Color.BgPanel,
        ["bg-card"]        = Tokens.Color.BgCard,
        ["bg-hover"]       = Tokens.Color.BgHover,
        ["accent-primary"] = Tokens.Color.AccentPrimary,
        ["accent-hover"]   = Tokens.Color.AccentHover,
        ["border-subtle"]  = Tokens.Color.BorderSubtle,
        ["text-primary"]   = Tokens.Color.TextPrimary,
        ["text-secondary"] = Tokens.Color.TextSecondary,
        ["text-muted"]     = Tokens.Color.TextMuted,
        ["success"]        = Tokens.Color.AccentSuccess,
        ["warning"]        = Tokens.Color.AccentWarning,
        ["danger"]         = Tokens.Color.AccentDanger,
    };

    // Light Theme (preparado)
    private static readonly Dictionary<string, Color> LightColors = new()
    {
        ["bg-primary"]     = Color.FromArgb(250, 250, 252),
        ["bg-panel"]       = Color.White,
        ["bg-card"]        = Color.FromArgb(245, 245, 248),
        ["bg-hover"]       = Color.FromArgb(230, 238, 250),
        ["accent-primary"] = Tokens.Color.AccentPrimary,
        ["accent-hover"]   = Tokens.Color.AccentHover,
        ["border-subtle"]  = Color.FromArgb(220, 220, 226),
        ["text-primary"]   = Color.FromArgb(10, 10, 12),
        ["text-secondary"] = Color.FromArgb(80, 80, 88),
        ["text-muted"]     = Color.FromArgb(140, 140, 148),
        ["success"]        = Color.FromArgb(40, 160, 70),
        ["warning"]        = Color.FromArgb(200, 150, 30),
        ["danger"]         = Color.FromArgb(200, 60, 60),
    };
}