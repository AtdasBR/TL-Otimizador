using System.Collections.Concurrent;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Reflection;
using System.Runtime.InteropServices;

namespace TLOptimizer.Launcher.Design.Services;

/// <summary>
/// Símbolos Fluent — mapeamento semântico para os glyphs oficiais
/// do Fluent System Icons (codepoints PUA usados pelo conjunto de fontes).
/// </summary>
public enum Symbol
{
    Home,
    Delete,
    Settings,
    Wifi,
    Edit,
    Shield,
    Games,
    Download,
    Refresh,
    Sync,
    Clear,
    Filter,
    Search,
    Play,
    Checkmark,
    Dismiss,
    ChevronRight,
    ChevronLeft,
    ChevronDown,
    Close,
    Info,
    Warning,
    Error,
    CheckmarkCircle,
    Clock,
    Alert,
    Block,
    Theme,
    Globe,
    Rocket,
    Doctor,
    Folder,
    Save,
    Upload,
    Chip,
    Memory,
    HardDrive,
    GraphicsCard,
    Monitor,
    Chat,
    Code,
    Gamepad,
    Music,
    Tool
}

/// <summary>
/// Serviço centralizado de ícones — renderiza os Fluent System Icons
/// diretamente das fontes oficiais embutidas (sem dependência externa).
/// Suporta pesos Regular/Filled e qualquer tamanho (escalado por vetor).
/// </summary>
public static class IconService
{
    // Cache: key = "Symbol_Weight_Size_Color" -> Bitmap
    private static readonly ConcurrentDictionary<string, Bitmap> _cache = new();
    private static readonly object _initLock = new();
    private static bool _initialized;

    private static PrivateFontCollection? _regularFonts;
    private static PrivateFontCollection? _filledFonts;
    private static FontFamily? _regularFamily;
    private static FontFamily? _filledFamily;
    private static byte[]? _regularBytes;
    private static byte[]? _filledBytes;

    // Símbolos mais usados — mapeamento semântico
    public static class Symbols
    {
        // Navegação/Categorias
        public static readonly Symbol Home = Symbol.Home;
        public static readonly Symbol Broom = Symbol.Delete;           // Limpeza
        public static readonly Symbol Settings = Symbol.Settings;      // Ajustes
        public static readonly Symbol Wifi = Symbol.Wifi;              // Rede
        public static readonly Symbol PaintBrush = Symbol.Edit;        // Visual
        public static readonly Symbol Shield = Symbol.Shield;          // Privacidade
        public static readonly Symbol Gear = Symbol.Settings;          // Sistema
        public static readonly Symbol Game = Symbol.Games;             // FiveM

        // Gerenciador de Apps
        public static readonly Symbol Download = Symbol.Download;      // Instalar
        public static readonly Symbol Delete = Symbol.Delete;          // Desinstalar
        public static readonly Symbol Refresh = Symbol.Refresh;        // Atualizar
        public static readonly Symbol Sync = Symbol.Sync;              // Atualizar Tudo
        public static readonly Symbol Clear = Symbol.Clear;            // Limpar Seleção
        public static readonly Symbol Filter = Symbol.Filter;          // Filtro
        public static readonly Symbol Search = Symbol.Search;          // Busca

        // Ações
        public static readonly Symbol Play = Symbol.Play;              // Executar
        public static readonly Symbol Check = Symbol.Checkmark;        // Aplicar/OK
        public static readonly Symbol Close = Symbol.Dismiss;          // Cancelar/Fechar
        public static readonly Symbol ChevronRight = Symbol.ChevronRight; // Próximo
        public static readonly Symbol ChevronLeft = Symbol.ChevronLeft;   // Voltar
        public static readonly Symbol Info = Symbol.Info;              // Info
        public static readonly Symbol Warning = Symbol.Warning;        // Aviso
        public static readonly Symbol Error = Symbol.Error;            // Erro
        public static readonly Symbol Success = Symbol.CheckmarkCircle; // Sucesso

        // Status
        public static readonly Symbol CheckmarkCircle = Symbol.CheckmarkCircle; // Instalado
        public static readonly Symbol Clock = Symbol.Clock;            // Verificando
        public static readonly Symbol Alert = Symbol.Alert;            // Atualização disponível
        public static readonly Symbol Block = Symbol.Block;            // Bloqueado

        // UI
        public static readonly Symbol Theme = Symbol.Theme;            // Tema
        public static readonly Symbol Globe = Symbol.Globe;            // Internet/Update
        public static readonly Symbol Rocket = Symbol.Rocket;          // Performance
        public static readonly Symbol Doctor = Symbol.Doctor;          // Diagnóstico
        public static readonly Symbol Folder = Symbol.Folder;          // Pastas/Cache
        public static readonly Symbol Trash = Symbol.Delete;           // Lixeira/Limpar
        public static readonly Symbol Save = Symbol.Save;              // Backup/Exportar
        public static readonly Symbol Upload = Symbol.Upload;          // Importar
        public static readonly Symbol Download2 = Symbol.Download;     // Baixar

        // Hardware
        public static readonly Symbol Cpu = Symbol.Chip;               // CPU
        public static readonly Symbol Ram = Symbol.Memory;             // RAM
        public static readonly Symbol Disk = Symbol.HardDrive;         // Disco
        public static readonly Symbol Gpu = Symbol.GraphicsCard;       // GPU
        public static readonly Symbol Monitor = Symbol.Monitor;        // Tela

        // Apps categorias
        public static readonly Symbol Browser = Symbol.Globe;          // Navegadores
        public static readonly Symbol Chat = Symbol.Chat;              // Comunicação
        public static readonly Symbol Code = Symbol.Code;              // Desenvolvimento
        public static readonly Symbol Gamepad = Symbol.Gamepad;        // Jogos
        public static readonly Symbol Music = Symbol.Music;            // Multimídia
        public static readonly Symbol Tool = Symbol.Tool;              // Utilitários/Drivers
    }

    // Pesos disponíveis
    public enum IconWeight
    {
        Regular,
        Filled
    }

    // Tamanhos padrão
    public static readonly int[] StandardSizes = { 12, 16, 20, 24, 28, 32, 40, 48 };

    private static readonly Dictionary<Symbol, (int Regular, int Filled)> GlyphMap = new()
    {
        [Symbol.Home] = (0xF481, 0xF488),
        [Symbol.Delete] = (0xF34D, 0xF34D),
        [Symbol.Settings] = (0xF6AA, 0xF6B3),
        [Symbol.Wifi] = (0xF8AD, 0xF8C5),
        [Symbol.Edit] = (0xF3DE, 0xF3DD),
        [Symbol.Shield] = (0xF6BF, 0xF6C8),
        [Symbol.Games] = (0xF451, 0xF455),
        [Symbol.Download] = (0xF151, 0xF151),
        [Symbol.Refresh] = (0xF13E, 0xF13E),
        [Symbol.Sync] = (0xF191, 0xF191),
        [Symbol.Clear] = (0xF36E, 0xF36E),
        [Symbol.Filter] = (0xF407, 0xF406),
        [Symbol.Search] = (0xF690, 0xF69A),
        [Symbol.Play] = (0xF606, 0xF610),
        [Symbol.Checkmark] = (0xF295, 0xF295),
        [Symbol.Dismiss] = (0xF36A, 0xF36A),
        [Symbol.ChevronRight] = (0xF2B1, 0xF2B1),
        [Symbol.ChevronLeft] = (0xF2AB, 0xF2AB),
        [Symbol.ChevronDown] = (0xF2A4, 0xF2A4),
        [Symbol.Close] = (0xF36A, 0xF36A),
        [Symbol.Info] = (0xF4A4, 0xF4AB),
        [Symbol.Warning] = (0xF86A, 0xF882),
        [Symbol.Error] = (0xF3F2, 0xF3F1),
        [Symbol.CheckmarkCircle] = (0xF299, 0xF299),
        [Symbol.Clock] = (0xF2DE, 0xF2DE),
        [Symbol.Alert] = (0xF115, 0xF115),
        [Symbol.Block] = (0xF62E, 0xF638),
        [Symbol.Theme] = (0xF2F6, 0xF2F6),
        [Symbol.Globe] = (0xF45B, 0xF45F),
        [Symbol.Rocket] = (0xF678, 0xF682),
        [Symbol.Doctor] = (0xF377, 0xF377),
        [Symbol.Folder] = (0xF419, 0xF41D),
        [Symbol.Save] = (0xF680, 0xF68A),
        [Symbol.Upload] = (0xF1A5, 0xF1A5),
        [Symbol.Chip] = (0xF35C, 0xF35C),
        [Symbol.Memory] = (0xF0F0, 0xF0F0),
        [Symbol.HardDrive] = (0xF0306, 0xF0319),
        [Symbol.GraphicsCard] = (0xF84D, 0xF865),
        [Symbol.Monitor] = (0xF35A, 0xF35A),
        [Symbol.Chat] = (0xF287, 0xF287),
        [Symbol.Code] = (0xF2F0, 0xF2F0),
        [Symbol.Gamepad] = (0xEEB9, 0xEEB9),
        [Symbol.Music] = (0xE852, 0xE860),
        [Symbol.Tool] = (0xF82F, 0xF848)
    };

    /// <summary>
    /// Inicializa o serviço (chamado automaticamente no primeiro uso).
    /// </summary>
    public static void Initialize()
    {
        if (_initialized) return;
        lock (_initLock)
        {
            if (_initialized) return;
            LoadFonts();
            _initialized = true;
        }
    }

    /// <summary>
    /// Obtém Bitmap do ícone Fluent UI.
    /// </summary>
    /// <param name="symbol">Símbolo (ex: Symbol.Home)</param>
    /// <param name="size">Tamanho em pixels (ex: 24)</param>
    /// <param name="weight">Regular ou Filled</param>
    /// <param name="color">Cor do ícone (default: TextPrimary)</param>
    /// <returns>Bitmap pronto para uso</returns>
    public static Bitmap Get(Symbol symbol, int size = 24, IconWeight weight = IconWeight.Regular, Color? color = null)
    {
        Initialize();

        var c = color ?? Tokens.Color.TextPrimary;
        var key = $"{symbol}_{weight}_{size}_{c.R}_{c.G}_{c.B}";

        return _cache.GetOrAdd(key, _ =>
        {
            var glyph = GetGlyphString(symbol, weight);
            var bitmap = new Bitmap(size, size);
            bitmap.SetResolution(96, 96);

            using var g = Graphics.FromImage(bitmap);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;

            if (!string.IsNullOrEmpty(glyph) && TryGetFamily(weight, out var family))
            {
                DrawGlyph(g, family!, glyph, size, c);
            }
            else
            {
                // Fallback: desenha geometria simples
                DrawFallback(g, symbol, size, c);
            }

            return bitmap;
        });
    }

    /// <summary>
    /// Obtém Icon (para uso em Button.Image, etc).
    /// </summary>
    public static Icon GetIcon(Symbol symbol, int size = 24, IconWeight weight = IconWeight.Regular, Color? color = null)
    {
        var bmp = Get(symbol, size, weight, color);
        return Icon.FromHandle(bmp.GetHicon());
    }

    /// <summary>
    /// Obtém Image (para PictureBox, etc).
    /// </summary>
    public static Image GetImage(Symbol symbol, int size = 24, IconWeight weight = IconWeight.Regular, Color? color = null)
        => Get(symbol, size, weight, color);

    /// <summary>
    /// Pré-carrega ícones comuns para evitar lag no primeiro uso.
    /// </summary>
    public static void PreloadCommon()
    {
        var common = new[]
        {
            Symbols.Home, Symbols.Broom, Symbols.Settings, Symbols.Wifi,
            Symbols.PaintBrush, Symbols.Shield, Symbols.Gear, Symbols.Game,
            Symbols.Download, Symbols.Delete, Symbols.Refresh, Symbols.Search,
            Symbols.Play, Symbols.Check, Symbols.Close, Symbols.ChevronRight,
            Symbols.Info, Symbols.Warning, Symbols.Error, Symbols.Success,
            Symbols.CheckmarkCircle, Symbols.Clock, Symbols.Filter,
            Symbols.Cpu, Symbols.Ram, Symbols.Disk, Symbols.Gpu,
            Symbols.Browser, Symbols.Chat, Symbols.Code, Symbols.Gamepad
        };

        foreach (var sym in common)
        {
            foreach (var size in new[] { 16, 20, 24, 28 })
            {
                foreach (var w in new[] { IconWeight.Regular, IconWeight.Filled })
                {
                    _ = Get(sym, size, w);
                }
            }
        }
    }

    // --- Internos ---

    private static string GetGlyphString(Symbol symbol, IconWeight weight)
    {
        if (GlyphMap.TryGetValue(symbol, out var cp))
        {
            var code = weight == IconWeight.Filled ? cp.Filled : cp.Regular;
            if (code > 0 && code <= 0x10FFFF)
            {
                try { return char.ConvertFromUtf32(code); }
                catch { return string.Empty; }
            }
        }
        return string.Empty;
    }

    private static bool TryGetFamily(IconWeight weight, out FontFamily? family)
    {
        var fonts = weight == IconWeight.Filled ? _filledFonts : _regularFonts;
        var f = weight == IconWeight.Filled ? _filledFamily : _regularFamily;
        family = f;
        return fonts != null && f != null;
    }

    private static void LoadFonts()
    {
        _regularBytes = ReadResource("FluentSystemIcons-Regular.ttf");
        _filledBytes = ReadResource("FluentSystemIcons-Filled.ttf");
        _regularFonts = new PrivateFontCollection();
        _filledFonts = new PrivateFontCollection();

        if (_regularBytes != null)
        {
            AddMemoryFont(_regularFonts, _regularBytes);
            if (_regularFonts.Families.Length > 0) _regularFamily = _regularFonts.Families[0];
        }

        if (_filledBytes != null)
        {
            AddMemoryFont(_filledFonts, _filledBytes);
            if (_filledFonts.Families.Length > 0) _filledFamily = _filledFonts.Families[0];
        }
    }

    private static byte[]? ReadResource(string fileName)
    {
        var asm = Assembly.GetExecutingAssembly();
        var resName = asm.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith(fileName, StringComparison.OrdinalIgnoreCase));
        if (resName == null) return null;

        using var stream = asm.GetManifestResourceStream(resName);
        if (stream == null) return null;

        using var ms = new MemoryStream();
        stream.CopyTo(ms);
        return ms.ToArray();
    }

    private static void AddMemoryFont(PrivateFontCollection fonts, byte[] fontData)
    {
        var handle = GCHandle.Alloc(fontData, GCHandleType.Pinned);
        try
        {
            fonts.AddMemoryFont(handle.AddrOfPinnedObject(), fontData.Length);
        }
        finally
        {
            handle.Free();
        }
    }

    private static void DrawGlyph(Graphics g, FontFamily family, string glyph, int size, Color color)
    {
        // Traça o glyph como vetor centrado — sem depender de métricas de linha
        using var path = new GraphicsPath();
        path.AddString(glyph, family, (int)FontStyle.Regular, size, new Point(0, 0), StringFormat.GenericTypographic);

        var bounds = path.GetBounds();
        if (bounds.Width <= 0 || bounds.Height <= 0) return;

        // Centraliza dentro do bitmap
        var dx = (size - bounds.Width) / 2f - bounds.X;
        var dy = (size - bounds.Height) / 2f - bounds.Y;

        using var translate = new Matrix();
        translate.Translate(dx, dy);
        path.Transform(translate);

        using var brush = new SolidBrush(color);
        g.FillPath(brush, path);
    }

    private static void DrawFallback(Graphics g, Symbol symbol, int size, Color color)
    {
        // Placeholder simples baseado no símbolo (diamante/quadrado)
        using var brush = new SolidBrush(color);
        var rect = new Rectangle(2, 2, size - 4, size - 4);
        g.FillRectangle(brush, rect);
    }

    /// <summary>
    /// Limpa o cache (útil se mudar tema).
    /// </summary>
    public static void ClearCache()
    {
        foreach (var bmp in _cache.Values)
            bmp?.Dispose();
        _cache.Clear();
    }
}