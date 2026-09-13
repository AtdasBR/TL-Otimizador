using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using TLOptimizer.Launcher.Design;
using TLOptimizer.Launcher.Design.Components;
using TLOptimizer.Launcher.Design.Services;

namespace TLOptimizer.Launcher;

/// <summary>
/// Janela principal do launcher reconstruída sobre o Design System (Tokens +
/// componentes TL). Preserva toda a lógica de negócio do app original.
/// </summary>
public sealed class MainForm : Form
{
    // ============================================================
    // MODELO DE MENU (nome exibido em português simples)
    // ============================================================

    private sealed record MenuAction(string Id, string Nome, string Desc, string Risco);

    private sealed record MenuCategory(Symbol Icon, string Cat, MenuAction[] Itens);

    private static readonly MenuCategory[] _menuCategorias =
    {
        new(IconService.Symbols.Broom, "Limpeza", new[]
        {
            new MenuAction("11","Temp. do Windows","Apaga arquivos temporarios do sistema","Seguro"),
            new MenuAction("13","Temporarios","Remove arquivos temporarios de usuario/sistema","Seguro"),
            new MenuAction("10","Logs Eventos","Limpa logs do Visualizador de Eventos","Seguro"),
            new MenuAction("12","Cache de Internet","Limpa cache DNS e temporarios de rede","Seguro"),
            new MenuAction("14","Limpeza Extrema","Limpeza profunda (cache drivers/fontes)","Moderado"),
            new MenuAction("15","Limpeza de Disco","Abre a ferramenta CleanMgr do Windows","Seguro"),
            new MenuAction("16","Reparar Sistema","Executa SFC e DISM para reparar arquivos","Moderado"),
        }),
        new(IconService.Symbols.Settings, "Tweaks", new[]
        {
            new MenuAction("1","Central de Acao","Abre o centro de notificacoes e acoes","Seguro"),
            new MenuAction("3","Hibernacao","Libera espaco desligando a hibernacao","Moderado"),
            new MenuAction("4","Memoria Virtual","Ajusta o arquivo de paginacao","Arriscado"),
            new MenuAction("5","Tomar Posse","Adiciona Tomar Posse ao menu de contexto","Seguro"),
            new MenuAction("6","Pausar Updates","Pausa atualizacoes por 30 dias","Moderado"),
            new MenuAction("7","Comprimir Sistema","Comprime arquivos do sistema (CompactOS)","Moderado"),
            new MenuAction("8","Remover Apps","Remove apps UWP pre-instalados","Arriscado"),
            new MenuAction("18","Finalizar na Barra","Adiciona Finalizar tarefa na barra","Seguro"),
            new MenuAction("19","Menu Classico","Restaura menu de contexto classico","Seguro"),
            new MenuAction("27","Notificacoes","Desativa central de notificacoes","Seguro"),
            new MenuAction("28","Storage Sense","Desativa sensor de armazenamento","Seguro"),
            new MenuAction("29","Protecao Memoria","Desliga isolamento de nucleo","Arriscado"),
        }),
        new(IconService.Symbols.Wifi, "Rede", new[]
        {
            new MenuAction("30","DNS Google","Usa DNS Google (8.8.8.8)","Seguro"),
            new MenuAction("31","DNS Cloudflare","Usa DNS Cloudflare (1.1.1.1)","Seguro"),
            new MenuAction("32","DNS OpenDNS","Usa DNS OpenDNS","Seguro"),
            new MenuAction("33","DNS Quad9","Usa DNS Quad9 (9.9.9.9)","Seguro"),
            new MenuAction("34","DNS AdGuard","Usa DNS AdGuard","Seguro"),
            new MenuAction("35","DNS Automatico","Volta ao DNS do roteador (DHCP)","Seguro"),
            new MenuAction("36","Rede Completa","Varias otimizacoes de rede de uma vez","Moderado"),
            new MenuAction("59","Otimizar Internet","Desativa algoritmo Nagle (latencia)","Moderado"),
        }),
        new(IconService.Symbols.PaintBrush, "Visual", new[]
        {
            new MenuAction("70","Modo Escuro","Ativa o tema escuro no Windows","Seguro"),
            new MenuAction("71","Extensoes","Mostra extensoes de arquivo","Seguro"),
            new MenuAction("72","Ocultos","Mostra arquivos/pastas ocultos","Seguro"),
            new MenuAction("73","Detalhes Tela Azul","Exibe detalhes em BSoD","Seguro"),
            new MenuAction("74","Bateria %","Mostra % da bateria na barra","Seguro"),
            new MenuAction("75","Barras Rolagem","Barras de rolagem sempre visiveis","Seguro"),
            new MenuAction("48","Modo Jogo","Ativa o modo jogo do Windows","Seguro"),
            new MenuAction("49","Barra de Jogos","Desativa a barra de jogos","Seguro"),
            new MenuAction("56","Acelerar Video","Agendamento GPU por hardware","Seguro"),
            new MenuAction("58","Alto Desempenho","Plano de energia alto desempenho","Seguro"),
            new MenuAction("77","Corrigir Travamentos","Desativa MPO (travamentos video)","Moderado"),
        }),
        new(IconService.Symbols.Shield, "Privacidade", new[]
        {
            new MenuAction("86","Telemetria","Desativa coleta de dados do Windows","Seguro"),
            new MenuAction("87","Cortana","Desativa a assistente Cortana","Moderado"),
            new MenuAction("88","Localizacao","Desativa servico de localizacao","Seguro"),
            new MenuAction("89","Anuncios","Bloqueia ID de publicidade","Seguro"),
            new MenuAction("90","Compart. Wi-Fi","Desativa Wi-Fi Sense","Seguro"),
            new MenuAction("91","Ativ. Voz","Desativa ativacao por voz","Seguro"),
            new MenuAction("92","Bloquear Rastreadores","Adiciona telemetria ao arquivo Hosts","Seguro"),
            new MenuAction("93","Desat. Atualizacoes","Desativa Windows Update (isolado)","Arriscado"),
            new MenuAction("94","Remover Conta MS","Remove conta Microsoft do login","Moderado"),
            new MenuAction("95","Desativar Antivirus","Desativa Windows Defender","Arriscado"),
        }),
        new(IconService.Symbols.Gear, "Sistema", new[]
        {
            new MenuAction("52","Desfazer Servicos","Restaura servicos do Windows","Seguro"),
            new MenuAction("53","Desfazer Rede","Restaura configuracoes de rede","Seguro"),
            new MenuAction("54","Desfazer Visual","Restaura visuais anteriores","Seguro"),
            new MenuAction("55","Desfazer Privacidade","Restaura privacidade anterior","Seguro"),
            new MenuAction("60","Backup","Cria ponto de restauracao do sistema","Seguro"),
            new MenuAction("61","Restaurar","Abre restauracao do sistema","Seguro"),
            new MenuAction("41","Plano de Energia","Altera plano de energia","Seguro"),
            new MenuAction("67","Rotina Completa","Limpeza + servicos + rede + visual","Moderado"),
        }),
        new(IconService.Symbols.Game, "FiveM", new[]
        {
            new MenuAction("17","Limpar Cache FiveM","Remove cache do jogo FiveM (GTA RP)","Seguro"),
        }),
    };

    public const string NomeCategoriaInstalador = "Instalador";

    // ============================================================
    // CONTROLES ESTRUTURAIS
    // ============================================================

    private readonly TableLayoutPanel _root = new();
    private readonly Panel _sidebar = new();
    private readonly Panel _content = new();
    private readonly FlowLayoutPanel _grid;
    private readonly TLSearchBox _search;
    private readonly Label _title = new();
    private readonly Label _subtitle = new();
    private readonly Panel _installerPanel = new();
    private readonly FlowLayoutPanel _installerGrid;
    private readonly TLComboBox _installerFilter = new();
    private readonly TLSearchBox _installerSearch;

    private readonly Dictionary<string, NavItem> _nav = new();
    private string _categoriaAtiva = "";

    // Instalador
    private readonly HashSet<string> _installerSelecionados = new();
    private readonly Dictionary<string, bool> _installerEstado = new();
    private readonly Dictionary<string, (TLCard card, Label estado, TLAvatar avatar)> _installerCards = new();
    private string _installerUltimaChave = "";
    private string _installerGerenciador = InstallerManager.Winget;

    // Dashboard de métricas
    private readonly TLProgressRing _metricCpu = new();
    private readonly TLProgressRing _metricRam = new();
    private readonly TLProgressRing _metricDisk = new();
    private readonly TLProgressRing _metricApps = new();
    private readonly Label _metricCpuValue = new();
    private readonly Label _metricRamValue = new();
    private readonly Label _metricDiskValue = new();
    private readonly Label _metricAppsValue = new();
    private readonly System.Windows.Forms.Timer _metricsTimer = new() { Interval = 1500 };
    private readonly System.Windows.Forms.Timer _sysTimer = new() { Interval = 5000 };
    private PerformanceCounter? _cpuCounter;
    private PerformanceCounter? _diskCounter;
    private PerformanceCounter? _ramCounter;

    // Sys info
    private readonly Label _sysInfo = new();

    // Log + status
    private readonly RichTextBox _log = new();
    private readonly Label _status = new();

    // Diagnóstico FiveM
    private DiagData? _diagCache;
    private string? _detectedFiveMPath;
    private string? _detectedGtaVPath;

    private readonly IDisposable? _themeSub;

    public MainForm()
    {
        Text = "TL Optimizer";
        Size = new Size(1120, 720);
        MinimumSize = new Size(920, 600);
        BackColor = Tokens.Color.BgPrimary;
        ForeColor = Tokens.Color.TextPrimary;
        Font = Tokens.Font.Create(Tokens.Font.MD);
        Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        EnableDoubleBuffer(this);

        _grid = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.XXL, Tokens.Space.XXXL, Tokens.Space.XXL),
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight
        };
        _grid.EnableDoubleBuffer();

        _installerGrid = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.LG, Tokens.Space.XXXL, Tokens.Space.XXL),
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight
        };
        _installerGrid.EnableDoubleBuffer();

        _search = new TLSearchBox { Placeholder = "Buscar ação..." };
        _installerSearch = new TLSearchBox { Placeholder = "Buscar aplicativo..." };

        BuildSidebar();
        BuildContentHeader();
        BuildInstallerPanel();

        // ======= LOG + STATUS (rodapé) =======
        _log.Dock = DockStyle.Bottom;
        _log.Height = 130;
        _log.ReadOnly = true;
        _log.BackColor = Tokens.Color.BgPrimary;
        _log.ForeColor = Tokens.Color.TextSecondary;
        _log.BorderStyle = BorderStyle.None;
        _log.Font = new Font("Consolas", 9.5F, FontStyle.Regular);

        _status.Dock = DockStyle.Bottom;
        _status.Height = 28;
        _status.Text = "Pronto.";
        _status.ForeColor = Tokens.Color.TextSecondary;
        _status.TextAlign = ContentAlignment.MiddleLeft;
        _status.Padding = new Padding(Tokens.Space.MD, 0, 0, 0);

        // ======= ROOT (sidebar | conteúdo) =======
        _root.Dock = DockStyle.Fill;
        _root.ColumnCount = 2;
        _root.RowCount = 1;
        _root.BackColor = Tokens.Color.BgPrimary;
        _root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 248));
        _root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        _root.Controls.Add(_sidebar, 0, 0);
        _root.Controls.Add(_content, 1, 0);
        _root.Controls.Add(_installerPanel, 1, 0);
        _installerPanel.Visible = false;

        // ======= MONTAGEM FINAL =======
        Controls.Add(_root);
        Controls.Add(_status);
        Controls.Add(_log);

        SelectCategory("Limpeza");
        AppendLog("TL Optimizer iniciado.");

        InitMetrics();

        // Mudança de tema → redesenha a tela atual inteira
        _themeSub = ThemeManager.Subscribe(_ => RedrawCurrentView());

        Load += (s, e) =>
        {
            RefreshSysInfo();
            _sysTimer.Tick += (_, _) => RefreshSysInfo();
            _sysTimer.Start();
            BeginInvoke(CheckUpdatesBackground);
            Task.Run(() =>
            {
                DetectarPastas();
                ColetarDadosDiagnostico();
            });
        };
    }

    private void RedrawCurrentView()
    {
        SelectCategory(_categoriaAtiva);
        Invalidate(true);
    }

    // ============================================================
    // SIDEBAR
    // ============================================================

    private void BuildSidebar()
    {
        _sidebar.Dock = DockStyle.Fill;
        _sidebar.BackColor = Tokens.Color.BgPanel;
        _sidebar.AutoScroll = true;
        _sidebar.Paint += (s, e) =>
        {
            var g = e.Graphics;
            using var br = new LinearGradientBrush(
                new Rectangle(0, 0, _sidebar.Width, _sidebar.Height),
                Tokens.Helpers.Darken(Tokens.Color.BgPanel, 0.03f),
                Tokens.Color.BgHover,
                LinearGradientMode.Vertical);
            g.FillRectangle(br, 0, 0, _sidebar.Width, _sidebar.Height);
        };

        // Brand
        var brandPanel = new Panel { Dock = DockStyle.Top, Height = 88, BackColor = Color.Transparent };
        brandPanel.Paint += (s, e) =>
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            var rect = new Rectangle(Tokens.Space.XL, 24, 32, 32);
            using var grad = new LinearGradientBrush(rect,
                Tokens.Color.AccentPrimary, Tokens.Helpers.Lighten(Tokens.Color.AccentHover, 0.15f),
                LinearGradientMode.ForwardDiagonal);
            using var path = GraphicsExtensions.RoundedRect(rect, Tokens.Radius.MD);
            g.FillPath(grad, path);
            using var font = new Font(Tokens.Font.Family, 13F, FontStyle.Bold, GraphicsUnit.Pixel);
            using var brush = new SolidBrush(Tokens.Color.TextOnAccent);
            g.DrawString("TL", font, brush, rect.X + rect.Width / 2 - 12, rect.Y + rect.Height / 2 - 10);
        };
        var brand = new Label
        {
            Text = "TL OPTIMIZER",
            Location = new Point(64, 18),
            AutoSize = true,
            ForeColor = Tokens.Color.TextPrimary,
            Font = Tokens.Font.Create(Tokens.Font.XL),
        };
        var brandSub = new Label
        {
            Text = "Windows · v" + AppConfig.LauncherVersion,
            Location = new Point(66, 46),
            AutoSize = true,
            ForeColor = Tokens.Color.TextMuted,
            Font = Tokens.Font.Create(Tokens.Font.XS),
        };
        brandPanel.Controls.AddRange(new Control[] { brand, brandSub });

        // Navegação das categorias
        foreach (var cat in _menuCategorias)
            AddNavItem(cat.Cat, cat.Icon);

        // Separador
        var sep = new Panel
        {
            Dock = DockStyle.Top,
            Height = 1,
            Margin = new Padding(Tokens.Space.LG, 4, Tokens.Space.LG, 8),
            BackColor = Color.Transparent
        };
        sep.Paint += (_, e) =>
        {
            using var pen = new Pen(Tokens.Helpers.WithAlpha(Tokens.Color.BorderSubtle, 120), 1);
            e.Graphics.DrawLine(pen, 0, 0, sep.Width, 0);
        };
        _sidebar.Controls.Add(sep);

        // Instalador
        AddNavItem(NomeCategoriaInstalador, IconService.Symbols.Download);

        // Rodapé: botão de atualização
        var updateItem = new NavItem
        {
            Icon = IconService.Symbols.Alert,
            TextLabel = "Verificar atualizações",
            Dock = DockStyle.Bottom,
            Height = 44,
            Tag = "_update"
        };
        updateItem.ItemClicked += (_, _) => CheckForUpdatesNow();
        _sidebar.Controls.Add(updateItem);

        // Marca no topo — adicionada por último porque o dock processa a coleção
        // na ordem inversa (último adicionado = primeiro posicionado no topo).
        _sidebar.Controls.Add(brandPanel);
    }

    private void AddNavItem(string cat, Symbol icon)
    {
        var item = new NavItem
        {
            Icon = icon,
            TextLabel = cat,
            Dock = DockStyle.Top,
            Height = 44,
            Tag = cat,
            Selected = cat == _categoriaAtiva
        };
        var c = cat;
        item.ItemClicked += (_, _) => SelectCategory(c);
        _nav[cat] = item;
        _sidebar.Controls.Add(item);
    }

    // ============================================================
    // HEADER DE CONTEÚDO (título + busca + sistema)
    // ============================================================

    private void BuildContentHeader()
    {
        _content.Dock = DockStyle.Fill;
        _content.BackColor = Tokens.Color.BgPrimary;

        var header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 168,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.XL, Tokens.Space.XXXL, Tokens.Space.SM)
        };

        _title.Text = "Limpeza";
        _title.AutoSize = true;
        _title.Location = new Point(0, 6);
        _title.ForeColor = Tokens.Color.TextPrimary;
        _title.Font = Tokens.Font.Create(Tokens.Font.XXXL);

        _subtitle.Text = "";
        _subtitle.AutoSize = true;
        _subtitle.Location = new Point(0, 44);
        _subtitle.ForeColor = Tokens.Color.TextSecondary;
        _subtitle.Font = Tokens.Font.Create(Tokens.Font.SM);

        _sysInfo.AutoSize = true;
        _sysInfo.ForeColor = Tokens.Color.TextMuted;
        _sysInfo.Font = new Font(Tokens.Font.Family, 8.5F, FontStyle.Regular);
        _sysInfo.Padding = new Padding(0);
        _sysInfo.Anchor = AnchorStyles.None;

        var themeBtn = new TLButton
        {
            ButtonSize = TLButtonSize.Small,
            Variant = TLButtonVariant.Ghost,
            Icon = IconService.Symbols.Theme,
            Text = "",
            Width = 40,
            Height = 36
        };
        var themeTip = new ToolTip { ShowAlways = true, AutomaticDelay = 700 };
        themeTip.SetToolTip(themeBtn, "Alternar tema");
        themeBtn.Click += (_, _) => ThemeManager.Toggle();
        themeBtn.Anchor = AnchorStyles.None;

        header.Controls.AddRange(new Control[] { _title, _subtitle, _sysInfo, _search, themeBtn });

        _search.Width = 280;
        _search.Height = 40;
        _search.Anchor = AnchorStyles.None;
        _search.SearchTextChanged += (_, e) =>
        {
            if (!string.IsNullOrEmpty(_categoriaAtiva) && _categoriaAtiva != NomeCategoriaInstalador)
                RenderCards(_categoriaAtiva, e.Text ?? "");
        };
        _search.SearchCleared += (_, _) =>
        {
            if (!string.IsNullOrEmpty(_categoriaAtiva) && _categoriaAtiva != NomeCategoriaInstalador)
                RenderCards(_categoriaAtiva, "");
        };

        header.Resize += (_, _) =>
        {
            var cw = header.ClientSize.Width;
            _search.Location = new Point(cw - _search.Width - themeBtn.Width - Tokens.Space.LG, 14);

            var xTheme = cw - themeBtn.Width;
            if (xTheme < _search.Right + Tokens.Space.XS)
                xTheme = _search.Right + Tokens.Space.XS;
            themeBtn.Location = new Point(xTheme, 12);

            _sysInfo.Location = new Point(0, 84);
            _sysInfo.Visible = cw >= 620;
        };

        _content.Controls.Add(_grid);
        _content.Controls.Add(header);
    }

    // ============================================================
    // SELEÇÃO DE CATEGORIA / RENDERIZAÇÃO DE CARDS
    // ============================================================

    private void SelectCategory(string cat)
    {
        var sw = Stopwatch.StartNew();
        _categoriaAtiva = cat;

        foreach (var kv in _nav)
            kv.Value.Selected = kv.Key == cat;

        bool isInst = cat == NomeCategoriaInstalador;
        _content.Visible = !isInst;
        _installerPanel.Visible = isInst;
        _installerGrid.Visible = isInst;

        if (isInst)
        {
            _installerGrid.SuspendLayout();
            RenderInstaller();
            _installerGrid.ResumeLayout();
            return;
        }

        var found = _menuCategorias.FirstOrDefault(m => m.Cat == cat);
        _title.Text = cat;
        _subtitle.Text = found == null
            ? "0 ações"
            : cat == "FiveM"
                ? "Diagnóstico + 1 ação"
                : $"{found.Itens.Length} ações disponíveis";

        _search.Placeholder = "Buscar ação...";
        _search.Text = "";
        RenderCards(cat, "");

        sw.Stop();
        if (sw.ElapsedMilliseconds > 50)
            AppendLog($"[TIMING] SelectCategory({cat}): {sw.ElapsedMilliseconds}ms");
    }

    private void RenderCards(string cat, string filtro)
    {
        var sw = Stopwatch.StartNew();
        _grid.SuspendLayout();
        _grid.Controls.Clear();

        if (cat == "FiveM")
        {
            var sw5 = Stopwatch.StartNew();
            RenderStatusPastasEAcoes();
            sw5.Stop();
            AppendLog($"[TIMING] RenderStatusPastasEAcoes: {sw5.ElapsedMilliseconds}ms");
            RenderDiagnosticoGargalos();
        }
        else
        {
            var found = _menuCategorias.FirstOrDefault(m => m.Cat == cat);
            if (found?.Cat == null)
            {
                _grid.ResumeLayout(false);
                return;
            }

            var items = found.Itens.Where(i =>
                string.IsNullOrWhiteSpace(filtro) ||
                i.Nome.Contains(filtro, StringComparison.OrdinalIgnoreCase) ||
                i.Desc.Contains(filtro, StringComparison.OrdinalIgnoreCase)).ToArray();

            const int cardW = 260, cardH = 96;
            foreach (var it in items)
                _grid.Controls.Add(CreateCard(it, found.Icon, cardW, cardH));

            if (items.Length == 0)
            {
                var empty = CriarEstadoVazio("Nenhuma ação encontrada",
                    "Tente ajustar sua busca ou escolher outra categoria.");
                _grid.Controls.Add(empty);
            }
        }

        _grid.ResumeLayout(true);
        sw.Stop();
        if (sw.ElapsedMilliseconds > 20)
            AppendLog($"[TIMING] RenderCards({cat}): {sw.ElapsedMilliseconds}ms");
    }

    private TLCard CreateCard(MenuAction item, Symbol catIcon, int w, int h)
    {
        var info = ActionData.Get(item.Id, item.Nome, item.Desc, item.Risco);
        var state = ActionStateManager.GetState(item.Id);
        bool isOn = state.IsOn;
        string? lastExec = state.LastExecution?.ToString("dd/MM HH:mm");

        var card = new TLCard
        {
            Size = new Size(w, h),
            Elevation = 1,
            Variant = TLCardVariant.Elevated,
            Tag = item.Id,
        };
        AttackClick(card, () => MostrarDialogEAcao(item.Id, item.Nome, item.Desc, item.Risco));

        // Ícone da categoria
        var icon = IconService.GetImage(catIcon, 20, IconService.IconWeight.Regular, Tokens.Color.AccentPrimary);
        card.Controls.Add(new PictureBox
        {
            Image = icon,
            Size = new Size(20, 20),
            Location = new Point(Tokens.Space.LG, 14),
            BackColor = Color.Transparent
        });

        // Nome
        card.Controls.Add(new Label
        {
            Text = item.Nome,
            Location = new Point(44, 8),
            Size = new Size(w - 44 - 84, 24),
            ForeColor = Tokens.Color.TextPrimary,
            Font = Tokens.Font.Create(Tokens.Font.XL),
            AutoEllipsis = true,
            TextAlign = ContentAlignment.MiddleLeft
        });

        // Badge de risco
        var badge = new TLBadge { Kind = TLBadgeKind.Risk, BadgeSize = TLBadgeSize.Small };
        badge.Risk = item.Risco switch
        {
            "Arriscado" => TLRiskLevel.Risky,
            "Moderado" => TLRiskLevel.Moderate,
            _ => TLRiskLevel.Safe
        };
        badge.Text = item.Risco.ToUpper();
        badge.Width = badge.Text.Length * 7 + 18;
        badge.Height = 20;
        badge.Location = new Point(w - badge.Width - Tokens.Space.LG, 10);
        card.Controls.Add(badge);

        // Descrição
        card.Controls.Add(new Label
        {
            Text = item.Desc,
            Location = new Point(Tokens.Space.LG, 40),
            Size = new Size(w - Tokens.Space.LG * 2, 28),
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.SM),
            AutoEllipsis = true
        });

        // Status
        bool temToggle = info.HasToggle;
        string statusText = temToggle
            ? (isOn ? "●  Ativada" : "○  Desativada")
            : (state.LastExecution.HasValue ? $"✓  Hoje {lastExec}" : "○  Nunca executada");
        Color statusCor = temToggle
            ? (isOn ? Tokens.Color.AccentSuccess : Tokens.Color.StatusNeutral)
            : (state.LastExecution.HasValue ? Tokens.Color.AccentSuccess : Tokens.Color.StatusNeutral);

        card.Controls.Add(new Label
        {
            Text = statusText,
            Location = new Point(Tokens.Space.LG, h - 26),
            Size = new Size(w - Tokens.Space.LG * 2, 18),
            ForeColor = statusCor,
            Font = Tokens.Font.Create(Tokens.Font.XS),
            TextAlign = ContentAlignment.MiddleLeft
        });

        return card;
    }

    private static void AttackClick(Control parent, Action onClick)
    {
        parent.Click += (_, _) => onClick();
        foreach (Control child in parent.Controls)
        {
            child.Click += (_, _) => onClick();
            child.MouseEnter += (_, _) => parent.Invalidate();
            child.MouseLeave += (_, _) => parent.Invalidate();
        }
    }

    private static Label CriarEstadoVazio(string titulo, string descricao)
    {
        var lbl = new Label
        {
            Text = titulo + "\n" + descricao,
            AutoSize = true,
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.MD),
            Margin = new Padding(Tokens.Space.XS, Tokens.Space.LG, Tokens.Space.XS, Tokens.Space.XS),
            TextAlign = ContentAlignment.MiddleCenter,
            Padding = new Padding(0)
        };
        return lbl;
    }

    // ============================================================
    // INSTALADOR (WinGet/Chocolatey)
    // ============================================================

    private void BuildInstallerPanel()
    {
        _installerPanel.Dock = DockStyle.Fill;
        _installerPanel.BackColor = Tokens.Color.BgPrimary;

        // ---- Header: título + filtro + busca + dashboard ----
        var header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 204,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.LG, Tokens.Space.XXXL, 0)
        };

        var titulo = new Label
        {
            Text = "Gerenciador de Aplicativos",
            Location = new Point(0, 6),
            AutoSize = true,
            ForeColor = Tokens.Color.TextPrimary,
            Font = Tokens.Font.Create(Tokens.Font.XXXL)
        };
        var subtitulo = new Label
        {
            Text = "Instale, atualize e remova programas em massa.",
            Location = new Point(2, 44),
            AutoSize = true,
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.SM)
        };

        _installerFilter.DropDownStyle = ComboBoxStyle.DropDownList;
        _installerFilter.Location = new Point(0, 78);
        _installerFilter.Width = 200;
        _installerFilter.Items.Add("Todos");
        _installerFilter.Items.Add("Instalados");
        foreach (var c in InstallerManager.Categorias)
            _installerFilter.Items.Add(c);
        _installerFilter.SelectedIndex = 0;
        _installerFilter.SelectedIndexChanged += (s, e) => RenderInstaller();

        _installerSearch.Width = 260;
        _installerSearch.Height = 40;
        _installerSearch.Anchor = AnchorStyles.None;
        _installerSearch.SearchTextChanged += (_, e) => RenderInstaller();
        _installerSearch.SearchCleared += (_, _) => RenderInstaller();

        // Dashboard de métricas
        var dash = new Panel
        {
            Size = new Size(478, 92),
            Anchor = AnchorStyles.None,
            BackColor = Tokens.Color.BgPrimary
        };
        dash.Controls.AddRange(new Control[]
        {
            CreateMetricTile(_metricCpu, _metricCpuValue, "CPU", 0),
            CreateMetricTile(_metricRam, _metricRamValue, "MEMÓRIA", 116),
            CreateMetricTile(_metricDisk, _metricDiskValue, "DISCO", 232),
            CreateMetricTile(_metricApps, _metricAppsValue, "INSTALADOS", 348),
        });

        // Reposiciona busca e dashboard ao redimensionar
        header.Resize += (_, _) =>
        {
            var cw = header.ClientSize.Width;
            _installerSearch.Location = new Point(cw - _installerSearch.Width, 68);
            dash.Location = new Point(Math.Max(cw - dash.Width, 220), 78);
            dash.Visible = cw >= 700;
        };

        header.Controls.AddRange(new Control[]
        {
            titulo, subtitulo, _installerFilter, _installerSearch, dash
        });

        // ---- Barra de ações ----
        var barra = new FlowLayoutPanel
        {
            Dock = DockStyle.Top,
            Height = 52,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.SM, 0, Tokens.Space.SM),
            WrapContents = false,
            AutoSize = true
        };
        barra.Controls.Add(CriarBotaoAcao("Instalar selecionados", TLButtonVariant.Primary, IconService.Symbols.Download,
            () => InstallerAcaoEmLote("instalar")));
        barra.Controls.Add(CriarBotaoAcao("Desinstalar", TLButtonVariant.Danger, IconService.Symbols.Delete,
            () => InstallerAcaoEmLote("desinstalar")));
        barra.Controls.Add(CriarBotaoAcao("Atualizar", TLButtonVariant.Secondary, IconService.Symbols.Refresh,
            () => InstallerAcaoEmLote("atualizar")));
        barra.Controls.Add(CriarBotaoAcao("Atualizar tudo", TLButtonVariant.Outline, IconService.Symbols.Sync,
            () => InstallerAcaoEmLote("atualizar-tudo")));
        barra.Controls.Add(CriarBotaoAcao("Limpar seleção", TLButtonVariant.Ghost, IconService.Symbols.Clear,
            () => { _installerSelecionados.Clear(); RenderInstaller(); }));

        // ---- Gerenciador de pacotes ----
        var pkg = new Panel
        {
            Dock = DockStyle.Top,
            Height = 44,
            BackColor = Tokens.Color.BgPrimary,
            Padding = new Padding(Tokens.Space.XXXL, Tokens.Space.SM, Tokens.Space.XXXL, Tokens.Space.SM)
        };
        var lblPkg = new Label
        {
            Text = "Gerenciador:",
            Location = new Point(0, 12),
            AutoSize = true,
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.SM)
        };
        var btnWinget = new ToggleChip { TextLabel = "WinGet", Location = new Point(96, 6), Selected = true };
        var btnChoco = new ToggleChip { TextLabel = "Chocolatey", Location = new Point(198, 6) };
        btnWinget.ChipClicked += (_, _) =>
        {
            _installerGerenciador = InstallerManager.Winget;
            btnWinget.Selected = true;
            btnChoco.Selected = false;
            RenderInstaller();
        };
        btnChoco.ChipClicked += (_, _) =>
        {
            _installerGerenciador = InstallerManager.Chocolatey;
            btnWinget.Selected = false;
            btnChoco.Selected = true;
            RenderInstaller();
        };
        pkg.Controls.AddRange(new Control[] { lblPkg, btnWinget, btnChoco });

        _installerPanel.Controls.AddRange(new Control[] { _installerGrid, pkg, barra, header });
    }

    private TLButton CriarBotaoAcao(string texto, TLButtonVariant variante, Symbol icon, Action aoClicar)
    {
        var b = new TLButton
        {
            Text = texto,
            ButtonSize = TLButtonSize.Small,
            Variant = variante,
            Icon = icon,
            Margin = new Padding(0, 4, Tokens.Space.SM, 0),
            AutoSize = true,
            Height = 34,
        };
        b.Click += (_, _) => aoClicar();
        return b;
    }

    private Panel CreateMetricTile(TLProgressRing ring, Label value, string caption, int x)
    {
        var tile = new Panel { Size = new Size(112, 84), BackColor = Tokens.Color.BgCard, Margin = new Padding(0, 0, 4, 0) };
        tile.ApplyCardStyle(elevation: 0);
        tile.Location = new Point(x, 4);

        ring.Size = new Size(44, 44);
        ring.Location = new Point(10, 20);
        ring.ProgressColor = Tokens.Color.AccentPrimary;

        var cap = new Label
        {
            Text = caption,
            Location = new Point(60, 8),
            Size = new Size(48, 14),
            ForeColor = Tokens.Color.TextMuted,
            Font = new Font(Tokens.Font.Family, 7F, FontStyle.Bold),
            TextAlign = ContentAlignment.MiddleLeft
        };
        value.Location = new Point(60, 24);
        value.Size = new Size(48, 32);
        value.ForeColor = Tokens.Color.TextPrimary;
        value.Font = Tokens.Font.Create(Tokens.Font.XXL);
        value.TextAlign = ContentAlignment.MiddleLeft;
        value.Text = "--";

        tile.Controls.AddRange(new Control[] { ring, cap, value });
        return tile;
    }

    private void RenderInstaller()
    {
        var sw = Stopwatch.StartNew();
        if (_installerGrid is null) return;

        var filtro = _installerFilter.SelectedItem?.ToString() ?? "Todos";
        var busca = _installerSearch.Text ?? "";

        var apps = InstallerManager.Catalog.Where(a =>
            (filtro == "Todos" || filtro == "Instalados" || a.Categoria == filtro) &&
            (filtro != "Instalados" || _installerEstado.TryGetValue(a.PackageId, out var inst) && inst) &&
            (string.IsNullOrWhiteSpace(busca) || a.Nome.Contains(busca, StringComparison.OrdinalIgnoreCase))).ToArray();

        var chave = filtro + "|" + busca + "|" + _installerGerenciador + "|" +
                    string.Join(",", apps.Select(a => a.PackageId));
        if (chave == _installerUltimaChave && _installerGrid.Controls.Count > 0)
        {
            AjustarVisibilidadeInstalados();
            return;
        }
        _installerUltimaChave = chave;

        _installerGrid.SuspendLayout();
        _installerGrid.Controls.Clear();
        _installerCards.Clear();

        foreach (var app in apps)
            _installerGrid.Controls.Add(CreateAppCard(app));

        if (apps.Length == 0)
        {
            var empty = CriarEstadoVazio("Nenhum aplicativo encontrado",
                "Tente ajustar sua busca ou o filtro de categoria.");
            _installerGrid.Controls.Add(empty);
        }

        _installerGrid.ResumeLayout(true);
        _status.Text = $"{apps.Length} aplicativos | gerenciador: {_installerGerenciador}";
        sw.Stop();
        if (sw.ElapsedMilliseconds > 30)
            AppendLog($"[TIMING] RenderInstaller ({apps.Length} apps): {sw.ElapsedMilliseconds}ms");
    }

    private void AjustarVisibilidadeInstalados()
    {
        var filtro = _installerFilter.SelectedItem?.ToString() ?? "Todos";
        if (filtro != "Instalados") return;
        foreach (var kv in _installerCards)
        {
            var instalado = _installerEstado.TryGetValue(kv.Key, out var v) && v;
            kv.Value.card.Visible = instalado;
        }
    }

    private TLCard CreateAppCard(InstallerManager.AppEntry app)
    {
        const int w = 232, h = 92;
        var card = new TLCard
        {
            Size = new Size(w, h),
            Elevation = 1,
            Variant = TLCardVariant.Elevated,
            HoverLift = false,
            Tag = app.PackageId,
        };
        bool sel = _installerSelecionados.Contains(app.PackageId);
        card.Selected = sel;

        // Logo oficial ou avatar com inicial
        var logoPath = Path.Combine(AppContext.BaseDirectory, "recursos", "logos", app.PackageId + ".png");
        var avatar = new TLAvatar
        {
            AvatarSize = TLAvatarSize.Medium,
            Location = new Point(16, 26),
            StatusBadge = false,
        };
        avatar.SetFromPackageId(app.PackageId, File.Exists(logoPath) ? logoPath : null);

        // Categoria
        var cat = new TLBadge { Kind = TLBadgeKind.Category, BadgeSize = TLBadgeSize.Small, Category = app.Categoria };
        cat.Width = cat.Text.Length * 6 + 16;
        cat.Height = 16;
        cat.Location = new Point(66, 10);
        card.Controls.Add(cat);

        // Nome
        card.Controls.Add(new Label
        {
            Text = app.Nome,
            Location = new Point(66, 26),
            Size = new Size(w - 66 - 16, 22),
            ForeColor = Tokens.Color.TextPrimary,
            Font = Tokens.Font.Create(Tokens.Font.MD),
            AutoEllipsis = true,
            TextAlign = ContentAlignment.MiddleLeft
        });

        // Estado
        var estado = new Label
        {
            Text = "Verificando...",
            Location = new Point(66, 52),
            Size = new Size(w - 66 - 16, 18),
            ForeColor = Tokens.Color.TextMuted,
            Font = Tokens.Font.Create(Tokens.Font.XS),
            TextAlign = ContentAlignment.MiddleLeft
        };
        card.Controls.Add(estado);
        card.Controls.Add(avatar);
        _installerCards[app.PackageId] = (card, estado, avatar);

        AttackClick(card, () => ToggleSelecao(app, card));

        // Detecta estado em background (atualiza SÓ os controles do card)
        Task.Run(() =>
        {
            var st = InstallerManager.DetectarEstado(app, _installerGerenciador);
            if (card.IsDisposed || estado.IsDisposed || avatar.IsDisposed) return;
            var instalado = st == "Instalado";
            lock (_installerEstado) _installerEstado[app.PackageId] = instalado;
            try
            {
                Invoke(() =>
                {
                    if (card.IsDisposed || estado.IsDisposed || avatar.IsDisposed) return;
                    estado.Text = st == "Instalado" ? "Instalado"
                        : st == "NaoInstalado" ? "Não instalado"
                        : st;
                    estado.ForeColor = instalado ? Tokens.Color.AccentSuccess : Tokens.Color.TextMuted;
                    avatar.StatusBadge = instalado;
                    avatar.StatusColor = Tokens.Color.AccentSuccess;
                    if ((_installerFilter.SelectedItem?.ToString() ?? "") == "Instalados")
                        card.Visible = instalado;
                });
            }
            catch (ObjectDisposedException) { }
        });

        return card;
    }

    private void ToggleSelecao(InstallerManager.AppEntry app, TLCard card)
    {
        if (!_installerSelecionados.Remove(app.PackageId))
            _installerSelecionados.Add(app.PackageId);
        card.Selected = _installerSelecionados.Contains(app.PackageId);
        card.Invalidate();
        _status.Text = $"{_installerSelecionados.Count} selecionado(s) | gerenciador: {_installerGerenciador}";
    }

    private void InstallerAcaoEmLote(string tipo)
    {
        InstallerManager.AppEntry[] apps;
        string label;
        if (tipo == "atualizar-tudo")
        {
            apps = InstallerManager.Catalog.Where(a => _installerEstado.TryGetValue(a.PackageId, out var v) && v).ToArray();
            label = "Atualizar Tudo";
            if (apps.Length == 0) { _status.Text = "Nenhum app instalado para atualizar."; return; }
        }
        else
        {
            if (_installerSelecionados.Count == 0) { _status.Text = "Nenhum app selecionado."; return; }
            apps = InstallerManager.Catalog.Where(a => _installerSelecionados.Contains(a.PackageId)).ToArray();
            label = tipo;
        }

        var confirm = MessageBox.Show(
            $"Deseja {label.ToLower()} {apps.Length} aplicativo(s) via {_installerGerenciador}?",
            "Confirmar operação", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (confirm != DialogResult.Yes) return;

        _status.Text = $"{label} de {apps.Length} app(s) via {_installerGerenciador}...";
        AppendLog($">> {label.ToUpper()} ({apps.Length} apps) - {_installerGerenciador}");

        Task.Run(() =>
        {
            foreach (var app in apps)
            {
                Invoke(() => _status.Text = $"{label}: {app.Nome}...");
                AppendLog($"-- {app.Nome}");
                var saida = (tipo == "atualizar-tudo" || tipo == "atualizar")
                    ? InstallerManager.Atualizar(app, _installerGerenciador)
                    : tipo == "instalar"
                        ? InstallerManager.Instalar(app, _installerGerenciador)
                        : InstallerManager.Desinstalar(app, _installerGerenciador);
                Invoke(() => AppendLog(saida.Replace("\n", " | ")));
            }
            Invoke(() =>
            {
                AppendLog("----------------------------------------");
                _status.Text = $"Concluído: {label} de {apps.Length} app(s).";
                RenderInstaller();
            });
        });
    }

    // ============================================================
    // MÉTRICAS AO VIVO
    // ============================================================

    private void InitMetrics()
    {
        try { _cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total"); } catch { }
        try { _diskCounter = new PerformanceCounter("PhysicalDisk", "% Disk Time", "_Total"); } catch { }
        try { _ramCounter = new PerformanceCounter("Memory", "% Committed Bytes In Use"); } catch { }
        _metricsTimer.Tick += (s, e) => UpdateMetrics();
        _metricsTimer.Start();
        UpdateMetrics();
    }

    private void UpdateMetrics()
    {
        if (_installerPanel is null || !_installerPanel.Visible) return;
        try
        {
            double cpu = _cpuCounter?.NextValue() ?? 0;
            double ramPct = _ramCounter?.NextValue() ?? 0;
            double disk = _diskCounter?.NextValue() ?? 0;
            int instalados = _installerEstado.Count(kv => kv.Value);
            double appsPct = InstallerManager.Catalog.Length > 0
                ? Math.Min(1.0, instalados / (double)InstallerManager.Catalog.Length)
                : 0;

            Invoke(() =>
            {
                _metricCpu.SetValue((float)Math.Min(1, Math.Max(cpu, 0) / 100));
                _metricRam.SetValue((float)Math.Min(1, Math.Max(ramPct, 0) / 100));
                _metricDisk.SetValue((float)Math.Min(1, Math.Max(disk, 0) / 100));
                _metricApps.SetValue((float)appsPct);
                _metricApps.ProgressColor = Tokens.Color.AccentInfo;

                _metricCpuValue.Text = $"{Math.Max(cpu, 0):0}%";
                _metricRamValue.Text = $"{Math.Max(ramPct, 0):0}%";
                _metricDiskValue.Text = $"{Math.Min(Math.Max(disk, 0), 100):0}%";
                _metricAppsValue.Text = $"{instalados}";
            });
        }
        catch { }
    }

    // ============================================================
    // SISTEMA (informações)
    // ============================================================

    private void RefreshSysInfo()
    {
        try
        {
            var so = _soFriendlyName();
            var cpu = Environment.GetEnvironmentVariable("PROCESSOR_IDENTIFIER")?.Trim() ?? "N/A";
            var ram = new Microsoft.VisualBasic.Devices.ComputerInfo().TotalPhysicalMemory;
            var ramGb = ram / (1024.0 * 1024 * 1024);
            using var ramCounter = new PerformanceCounter("Memory", "Available MBytes");
            var ramLivre = ramCounter.NextValue() / 1024.0;
            var up = TimeSpan.FromMilliseconds(Environment.TickCount64);
            var user = Environment.UserName;
            var pc = Environment.MachineName;
            var fuso = TimeZoneInfo.Local.DisplayName;
            var gpu = _gpuName();
            var tpm = _tpmStatus();
            var net4 = _net4Status();
            var drives = DriveInfo.GetDrives()
                .Where(d => d.IsReady && d.DriveType == DriveType.Fixed)
                .Select(d =>
                {
                    var total = d.TotalSize / 1073741824.0;
                    var used = (d.TotalSize - d.AvailableFreeSpace) / 1073741824.0;
                    var pct = total > 0 ? (int)(used / total * 100) : 0;
                    var bar = _diskBar(pct);
                    return $"{d.Name.TrimEnd('\\')}: {used:F0}/{total:F0} GB {bar} {pct}%";
                }).ToArray();

            _sysInfo.Text =
                $"SO:  {so}\n" +
                $"CPU:  {cpu} ({Environment.ProcessorCount} núcleos)\n" +
                $"RAM:  {ramGb:F1} GB ({ramLivre:F1} GB livre)\n" +
                $"GPU:  {gpu}\n" +
                $"Disco: {string.Join("  |  ", drives)}\n" +
                $"Uptime: {up.Days}d {up.Hours}h  |  TPM: {tpm}  |  NET 4: {net4}\n" +
                $"Usuário: {user}  |  PC: {pc}  |  {fuso}";
        }
        catch { }
    }

    private static string _gpuName()
    {
        try
        {
            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -Command \"(Get-CimInstance Win32_VideoController).Name\"")
            { RedirectStandardOutput = true, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
            using var p = Process.Start(psi);
            if (p is null) return "N/A";
            var output = p.StandardOutput.ReadToEnd().Trim();
            return output.Length > 0 ? output.Split('\n')[0].Trim() : "N/A";
        }
        catch { return "N/A"; }
    }

    private static string _tpmStatus()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(
                @"SYSTEM\CurrentControlSet\Services\TPM");
            if (key is null) return "N/A";
            var start = key.GetValue("Start");
            if (start is int s && s == 3) return "Desativado";
            return "Ativado";
        }
        catch { return "N/A"; }
    }

    private static string _net4Status()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(
                @"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full");
            if (key is null) return "Ausente";
            var release = key.GetValue("Release");
            if (release is int r)
            {
                return r >= 533325 ? "4.8.1" :
                       r >= 528372 ? "4.8" :
                       r >= 461808 ? "4.7.2" :
                       r >= 460798 ? "4.7" : "4.x";
            }
            return "Sim";
        }
        catch { return "N/A"; }
    }

    private static string _diskBar(int pct)
    {
        var full = Math.Clamp(pct / 10, 0, 10);
        return new string('\u25CF', full) + new string('\u25CB', 10 - full);
    }

    private static string _soFriendlyName()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows NT\CurrentVersion");
            if (key is null) return Environment.OSVersion.VersionString;
            var name = (key.GetValue("ProductName") as string) ?? "Windows";
            var ed = (key.GetValue("EditionID") as string) ?? "";
            if (!string.IsNullOrEmpty(ed) && !name.Contains(ed))
                name += " " + ed;
            return name;
        }
        catch { return Environment.OSVersion.VersionString; }
    }

    // ============================================================
    // DIAGNÓSTICO DE GARGALOS FIVEM
    // ============================================================

    private sealed class DiagData
    {
        internal string CpuName = "";
        internal int CpuClock; // MHz
        internal int CpuCores;
        internal int CpuThreads;
        internal long TotalRam; // bytes
        internal string GpuName = "";
        internal long GpuVram; // bytes
        internal string GtaPath = "";
        internal int DiskMediaType = -1;
        internal int DiskBusType = -1;
    }

    private DiagData ColetarDadosDiagnostico()
    {
        var sw = Stopwatch.StartNew();
        if (_diagCache != null) return _diagCache;

        var d = new DiagData();

        try { d.TotalRam = (long)new Microsoft.VisualBasic.Devices.ComputerInfo().TotalPhysicalMemory; } catch { }

        try
        {
            var swPs = Stopwatch.StartNew();
            var script = "$ErrorActionPreference='SilentlyContinue';$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1;$gpu=Get-CimInstance Win32_VideoController|Select-Object -First 1;$n=if($cpu){$cpu.Name}else{''};$c=if($cpu){[int]$cpu.MaxClockSpeed}else{0};$r=if($cpu){[int]$cpu.NumberOfCores}else{0};$t=if($cpu){[int]$cpu.NumberOfLogicalProcessors}else{0};$gn=if($gpu){$gpu.Name}else{''};$gv=if($gpu.AdapterRAM){[long]$gpu.AdapterRAM}else{0};Write-Output ('{0}|{1}|{2}|{3}|{4}|{5}' -f $n,$c,$r,$t,$gn,$gv)";
            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -Command \"" + script + "\"")
            { RedirectStandardOutput = true, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
            using var p = Process.Start(psi);
            if (p != null)
            {
                var output = p.StandardOutput.ReadToEnd().Trim();
                var parts = output.Split('|');
                if (parts.Length >= 6)
                {
                    d.CpuName = parts[0];
                    int.TryParse(parts[1], out d.CpuClock);
                    int.TryParse(parts[2], out d.CpuCores);
                    int.TryParse(parts[3], out d.CpuThreads);
                    d.GpuName = parts[4];
                    long.TryParse(parts[5], out d.GpuVram);
                }
            }
            swPs.Stop();
            AppendLog($"[TIMING] ColetarDadosDiagnostico PS(CPU+GPU): {swPs.ElapsedMilliseconds}ms");
        }
        catch { }

        if (_detectedGtaVPath != null)
        {
            d.GtaPath = _detectedGtaVPath;
            try
            {
                var swPs = Stopwatch.StartNew();
                var dl = _detectedGtaVPath.Length >= 2 ? _detectedGtaVPath[0].ToString() : "C";
                var ds = "$ErrorActionPreference='SilentlyContinue';$dl='" + dl + "';try{$dn=(Get-Partition -DriveLetter $dl -ErrorAction SilentlyContinue|Get-Disk -ErrorAction SilentlyContinue).Number -as [int];if($dn){$ph=Get-PhysicalDisk -ErrorAction SilentlyContinue|Where-Object DeviceID -eq $dn;if($ph){Write-Output ('{0}|{1}' -f [int]$ph.MediaType,[int]$ph.BusType);exit}};Write-Output '-1|-1'}catch{Write-Output '-1|-1'}";
                var p2 = new ProcessStartInfo("powershell",
                    "-NoProfile -Command \"" + ds + "\"")
                { RedirectStandardOutput = true, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
                using var p = Process.Start(p2);
                if (p != null)
                {
                    var o = p.StandardOutput.ReadToEnd().Trim();
                    var ps = o.Split('|');
                    if (ps.Length >= 2)
                    {
                        int.TryParse(ps[0], out d.DiskMediaType);
                        int.TryParse(ps[1], out d.DiskBusType);
                    }
                }
                swPs.Stop();
                AppendLog($"[TIMING] ColetarDadosDiagnostico PS(DISCO): {swPs.ElapsedMilliseconds}ms");
            }
            catch { }
        }

        _diagCache = d;
        sw.Stop();
        AppendLog($"[TIMING] ColetarDadosDiagnostico: {sw.ElapsedMilliseconds}ms");
        return d;
    }

    private void DetectarPastas()
    {
        if (_detectedFiveMPath != null && _detectedGtaVPath != null) return;

        var fmPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "FiveM", "FiveM.app");
        _detectedFiveMPath = Directory.Exists(fmPath) ? fmPath : null;

        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(
                @"SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V");
            var regPath = key?.GetValue("InstallFolder") as string;
            if (!string.IsNullOrEmpty(regPath) && Directory.Exists(regPath))
            { _detectedGtaVPath = regPath; return; }
        }
        catch { }

        foreach (var fb in new[]
        {
            @"C:\Program Files\Rockstar Games\Grand Theft Auto V",
            @"C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V",
            @"C:\Program Files\Epic Games\GTAV",
        })
        {
            if (Directory.Exists(fb)) { _detectedGtaVPath = fb; return; }
        }
        _detectedGtaVPath = null;
    }

    private void RenderStatusPastasEAcoes()
    {
        DetectarPastas();
        int availW = Math.Max(_grid.ClientSize.Width - _grid.Padding.Left - _grid.Padding.Right, 600);
        const int cw = 260, ch = 96;

        _grid.Controls.Add(CriarHeaderSecao("Pastas do FiveM", IconService.Symbols.Folder, availW));
        _grid.Controls.Add(CriarCardPasta("Pasta FiveM", _detectedFiveMPath, cw, ch));
        _grid.Controls.Add(CriarCardPasta("Pasta GTA V", _detectedGtaVPath, cw, ch));

        _grid.Controls.Add(CriarHeaderSecao("Ações", IconService.Symbols.Play, availW, extraTop: 12));

        var actionsPnl = new Panel
        {
            Width = availW,
            Height = 48,
            BackColor = Color.Transparent,
            Margin = new Padding(0, 0, 0, 8)
        };
        actionsPnl.EnableDoubleBuffer();
        void AddBtn(string txt, string? path, int x)
        {
            var b = new TLButton
            {
                Text = txt,
                ButtonSize = TLButtonSize.Small,
                Variant = TLButtonVariant.Primary,
                Location = new Point(x, 6),
                Size = new Size(190, 36),
                Enabled = path != null
            };
            if (path != null)
                b.Click += (_, _) => Process.Start("explorer.exe", path);
            actionsPnl.Controls.Add(b);
        }
        AddBtn("Abrir pasta FiveM", _detectedFiveMPath, 0);
        AddBtn("Abrir pasta GTA V", _detectedGtaVPath, 200);
        _grid.Controls.Add(actionsPnl);
    }

    private Panel CriarHeaderSecao(string texto, Symbol icon, int availW, int extraTop = 0)
    {
        var hdr = new Panel
        {
            Width = availW,
            Height = 46,
            BackColor = Color.Transparent,
            Margin = new Padding(0, extraTop, 0, 4)
        };
        hdr.EnableDoubleBuffer();

        var img = IconService.GetImage(icon, 24, IconService.IconWeight.Regular, Tokens.Color.AccentPrimary);
        hdr.Controls.Add(new PictureBox
        {
            Image = img,
            Size = new Size(24, 24),
            Location = new Point(0, 10),
            BackColor = Color.Transparent
        });
        hdr.Controls.Add(new Label
        {
            Text = texto,
            Location = new Point(34, 10),
            AutoSize = true,
            Font = Tokens.Font.Create(Tokens.Font.XL),
            ForeColor = Tokens.Color.TextPrimary
        });
        return hdr;
    }

    private TLCard CriarCardPasta(string nome, string? caminho, int w, int h)
    {
        bool encontrada = caminho != null;
        string value = encontrada ? "Detectada" : "Não encontrada";
        string desc = encontrada ? caminho! : "Não foi possível localizar automaticamente";
        var card = new TLCard
        {
            Size = new Size(w, h),
            Elevation = 1,
            Variant = TLCardVariant.Elevated,
            HoverLift = false,
            Cursor = Cursors.Default,
            Tag = nome
        };

        var icon = IconService.GetImage(
            IconService.Symbols.Folder, 20, IconService.IconWeight.Regular,
            encontrada ? Tokens.Color.AccentSuccess : Tokens.Color.AccentDanger);
        card.Controls.Add(new PictureBox
        {
            Image = icon, Size = new Size(20, 20), Location = new Point(Tokens.Space.LG, 12), BackColor = Color.Transparent
        });

        card.Controls.Add(new Label
        {
            Text = nome,
            Location = new Point(44, 8),
            Size = new Size(w - 60, 20),
            ForeColor = Tokens.Color.TextSecondary,
            Font = new Font(Tokens.Font.Family, 8.5F, FontStyle.Regular),
            TextAlign = ContentAlignment.MiddleLeft
        });

        var lblValue = new Label
        {
            Text = value,
            Location = new Point(44, 30),
            Size = new Size(w - 60, 24),
            Font = Tokens.Font.Create(Tokens.Font.XL),
            TextAlign = ContentAlignment.MiddleLeft
        };
        lblValue.ForeColor = encontrada ? Tokens.Color.AccentSuccess : Tokens.Color.AccentDanger;
        card.Controls.Add(lblValue);

        var lblDesc = new Label
        {
            Text = desc,
            Location = new Point(Tokens.Space.LG, h - 28),
            Size = new Size(w - Tokens.Space.LG * 2, 20),
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.XS),
            AutoEllipsis = true,
            Cursor = encontrada ? Cursors.Hand : Cursors.Default
        };
        if (encontrada)
        {
            lblDesc.Click += (_, _) =>
            {
                Clipboard.SetText(caminho!);
                var orig = lblDesc.Text;
                lblDesc.Text = "Copiado!";
                var t = new System.Windows.Forms.Timer { Interval = 1500 };
                t.Tick += (_, _) => { lblDesc.Text = orig; t.Stop(); t.Dispose(); };
                t.Start();
            };
        }
        card.Controls.Add(lblDesc);

        return card;
    }

    private void RenderDiagnosticoGargalos()
    {
        var sw = Stopwatch.StartNew();
        int availW = Math.Max(_grid.ClientSize.Width - _grid.Padding.Left - _grid.Padding.Right, 600);

        var header = CriarHeaderSecao("Diagnóstico de Gargalos", IconService.Symbols.Doctor, availW);
        header.Height = 56;
        header.Controls.Add(new Label
        {
            Text = "O que pode estar limitando seu FPS no FiveM",
            Location = new Point(34, 36),
            AutoSize = true,
            Font = Tokens.Font.Create(Tokens.Font.SM),
            ForeColor = Tokens.Color.TextSecondary
        });
        _grid.Controls.Add(header);

        var data = ColetarDadosDiagnostico();

        const int cw = 260, ch = 96;
        _grid.Controls.Add(CriarCardDiagnostico("Processador", AvaliarCPU(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Memória RAM", AvaliarRAM(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Placa de Vídeo (VRAM)", AvaliarGPU(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Armazenamento do GTA V", AvaliarArmazenamento(data), cw, ch));
        sw.Stop();
        AppendLog($"[TIMING] RenderDiagnosticoGargalos: {sw.ElapsedMilliseconds}ms");
    }

    private static (string value, string desc, string status, Color cor) AvaliarCPU(DiagData data)
    {
        if (string.IsNullOrEmpty(data.CpuName))
            return ("N/A", "Não foi possível detectar o processador", "Erro", Tokens.Color.StatusNeutral);

        var label = data.CpuClock > 0
            ? $"{data.CpuName} @ {data.CpuClock} MHz"
            : data.CpuName;
        if (data.CpuCores >= 6)
            return (label, "Processador atende bem aos requisitos do FiveM", "OK", Tokens.Color.AccentSuccess);
        if (data.CpuCores >= 4 && data.CpuClock >= 3000)
            return (label, "Processador atende aos requisitos do FiveM", "OK", Tokens.Color.AccentSuccess);
        if (data.CpuCores >= 4 && data.CpuClock >= 2400)
            return (label, "Clock ou núcleos abaixo do recomendado", "Mediano", Tokens.Color.AccentWarning);

        return (label, "Processador abaixo do mínimo exigido pelo FiveM", "Gargalo", Tokens.Color.AccentDanger);
    }

    private static (string value, string desc, string status, Color cor) AvaliarRAM(DiagData data)
    {
        if (data.TotalRam <= 0)
            return ("N/A", "Não foi possível detectar a memória RAM", "Erro", Tokens.Color.StatusNeutral);

        var ramGb = data.TotalRam / (1024.0 * 1024 * 1024);
        var label = $"{ramGb:F1} GB";
        if (ramGb >= 16)
            return (label, "16 GB ou mais — suficiente para FiveM", "OK", Tokens.Color.AccentSuccess);
        if (ramGb >= 8)
            return (label, "Entre 8 e 16 GB — pode limitar em cenários pesados", "Mediano", Tokens.Color.AccentWarning);

        return (label, "Menos de 8 GB — causa travamentos e baixo FPS", "Gargalo", Tokens.Color.AccentDanger);
    }

    private static (string value, string desc, string status, Color cor) AvaliarGPU(DiagData data)
    {
        if (string.IsNullOrEmpty(data.GpuName))
            return ("N/A", "Não foi possível detectar a placa de vídeo", "Erro", Tokens.Color.StatusNeutral);

        var vramBytes = data.GpuVram;
        var vramMb = vramBytes / (1024.0 * 1024);
        var vramGb = vramBytes / (1024.0 * 1024 * 1024);

        string label;
        if (vramGb >= 1)
            label = $"{data.GpuName} ({vramGb:F1} GB)";
        else if (vramMb >= 1)
            label = $"{data.GpuName} ({vramMb:F0} MB)";
        else
            label = data.GpuName + " (VRAM não detectada)";

        if (vramGb >= 2)
            return (label, "VRAM suficiente para texturas no FiveM", "OK", Tokens.Color.AccentSuccess);
        if (vramGb >= 1)
            return (label, "VRAM limitada — pode causar travamentos ao carregar texturas", "Mediano", Tokens.Color.AccentWarning);
        if (vramMb > 0)
            return (label, "VRAM muito baixa — FiveM pode ficar injogável", "Gargalo", Tokens.Color.AccentDanger);

        return (label, "VRAM não detectada — possível placa integrada", "Mediano", Tokens.Color.AccentWarning);
    }

    private static (string value, string desc, string status, Color cor) AvaliarArmazenamento(DiagData data)
    {
        if (string.IsNullOrEmpty(data.GtaPath))
            return ("Não localizado", "Instalação do GTA V não encontrada", "Mediano", Tokens.Color.AccentWarning);

        var drive = data.GtaPath.Length >= 2 ? data.GtaPath[..2] : "";
        bool isNvme = data.DiskBusType is 9 or 17;
        bool isHdd = data.DiskMediaType == 1;

        if (isNvme)
            return ($"NVMe ({drive})", "NVMe — carregamento rápido de texturas e assets", "OK", Tokens.Color.AccentSuccess);
        if (isHdd)
            return ($"HDD ({drive})", "HDD — engasgos ao carregar texturas e streaming de assets", "Gargalo", Tokens.Color.AccentDanger);

        return ($"SSD SATA ({drive})", "SSD SATA — bom, mas NVMe traria mais desempenho", "Mediano", Tokens.Color.AccentWarning);
    }

    private TLCard CriarCardDiagnostico(string nome, (string value, string desc, string status, Color cor) info, int w, int h)
    {
        var card = new TLCard
        {
            Size = new Size(w, h),
            Elevation = 1,
            Variant = TLCardVariant.Elevated,
            HoverLift = false,
            Cursor = Cursors.Default,
            Tag = nome
        };

        var badge = new TLBadge { Kind = TLBadgeKind.Status, BadgeSize = TLBadgeSize.Small };
        badge.Status = ($"status", info.status) switch
        {
            (_, "OK") => TLStatusKind.Success,
            (_, "Mediano") => TLStatusKind.Warning,
            (_, "Gargalo") => TLStatusKind.Danger,
            _ => TLStatusKind.Neutral
        };
        badge.Text = info.status.ToUpper();
        badge.Width = badge.Text.Length * 7 + 18;
        badge.Height = 20;
        badge.Location = new Point(w - badge.Width - Tokens.Space.LG, 10);
        card.Controls.Add(badge);

        card.Controls.Add(new Label
        {
            Text = nome,
            Location = new Point(Tokens.Space.LG, 8),
            Size = new Size(w - badge.Width - 48, 20),
            ForeColor = Tokens.Color.TextSecondary,
            Font = new Font(Tokens.Font.Family, 8.5F, FontStyle.Regular),
            TextAlign = ContentAlignment.MiddleLeft
        });

        var lblValue = new Label
        {
            Text = info.value,
            Location = new Point(Tokens.Space.LG, 30),
            Size = new Size(w - Tokens.Space.LG * 2, 24),
            ForeColor = info.cor,
            Font = Tokens.Font.Create(Tokens.Font.XL),
            AutoEllipsis = true,
            TextAlign = ContentAlignment.MiddleLeft
        };
        card.Controls.Add(lblValue);

        card.Controls.Add(new Label
        {
            Text = info.desc,
            Location = new Point(Tokens.Space.LG, h - 30),
            Size = new Size(w - Tokens.Space.LG * 2, 22),
            ForeColor = Tokens.Color.TextSecondary,
            Font = Tokens.Font.Create(Tokens.Font.XS),
            AutoEllipsis = true
        });

        return card;
    }

    // ============================================================
    // AÇÕES / LOG / ATUALIZAÇÃO
    // ============================================================

    private void MostrarDialogEAcao(string id, string nome, string desc, string risco)
    {
        using var dialog = new ActionDialog(id, nome, desc, risco);
        if (dialog.ShowDialog(this) == DialogResult.OK)
        {
            var info = ActionData.Get(id, nome, desc, risco);
            if (info.HasToggle)
                ActionStateManager.SetToggle(id, dialog.ToggleResult);
            ActionStateManager.SetLastExecution(id);
            ExecuteAction(id, nome);
            RenderCards(_categoriaAtiva, _search.Text);
        }
    }

    private void ExecuteAction(string id, string nome)
    {
        _status.Text = $"Executando: {nome}...";
        AppendLog($">> {nome} (acao {id})");

        var script = AppConfig.OptimizerScriptPath;
        if (!File.Exists(script))
        {
            AppendLog("[ERRO] Script do otimizador nao encontrado.");
            _status.Text = "Erro: script ausente.";
            return;
        }

        Task.Run(() =>
        {
            var saida = PsActionRunner.RunAction(script, id);
            Invoke(() =>
            {
                AppendLog(saida);
                AppendLog("----------------------------------------");
                _status.Text = $"Concluído: {nome}.";
            });
        });
    }

    private async void CheckUpdatesBackground()
    {
        try
        {
            var handler = new HttpClientHandler { UseProxy = false };
            using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(20) };
            _status.Text = "Verificando atualizações...";
            var log = new Progress<string>(s => AppendLog(s));
            var manifest = await UpdateManager.FetchManifestAsync(client, log);
            if (manifest is not null)
            {
                var launcherUpdate = UpdateManager.CheckLauncherUpdate(manifest);
                if (launcherUpdate is not null)
                {
                    _status.Text = $"Nova versão: v{launcherUpdate.Version}";
                    var msg = $"Nova versão do TL Optimizer disponível (v{launcherUpdate.Version}).\n" +
                              $"Você está usando v{AppConfig.LauncherVersion}.\n\nDeseja atualizar agora?";
                    if (MessageBox.Show(msg, "Atualização disponível",
                            MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes)
                    {
                        _status.Text = "Atualizando...";
                        await UpdateManager.DownloadAndApplyLauncherUpdateAsync(client, launcherUpdate, log);
                        return;
                    }
                }
                _status.Text = $"Atualizando otimizador para v{manifest.Version}...";
                await UpdateManager.ApplyUpdateAsync(client, manifest, log);
            }
            _status.Text = "Pronto.";
        }
        catch (Exception ex)
        {
            AppendLog("[Update] " + ex.Message);
            _status.Text = "Pronto.";
        }
    }

    private async void CheckForUpdatesNow()
    {
        var msg = $"TL Optimizer v{AppConfig.LauncherVersion}\n\n";
        try
        {
            using var client = new HttpClient(new HttpClientHandler { UseProxy = false }) { Timeout = TimeSpan.FromSeconds(20) };
            var log = new Progress<string>(s => AppendLog(s));
            var manifest = await UpdateManager.FetchManifestAsync(client, log);
            if (manifest is not null)
            {
                var launcherUpdate = UpdateManager.CheckLauncherUpdate(manifest);
                var ultima = launcherUpdate?.Version ?? manifest.Version;
                msg += $"Última versão disponível: {ultima}\n\n";
                if (launcherUpdate is not null)
                {
                    msg += $"Nova versão do TL Optimizer disponível (v{ultima})!\n\nDeseja baixar e instalar agora?";
                    if (MessageBox.Show(msg, "Atualização disponível",
                            MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes)
                    {
                        _status.Text = "Atualizando...";
                        await UpdateManager.DownloadAndApplyLauncherUpdateAsync(client, launcherUpdate, log);
                    }
                    return;
                }
                var otimizadorAtual = UpdateManager.CompareVersions(manifest.Version, UpdateManager.GetInstalledVersion()) <= 0;
                if (!otimizadorAtual)
                {
                    msg += $"Nova versão do otimizador disponível (v{manifest.Version}). Deseja atualizar?";
                    if (MessageBox.Show(msg, "Otimizador desatualizado",
                            MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes)
                    {
                        await UpdateManager.ApplyUpdateAsync(client, manifest, log);
                    }
                    return;
                }
                msg += "O TL Optimizer está atualizado.";
            }
            else
                msg += "Não foi possível contactar o servidor de atualizações.\nVerifique sua conexão com a internet.";
        }
        catch (Exception ex)
        {
            msg += $"Erro ao verificar atualizações:\n{ex.Message}";
        }
        MessageBox.Show(msg, "TL Optimizer", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void AppendLog(string text)
    {
        if (_log.InvokeRequired) { _log.Invoke(() => AppendLog(text)); return; }
        _log.AppendText(text + Environment.NewLine);
        _log.ScrollToCaret();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _themeSub?.Dispose();
            _metricsTimer?.Stop();
            _metricsTimer?.Dispose();
            _sysTimer?.Stop();
            _sysTimer?.Dispose();
            IconService.ClearCache();
        }
        base.Dispose(disposing);
    }

    private void EnableDoubleBuffer(Control target)
    {
        typeof(Control).GetProperty("DoubleBuffered",
            System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)?
            .SetValue(target, true);
    }

    // ============================================================
    // CONTROLES AUXILIARES (NavItem / ToggleChip)
    // ============================================================

    private sealed class NavItem : Control
    {
        private Symbol _icon = Symbol.Home;
        private string _textLabel = "";
        private bool _selected;

        public Symbol Icon { get => _icon; set { _icon = value; Invalidate(); } }
        public string TextLabel { get => _textLabel; set { _textLabel = value; Invalidate(); } }
        public bool Selected { get => _selected; set { _selected = value; Invalidate(); } }

        public event EventHandler? ItemClicked;

        public NavItem()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                     ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);
            Font = Tokens.Font.Create(Tokens.Font.MD);
            Cursor = Cursors.Hand;
            MouseDown += (_, _) => ItemClicked?.Invoke(this, EventArgs.Empty);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            var hovered = ClientRectangle.Contains(PointToClient(MousePosition));
            var r = Tokens.Radius.MD;
            if (Selected || hovered)
            {
                using var brush = new SolidBrush(Selected ? Tokens.Color.AccentPrimary : Tokens.Color.BgHover);
                using var path = GraphicsExtensions.RoundedRect(new Rectangle(6, 4, Width - 12, Height - 8), r);
                g.FillPath(brush, path);
            }

            Color fg = Selected ? Tokens.Color.TextOnAccent
                : hovered ? Tokens.Color.TextPrimary
                : Tokens.Color.TextSecondary;

            var icon = IconService.GetImage(Icon, 20, IconService.IconWeight.Regular, fg);
            g.DrawImage(icon, 18, (Height - 20) / 2, 20, 20);

            TextRenderer.DrawText(g, TextLabel, Font, new Rectangle(48, 0, Width - 54, Height), fg,
                TextFormatFlags.VerticalCenter | TextFormatFlags.SingleLine |
                TextFormatFlags.NoPrefix | TextFormatFlags.EndEllipsis);
        }

        protected override void OnMouseEnter(EventArgs e) { base.OnMouseEnter(e); Invalidate(); }
        protected override void OnMouseLeave(EventArgs e) { base.OnMouseLeave(e); Invalidate(); }
    }

    private sealed class ToggleChip : Control
    {
        private string _textLabel = "";
        private bool _selected;

        public string TextLabel { get => _textLabel; set { _textLabel = value; Invalidate(); } }
        public bool Selected { get => _selected; set { _selected = value; Invalidate(); } }

        public event EventHandler? ChipClicked;

        public ToggleChip()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                     ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);
            Size = new Size(96, 28);
            Font = Tokens.Font.Create(Tokens.Font.SM);
            Cursor = Cursors.Hand;
            MouseDown += (_, _) => ChipClicked?.Invoke(this, EventArgs.Empty);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            using var path = GraphicsExtensions.RoundedRect(new Rectangle(0, 0, Width - 1, Height - 1), Tokens.Radius.Full);
            using (var brush = new SolidBrush(Selected ? Tokens.Color.TextPrimary : Tokens.Color.BgCard))
                g.FillPath(brush, path);
            using (var pen = new Pen(Selected ? Tokens.Color.TextPrimary : Tokens.Color.BorderSubtle, 1))
                g.DrawPath(pen, path);

            TextRenderer.DrawText(g, TextLabel, Font, ClientRectangle,
                Selected ? Tokens.Color.TextInverse : Tokens.Color.TextSecondary,
                TextFormatFlags.VerticalCenter | TextFormatFlags.HorizontalCenter |
                TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
        }
    }
}