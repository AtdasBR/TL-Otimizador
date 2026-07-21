using System.Drawing;
using System.Drawing.Drawing2D;
using System.Diagnostics;
using System.Net.Http;

namespace TLOptimizer.Launcher;

/// <summary>
/// Janela principal do app (WinForms nativo) com visual moderno:
/// sidebar de navegacao, header com busca, grade de cards arredondados
/// com sombra e hover suave. Tudo em preto / branco / cinza.
/// </summary>
public partial class MainForm : Form
{
    private readonly RichTextBox _log;
    private readonly Label _status;
    private readonly Panel _sidebar;
    private readonly Panel _content;
    private readonly TableLayoutPanel _root;
    private readonly FlowLayoutPanel _grid;
    private readonly TextBox _search;
    private readonly Label _title;
    private readonly Label _subtitle;
    private Panel _installerPanel = default!;
    private FlowLayoutPanel _installerGrid = default!;
    private ComboBox _installerFilter = default!;
    private TextBox _installerSearch = default!;
    private readonly HashSet<string> _installerSelecionados = new();

    private readonly Dictionary<string, bool> _installerEstado = new();
    private readonly Dictionary<string, (Panel card, Label estado, Panel ponto)> _installerCards = new();
    private string _installerUltimaChave = "";

    // Dashboard de métricas ao vivo (estilo Ashampoo/DefenderUI)
    private readonly Label _metricCpu = new();
    private readonly Label _metricRam = new();
    private readonly Label _metricDisk = new();
    private readonly Label _metricApps = new();
    private readonly System.Windows.Forms.Timer _metricsTimer = new() { Interval = 1500 };
    private PerformanceCounter? _cpuCounter;
    private PerformanceCounter? _diskCounter;

    // Painel de informações do sistema
    private readonly Label _sysInfo = new();
    private readonly System.Windows.Forms.Timer _sysTimer = new() { Interval = 5000 };

    private string _installerGerenciador = InstallerManager.Winget;
    private string _categoriaAtiva = "";

    // Diagnóstico de Gargalos FiveM
    private DiagData? _diagCache;
    // Paleta "pro": preto / branco / cinza com profundidade (alinhada com o setup WPF)
    private readonly Color _bg = Color.FromArgb(12, 12, 14);           // BgBrush
    private readonly Color _sidebarBg = Color.FromArgb(18, 18, 21);     // tom mais escuro para sidebar
    private readonly Color _cardBg = Color.FromArgb(30, 30, 34);        // CardBrush (#1E1E22)
    private readonly Color _cardHover = Color.FromArgb(28, 50, 80);     // BgHoverBrush (#1C3250)
    private readonly Color _line = Color.FromArgb(60, 60, 66);          // LineBrush
    private readonly Color _lineSoft = Color.FromArgb(44, 44, 49);
    private readonly Color _txt = Color.White;                          // TxtBrush
    private readonly Color _txtDim = Color.FromArgb(148, 148, 154);     // TxtDimBrush
    private readonly Color _txtFaint = Color.FromArgb(104, 104, 110);
    private readonly Color _accent = Color.FromArgb(0, 103, 192);       // BlueBrush (#0067C0)

    // Hover azul (Windows 11 accent) — aplicado em botões, pills, chips em todo o app
    private static readonly Color _hoverBlue = Color.FromArgb(0, 103, 192);       // BlueBrush
    private static readonly Color _hoverBlueLight = Color.FromArgb(0, 120, 212);  // BlueHoverBrush (#0078D4)
    private static readonly Color _hoverBlueBg = Color.FromArgb(28, 50, 80);      // BgHoverBrush (#1C3250)

    private static readonly (string Icon, string Cat, (string Id, string Nome, string Desc, string Risco)[] Itens)[] _menu = new[]
    {
        ("LIMPEZA", "Limpeza", new[]
        {
            ("11","Temp. do Windows","Apaga arquivos temporarios do sistema","Seguro"),
            ("13","Temporarios","Remove arquivos temporarios de usuario/sistema","Seguro"),
            ("10","Logs Eventos","Limpa logs do Visualizador de Eventos","Seguro"),
            ("12","Cache de Internet","Limpa cache DNS e temporarios de rede","Seguro"),
            ("14","Limpeza Extrema","Limpeza profunda (cache drivers/fontes)","Moderado"),
            ("15","Limpeza de Disco","Abre a ferramenta CleanMgr do Windows","Seguro"),
            ("16","Reparar Sistema","Executa SFC e DISM para reparar arquivos","Moderado"),
        }),
        ("AJUSTES", "Tweaks", new[]
        {
            ("1","Central de Acao","Abre o centro de notificacoes e acoes","Seguro"),
            ("3","Hibernacao","Libera espaco desligando a hibernacao","Moderado"),
            ("4","Memoria Virtual","Ajusta o arquivo de paginacao","Arriscado"),
            ("5","Tomar Posse","Adiciona Tomar Posse ao menu de contexto","Seguro"),
            ("6","Pausar Updates","Pausa atualizacoes por 30 dias","Moderado"),
            ("7","Comprimir Sistema","Comprime arquivos do sistema (CompactOS)","Moderado"),
            ("8","Remover Apps","Remove apps UWP pre-instalados","Arriscado"),
            ("18","Finalizar na Barra","Adiciona Finalizar tarefa na barra","Seguro"),
            ("19","Menu Classico","Restaura menu de contexto classico","Seguro"),
            ("27","Notificacoes","Desativa central de notificacoes","Seguro"),
            ("28","Storage Sense","Desativa sensor de armazenamento","Seguro"),
            ("29","Protecao Memoria","Desliga isolamento de nucleo","Arriscado"),
        }),
        ("REDE", "Rede", new[]
        {
            ("30","DNS Google","Usa DNS Google (8.8.8.8)","Seguro"),
            ("31","DNS Cloudflare","Usa DNS Cloudflare (1.1.1.1)","Seguro"),
            ("32","DNS OpenDNS","Usa DNS OpenDNS","Seguro"),
            ("33","DNS Quad9","Usa DNS Quad9 (9.9.9.9)","Seguro"),
            ("34","DNS AdGuard","Usa DNS AdGuard","Seguro"),
            ("35","DNS Automatico","Volta ao DNS do roteador (DHCP)","Seguro"),
            ("36","Rede Completa","Varias otimizacoes de rede de uma vez","Moderado"),
            ("59","Otimizar Internet","Desativa algoritmo Nagle (latencia)","Moderado"),
        }),
        ("VISUAL", "Visual", new[]
        {
            ("70","Modo Escuro","Ativa o tema escuro no Windows","Seguro"),
            ("71","Extensoes","Mostra extensoes de arquivo","Seguro"),
            ("72","Ocultos","Mostra arquivos/pastas ocultos","Seguro"),
            ("73","Detalhes Tela Azul","Exibe detalhes em BSoD","Seguro"),
            ("74","Bateria %","Mostra % da bateria na barra","Seguro"),
            ("75","Barras Rolagem","Barras de rolagem sempre visiveis","Seguro"),
            ("48","Modo Jogo","Ativa o modo jogo do Windows","Seguro"),
            ("49","Barra de Jogos","Desativa a barra de jogos","Seguro"),
            ("56","Acelerar Video","Agendamento GPU por hardware","Seguro"),
            ("58","Alto Desempenho","Plano de energia alto desempenho","Seguro"),
            ("77","Corrigir Travamentos","Desativa MPO (travamentos video)","Moderado"),
        }),
        ("PRIVACIDADE", "Privacidade", new[]
        {
            ("86","Telemetria","Desativa coleta de dados do Windows","Seguro"),
            ("87","Cortana","Desativa a assistente Cortana","Moderado"),
            ("88","Localizacao","Desativa servico de localizacao","Seguro"),
            ("89","Anuncios","Bloqueia ID de publicidade","Seguro"),
            ("90","Compart. Wi-Fi","Desativa Wi-Fi Sense","Seguro"),
            ("91","Ativ. Voz","Desativa ativacao por voz","Seguro"),
            ("92","Bloquear Rastreadores","Adiciona telemetria ao arquivo Hosts","Seguro"),
            ("93","Desat. Atualizacoes","Desativa Windows Update (isolado)","Arriscado"),
            ("94","Remover Conta MS","Remove conta Microsoft do login","Moderado"),
            ("95","Desativar Antivirus","Desativa Windows Defender","Arriscado"),
        }),
        ("SISTEMA", "Sistema", new[]
        {
            ("52","Desfazer Servicos","Restaura servicos do Windows","Seguro"),
            ("53","Desfazer Rede","Restaura configuracoes de rede","Seguro"),
            ("54","Desfazer Visual","Restaura visuais anteriores","Seguro"),
            ("55","Desfazer Privacidade","Restaura privacidade anterior","Seguro"),
            ("60","Backup","Cria ponto de restauracao do sistema","Seguro"),
            ("61","Restaurar","Abre restauracao do sistema","Seguro"),
            ("41","Plano de Energia","Altera plano de energia","Seguro"),
            ("67","Rotina Completa","Limpeza + servicos + rede + visual","Moderado"),
        }),
        ("FIVEM", "FiveM", new[]
        {
            ("17","Limpar Cache FiveM","Remove cache do jogo FiveM (GTA RP)","Seguro"),
            ("96","Localizar pasta do GTA V","Localiza a pasta de instalacao do Grand Theft Auto V","Seguro"),
            ("97","Localizar pasta do FiveM","Localiza a pasta do FiveM no computador","Seguro"),
        }),
    };

    private static readonly (string Icon, string Cat, (string Id, string Nome, string Desc, string Risco)[] Itens)[] _menuInstalador = new[]
    {
        ("INSTALADOR", "Instalador", new (string, string, string, string)[] { }),
    };

    public MainForm()
    {
        Text = "TL Optimizer";
        Size = new Size(1000, 700);
        MinimumSize = new Size(820, 560);
        BackColor = _bg;
        ForeColor = _txt;
        Font = new Font("Segoe UI", 10F);
        Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        DoubleBuffered = true;

        // ======= SIDEBAR =======
        _sidebar = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = _sidebarBg,
            AutoScroll = true
        };
        _sidebar.Paint += (s, e) =>
        {
            var g = e.Graphics;
            using var br = new LinearGradientBrush(new Rectangle(0, 0, _sidebar.Width, _sidebar.Height),
                Color.FromArgb(15, 15, 26), Color.FromArgb(10, 24, 54), LinearGradientMode.Vertical);
            g.FillRectangle(br, 0, 0, _sidebar.Width, _sidebar.Height);
        };
        var brandPanel = new Panel
        {
            Dock = DockStyle.Top,
            Height = 80,
            BackColor = _sidebarBg,
        };
        brandPanel.Paint += (s, e) =>
        {
            var g = e.Graphics; g.SmoothingMode = SmoothingMode.AntiAlias;
            using var path = RoundedRect(new Rectangle(24, 24, 28, 28), 8);
            using var br = new SolidBrush(Color.FromArgb(0, 103, 192));
            g.FillPath(br, path);
        };
        var brand = new Label
        {
            Text = "TL OPTIMIZER",
            Location = new Point(58, 14),
            Size = new Size(136, 28),
            ForeColor = _txt,
            Font = new Font("Segoe UI", 13.5F, FontStyle.Bold),
            TextAlign = ContentAlignment.MiddleLeft
        };
        var brandSub = new Label
        {
            Text = "Otimização · Plus",
            Location = new Point(58, 46),
            Size = new Size(136, 20),
            ForeColor = _txtFaint,
            Font = new Font("Segoe UI", 8.5F),
            TextAlign = ContentAlignment.MiddleLeft
        };
        brandPanel.Controls.AddRange(new Control[] { brand, brandSub });
        _sidebar.Controls.Add(brandPanel);

        const int navMargin = 2;
        foreach (var cat in _menu)
        {
            var item = new Label
            {
                Text = "  " + cat.Icon,
                Tag = cat.Cat,
                Height = 44,
                Dock = DockStyle.Top,
                Margin = new Padding(0, 0, 0, navMargin),
                ForeColor = _txtDim,
                Font = new Font("Segoe UI Semibold", 10.5F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(20, 0, 0, 0),
                Cursor = Cursors.Hand,
                BackColor = Color.Transparent
            };
            bool hovered = false;
            item.MouseEnter += (s, e) => { hovered = true; item.Invalidate(); };
            item.MouseLeave += (s, e) => { hovered = false; item.Invalidate(); };
            item.Paint += (s, e) => SidebarItem_Paint(item, hovered, e);
            item.Click += (s, e) => SelectCategory(cat.Cat);
            _sidebar.Controls.Add(item);
        }

        // ======= LINHA SEPARADORA =======
        var sep = new Panel
        {
            Dock = DockStyle.Top,
            Height = 1,
            Margin = new Padding(16, 4, 16, 8),
            BackColor = Color.Transparent
        };
        sep.Paint += (_, e) =>
        {
            using var pen = new Pen(Color.FromArgb(40, 120, 210), 1);
            e.Graphics.DrawLine(pen, 0, 0, sep.Width, 0);
        };
        _sidebar.Controls.Add(sep);

        // ======= SEÇÃO PRÓPRIA: INSTALADOR =======
        foreach (var cat in _menuInstalador)
        {
            var item = new Label
            {
                Text = "  " + cat.Icon,
                Tag = cat.Cat,
                Height = 44,
                Dock = DockStyle.Top,
                Margin = new Padding(0, 0, 0, navMargin),
                ForeColor = _txtDim,
                Font = new Font("Segoe UI Semibold", 10.5F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(20, 0, 0, 0),
                Cursor = Cursors.Hand,
                BackColor = Color.Transparent
            };
            bool hovered = false;
            item.MouseEnter += (s, e) => { hovered = true; item.Invalidate(); };
            item.MouseLeave += (s, e) => { hovered = false; item.Invalidate(); };
            item.Paint += (s, e) => SidebarItem_Paint(item, hovered, e);
            item.Click += (s, e) => SelectCategory(cat.Cat);
            _sidebar.Controls.Add(item);
        }

        // ======= ATUALIZAÇÃO (rodapé da sidebar) =======
        var updateItem = new Label
        {
            Dock = DockStyle.Bottom,
            Height = 44,
            Margin = new Padding(0, 8, 0, 0),
            Text = "  \u21BB Atualizar  v" + AppConfig.LauncherVersion,
            ForeColor = _txtDim,
            Font = new Font("Segoe UI", 9.5F),
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(20, 0, 0, 0),
            Cursor = Cursors.Hand,
            Tag = "_update",
            BackColor = Color.Transparent
        };
        bool updateHovered = false;
        updateItem.MouseEnter += (s, e) => { updateHovered = true; updateItem.Invalidate(); };
        updateItem.MouseLeave += (s, e) => { updateHovered = false; updateItem.Invalidate(); };
        updateItem.Paint += (s, e) => SidebarItem_Paint(updateItem, updateHovered, e);
        updateItem.Click += (s, e) => CheckForUpdatesNow();
        _sidebar.Controls.Add(updateItem);

        // ======= CONTENT (header + grid de cards) =======
        _content = new Panel { Dock = DockStyle.Fill, BackColor = _bg };

        var header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 220,
            BackColor = _bg,
            Padding = new Padding(28, 18, 28, 8)
        };
        _title = new Label
        {
            Text = "Instalador",
            Location = new Point(0, 8),
            AutoSize = true,
            ForeColor = _txt,
            Font = new Font("Segoe UI Light", 26F, FontStyle.Regular)
        };
        _subtitle = new Label
        {
            Text = "Package count available",
            Location = new Point(2, 56),
            AutoSize = true,
            ForeColor = _txtDim,
            Font = new Font("Segoe UI", 10.5F)
        };
        _search = new TextBox
        {
            Width = 240,
            Height = 30,
            BackColor = _cardBg,
            ForeColor = _txt,
            BorderStyle = BorderStyle.None,
            Font = new Font("Segoe UI", 10F),
            Text = "Buscar aplicativo..."
        };
        _search.GotFocus += (s, e) => { if (_search.Text == "Buscar aplicativo..." || _search.Text == "Buscar ação...") { _search.Text = ""; _search.ForeColor = _txt; } };
        _search.LostFocus += (s, e) => { if (string.IsNullOrWhiteSpace(_search.Text)) { _search.Text = _categoriaAtiva == "Instalador" ? "Buscar aplicativo..." : "Buscar ação..."; _search.ForeColor = _txtDim; } };
        _search.TextChanged += (s, e) => { if (!string.IsNullOrEmpty(_categoriaAtiva) && _categoriaAtiva != "Instalador") RenderCards(_categoriaAtiva, _search.Text); };
        _sysInfo = new Label
        {
            AutoSize = true,
            ForeColor = _txtDim,
            Font = new Font("Segoe UI", 9F),
            Padding = new Padding(0)
        };
        header.Controls.AddRange(new Control[] { _title, _subtitle, _search, _sysInfo });
        header.Resize += (_, _) =>
        {
            var cw = header.ClientSize.Width;
            _search.Location = new Point(cw - _search.Width - 28, 26);
            _sysInfo.Location = new Point(0, 70);
            _sysInfo.Visible = cw >= 600;
        };

        _grid = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            BackColor = _bg,
            Padding = new Padding(28, 20, 28, 20),
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight
        };
        typeof(Control).GetProperty("DoubleBuffered", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)?.SetValue(_grid, true);

        _content.Controls.AddRange(new Control[] { _grid, header });

        // ======= PAINEL DO INSTALADOR (seção própria) =======
        BuildInstallerPanel();
        InitMetrics();

        // ======= LOG + STATUS (embaixo) =======
        _log = new RichTextBox
        {
            Dock = DockStyle.Bottom,
            Height = 140,
            ReadOnly = true,
            BackColor = Color.FromArgb(10, 10, 12),
            ForeColor = Color.FromArgb(210, 210, 215),
            Font = new Font("Consolas", 9.5F),
            BorderStyle = BorderStyle.None
        };
        _status = new Label
        {
            Dock = DockStyle.Bottom,
            Height = 24,
            Text = "Pronto.",
            ForeColor = _txtDim,
            TextAlign = ContentAlignment.MiddleLeft,
            Padding = new Padding(12, 0, 0, 0)
        };

        // ======= ROOT (sidebar | content) via TableLayoutPanel — sem sobreposicao =======
        _root = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 1,
            BackColor = _bg
        };
        _root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 210));
        _root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        _root.Controls.Add(_sidebar, 0, 0);
        _root.Controls.Add(_content, 1, 0);
        _root.Controls.Add(_installerPanel!, 1, 0);
        _installerPanel!.Visible = false;

        // ======= MONTAGEM FINAL =======
        // Ordem: root (Fill) primeiro, depois status/log no rodape.
        Controls.Add(_root);
        Controls.Add(_status);
        Controls.Add(_log);
        SelectCategory("Limpeza");
        AppendLog("TL Optimizer iniciado. PowerShell roda em segundo plano (sem janela de cmd).");
        Load += (s, e) =>
        {
            RefreshSysInfo();
            _sysTimer.Tick += (_, _) => RefreshSysInfo();
            _sysTimer.Start();
            BeginInvoke(CheckUpdatesBackground);
        };
    }

    private async void CheckUpdatesBackground()
    {
        try
        {
            var handler = new HttpClientHandler { UseProxy = false };
            using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(20) };
            _status.Text = "Verificando atualizações...";
            var manifest = await UpdateManager.FetchManifestAsync(client);
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
                        await UpdateManager.DownloadAndApplyLauncherUpdateAsync(client, launcherUpdate);
                        return;
                    }
                }
                _status.Text = $"Atualizando otimizador para v{manifest.Version}...";
                await UpdateManager.ApplyUpdateAsync(client, manifest);
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
            var manifest = await UpdateManager.FetchManifestAsync(client);
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
                        await UpdateManager.DownloadAndApplyLauncherUpdateAsync(client, launcherUpdate);
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
                        await UpdateManager.ApplyUpdateAsync(client, manifest);
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

    private void RefreshSysInfo()
    {
        try
        {
            var so = Environment.OSVersion.VersionString;
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
                $"SO:  {_soFriendlyName()}\n" +
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

    private void SidebarItem_Paint(Label lbl, bool hovered, PaintEventArgs e)
    {
        var active = lbl.Tag?.ToString() == _categoriaAtiva;
        var g = e.Graphics; g.SmoothingMode = SmoothingMode.AntiAlias;

        using var path = RoundedRect(new Rectangle(6, 3, lbl.Width - 12, lbl.Height - 6), 8);

        if (active)
        {
            using var br = new SolidBrush(Color.FromArgb(0, 110, 200));
            g.FillPath(br, path);
            lbl.ForeColor = Color.White;
        }
        else if (hovered)
        {
            using var br = new SolidBrush(Color.FromArgb(28, 50, 80));
            g.FillPath(br, path);
            lbl.ForeColor = _txt;
        }
        else
        {
            lbl.ForeColor = _txtDim;
        }
    }

    private void SelectCategory(string cat)
    {
        _categoriaAtiva = cat;
        foreach (Control c in _sidebar.Controls)
            if (c is Label l && l.Tag != null)
                l.ForeColor = l.Tag.ToString() == cat ? _txt : _txtDim;

        bool isInst = cat == "Instalador";
        _content.Visible = !isInst;
        _installerPanel.Visible = isInst;
        if (isInst)
        {
            _title.Text = "Instalador";
            _subtitle.Text = $"{InstallerManager.Catalog.Length} aplicativos disponíveis";
            _search.Text = "Buscar aplicativo...";
            _search.ForeColor = _txtDim;
            RenderInstaller();
            return;
        }

        if (cat == "FiveM") _diagCache = null;

        var found = _menu.FirstOrDefault(m => m.Cat == cat);
        if (found.Cat == null) { _title.Text = cat; _subtitle.Text = "0 ações"; return; }
        _title.Text = cat;
        _subtitle.Text = cat == "FiveM" ? "Diagnóstico + 3 ações" : $"{found.Itens.Length} ações disponíveis";
        if (_search.Text == "Buscar aplicativo...")
            _search.ForeColor = _txtDim;
        _search.Text = "Buscar ação...";
        RenderCards(cat, "");
    }

    private void RenderCards(string cat, string filtro)
    {
        _grid.SuspendLayout();
        _grid.Controls.Clear();

        if (cat == "FiveM")
        {
            RenderStatusPastasEAcoes();
            RenderDiagnosticoGargalos();
        }

        var found = _menu.FirstOrDefault(m => m.Cat == cat);
        if (found.Cat == null) { _grid.ResumeLayout(false); return; }
        var items = found.Itens.Where(i =>
            string.IsNullOrWhiteSpace(filtro) ||
            filtro == "Buscar ação..." ||
            i.Nome.Contains(filtro, StringComparison.OrdinalIgnoreCase) ||
            i.Desc.Contains(filtro, StringComparison.OrdinalIgnoreCase)).ToArray();

        const int cardW = 250, cardH = 96;
        foreach (var it in items)
        {
            _grid.Controls.Add(CreateCard(it.Id, it.Nome, it.Desc, it.Risco, cardW, cardH));
        }

        if (items.Length == 0)
        {
            var empty = new Label
            {
                Text = "Nenhuma acao encontrada.",
                ForeColor = _txtDim,
                Font = new Font("Segoe UI", 11F),
                AutoSize = true,
                Margin = new Padding(4, 8, 4, 4)
            };
            _grid.Controls.Add(empty);
        }

        _grid.ResumeLayout(true);
    }

    // ======================= CARD PADRÃO =======================

    private void StyleCardContainer(Panel card)
    {
        void ForwardHover(Control c)
        {
            c.MouseEnter += (s, e) => { card.BackColor = _hoverBlueBg; card.Invalidate(); };
            c.MouseLeave += (s, e) => { card.BackColor = _cardBg; card.Invalidate(); };
            foreach (Control nested in c.Controls)
                ForwardHover(nested);
        }

        card.Paint += (s, e) =>
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using var path = RoundedRect(new Rectangle(0, 0, card.Width - 1, card.Height - 1), 12);
            g.SetClip(path);
            using var hb = new LinearGradientBrush(new Rectangle(0, 0, card.Width, 14), Color.FromArgb(38, 38, 44), Color.Transparent, 90f);
            g.FillRectangle(hb, 0, 0, card.Width, 12);
            g.ResetClip();
            g.DrawPath(new Pen(_line), path);
        };
        card.MouseEnter += (s, e) => { card.BackColor = _hoverBlueBg; card.Invalidate(); };
        card.MouseLeave += (s, e) => { card.BackColor = _cardBg; card.Invalidate(); };
        foreach (Control child in card.Controls)
            ForwardHover(child);
    }

    private (Label value, Label description) AddCardText(Panel card, int w, int h,
        string? label, string value, string description,
        string? badgeText = null, Color? badgeColor = null,
        string? statusText = null, Color? statusColor = null,
        Control? leftControl = null)
    {
        const int pad = 16;
        const int sp = 4;
        int x = pad;
        int innerW = w - pad * 2;

        if (leftControl != null)
        {
            leftControl.Location = new Point(pad, (h - leftControl.Height) / 2);
            card.Controls.Add(leftControl);
            x += leftControl.Width + 10;
            innerW = w - x - pad;
        }

        int y = pad;
        if (!string.IsNullOrEmpty(label))
        {
            card.Controls.Add(new Label
            {
                Text = label,
                Location = new Point(x, y),
                Size = new Size(innerW, 16),
                ForeColor = _txtDim,
                Font = new Font("Segoe UI", 8.5F),
                AutoEllipsis = true
            });
            y += 16 + sp;
        }

        var lblValue = new Label
        {
            Text = value,
            Location = new Point(x, y),
            Size = new Size(innerW - (badgeText != null ? 64 : 0), 20),
            ForeColor = _txt,
            Font = new Font("Segoe UI Semibold", 11F, FontStyle.Bold),
            AutoEllipsis = true
        };
        card.Controls.Add(lblValue);

        if (badgeText != null)
        {
            var bc = badgeColor ?? Color.FromArgb(60, 190, 90);
            card.Controls.Add(new Label
            {
                Text = badgeText.ToUpper(),
                Location = new Point(x + innerW - 56, y),
                Size = new Size(56, 18),
                ForeColor = bc == Color.FromArgb(230, 190, 60) ? Color.Black : Color.White,
                BackColor = bc,
                Font = new Font("Segoe UI", 7.5F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleCenter
            });
        }
        y += 20 + sp;

        int descMaxY = h - pad - (statusText != null ? 18 + sp : 0);
        var lblDesc = new Label
        {
            Text = description,
            Location = new Point(x, y),
            Size = new Size(innerW, Math.Max(descMaxY - y, 14)),
            ForeColor = _txtDim,
            Font = new Font("Segoe UI", 9F),
            AutoEllipsis = true
        };
        card.Controls.Add(lblDesc);

        if (statusText != null)
        {
            card.Controls.Add(new Label
            {
                Text = statusText,
                Location = new Point(x, descMaxY + sp),
                Size = new Size(innerW, 18),
                ForeColor = statusColor ?? Color.FromArgb(140, 140, 148),
                Font = new Font("Segoe UI Semibold", 7.5F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft
            });
        }

        return (lblValue, lblDesc);
    }

    private Panel CreateCard(string id, string nome, string desc, string risco, int w, int h)
    {
        if (id is "96" or "97")
            return CreateLocationCard(id, nome, w, h);

        var info = ActionData.Get(id, nome, desc, risco);
        var state = ActionStateManager.GetState(id);
        bool isOn = state.IsOn;
        string lastExec = state.LastExecution.HasValue ? state.LastExecution.Value.ToString("dd/MM HH:mm") : "";

        var card = new Panel
        {
            Size = new Size(w, h),
            Margin = new Padding(0, 0, 16, 16),
            Tag = id,
            BackColor = _cardBg,
            Cursor = Cursors.Hand,
        };

        string? status = info.HasToggle
            ? (isOn ? "● ATIVADA" : "○ DESATIVADA")
            : (state.LastExecution.HasValue ? $"✓ Hoje: {lastExec}" : "○ Nunca executada");
        Color statusCor = info.HasToggle
            ? (isOn ? Color.FromArgb(60, 190, 90) : Color.FromArgb(140, 140, 148))
            : (state.LastExecution.HasValue ? Color.FromArgb(60, 190, 90) : Color.FromArgb(140, 140, 148));

        Color badgeCor = risco switch
        {
            "Arriscado" => Color.FromArgb(220, 70, 70),
            "Moderado" => Color.FromArgb(230, 190, 60),
            _ => Color.FromArgb(60, 190, 90)
        };

        AddCardText(card, w, h, null, nome, desc, risco, badgeCor, status, statusCor);
        StyleCardContainer(card);

        card.Click += (s, e) => MostrarDialogEAcao(id, nome, desc, risco);
        foreach (Control child in card.Controls)
            child.Click += (s, e) => MostrarDialogEAcao(id, nome, desc, risco);

        return card;
    }

    private Panel CreateLocationCard(string id, string nome, int w, int h)
    {
        var cache = LocationDialog.Cache;
        string desc;
        if (cache.TryGetValue(id, out var path))
            desc = path != null ? "\u2713 Localizado: " + path : "\u2717 Nao encontrado";
        else
            desc = "Clique para localizar";

        var card = new Panel
        {
            Size = new Size(w, h),
            Margin = new Padding(0, 0, 16, 16),
            Tag = id,
            BackColor = _cardBg,
            Cursor = Cursors.Hand,
        };

        AddCardText(card, w, h, null, nome, desc, null, null, null, null);
        StyleCardContainer(card);

        void AbrirDialog()
        {
            using var dlg = new LocationDialog(id, nome);
            dlg.ShowDialog(this);
            RenderCards(_categoriaAtiva, _search.Text);
        }
        card.Click += (_, _) => AbrirDialog();
        foreach (Control child in card.Controls)
            child.Click += (_, _) => AbrirDialog();

        return card;
    }

    // ======================= INSTALADOR (WinGet/Chocolatey) =======================

    private void BuildInstallerPanel()
    {
        _installerPanel = new Panel { Dock = DockStyle.Fill, BackColor = _bg };

        // ---- Header: título + filtro + busca + dashboard de métricas ----
        var header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 128,
            BackColor = _bg,
            Padding = new Padding(28, 16, 28, 0)
        };
        var titulo = new Label
        {
            Text = "Gerenciador de Aplicativos",
            Location = new Point(0, 10),
            AutoSize = true,
            ForeColor = _txt,
            Font = new Font("Segoe UI Light", 24F, FontStyle.Regular)
        };
        var subtituloInst = new Label
        {
            Text = "Instale, atualize e remova programas em massa — com logos oficiais e estado em tempo real.",
            Location = new Point(2, 50),
            AutoSize = true,
            ForeColor = _txtDim,
            Font = new Font("Segoe UI", 9.5F)
        };
        _installerFilter = new ComboBox
        {
            Location = new Point(0, 84),
            Width = 200,
            FlatStyle = FlatStyle.Flat,
            BackColor = _cardBg,
            ForeColor = _txt,
            DropDownStyle = ComboBoxStyle.DropDownList,
            Font = new Font("Segoe UI", 10F)
        };
        _installerFilter.Items.Add("Todos");
        _installerFilter.Items.Add("Instalados");
        foreach (var c in InstallerManager.Categorias) _installerFilter.Items.Add(c);
        _installerFilter.SelectedIndex = 0;
        _installerFilter.SelectedIndexChanged += (s, e) => RenderInstaller();

        // Dashboard de métricas
        var dash = new Panel
        {
            Size = new Size(456, 106),
            Anchor = AnchorStyles.Top | AnchorStyles.Right,
            BackColor = _bg
        };
        dash.Controls.AddRange(new Control[]
        {
            CreateMetricTile(_metricCpu, "CPU", 14, 16),
            CreateMetricTile(_metricRam, "MEMÓRIA", 125, 16),
            CreateMetricTile(_metricDisk, "DISCO", 236, 16),
            CreateMetricTile(_metricApps, "INSTALADOS", 347, 16),
        });
        header.Controls.AddRange(new Control[] { titulo, subtituloInst, _installerFilter, dash });

        _installerSearch = new TextBox
        {
            Width = 240,
            Height = 30,
            BackColor = _cardBg,
            ForeColor = _txt,
            BorderStyle = BorderStyle.None,
            Font = new Font("Segoe UI", 10F),
            Text = "Buscar aplicativo..."
        };

        // Reposiciona search, dash e filtro ao redimensionar
        header.Resize += (_, _) =>
        {
            var cw = header.ClientSize.Width;
            _installerSearch.Location = new Point(cw - _installerSearch.Width - 28, 54);
            dash.Location = new Point(Math.Max(cw - dash.Width - 28, 220), 14);
            dash.Visible = cw >= 680;
        };
        _installerSearch.GotFocus += (s, e) => { if (_installerSearch.Text == "Buscar aplicativo...") { _installerSearch.Text = ""; _installerSearch.ForeColor = _txt; } };
        _installerSearch.LostFocus += (s, e) => { if (string.IsNullOrWhiteSpace(_installerSearch.Text)) { _installerSearch.Text = "Buscar aplicativo..."; _installerSearch.ForeColor = _txtDim; } };
        _installerSearch.TextChanged += (s, e) => RenderInstaller();
        header.Controls.AddRange(new Control[] { titulo, _installerFilter, _installerSearch });

        // ---- Barra de Ações ----
        var barra = new FlowLayoutPanel
        {
            Dock = DockStyle.Top,
            Height = 50,
            BackColor = _bg,
            Padding = new Padding(28, 8, 0, 8),
            WrapContents = false,
            AutoSize = true
        };
        barra.Controls.Add(InstallerBotao("Instalar Selecionados", Color.FromArgb(60,190,90), (s, e) => InstallerAcaoEmLote("instalar")));
        barra.Controls.Add(InstallerBotao("Desinstalar", Color.FromArgb(220,70,70), (s, e) => InstallerAcaoEmLote("desinstalar")));
        barra.Controls.Add(InstallerBotao("Atualizar", Color.FromArgb(230,190,60), (s, e) => InstallerAcaoEmLote("atualizar")));
        barra.Controls.Add(InstallerBotao("Atualizar Tudo", Color.FromArgb(0,153,204), (s, e) => InstallerAcaoEmLote("atualizar-tudo")));
        barra.Controls.Add(InstallerBotao("Limpar Selecao", _line, (s, e) => { _installerSelecionados.Clear(); RenderInstaller(); }));

        // ---- Gerenciador de Pacotes (winget/choco) ----
        var pkg = new Panel
        {
            Dock = DockStyle.Top,
            Height = 40,
            BackColor = _bg,
            Padding = new Padding(28, 6, 28, 6)
        };
        var lblPkg = new Label { Text = "Gerenciador:", Location = new Point(0, 8), AutoSize = true, ForeColor = _txtDim, Font = new Font("Segoe UI", 10F) };
        var btnWinget = InstallerChip("WinGet", true, () => { _installerGerenciador = InstallerManager.Winget; RenderInstaller(); });
        btnWinget.Location = new Point(110, 4);
        var btnChoco = InstallerChip("Chocolatey", false, () => { _installerGerenciador = InstallerManager.Chocolatey; RenderInstaller(); });
        btnChoco.Location = new Point(190, 4);
        pkg.Controls.AddRange(new Control[] { lblPkg, btnWinget, btnChoco });

        // ---- Grade de apps ----
        _installerGrid = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            BackColor = _bg,
            Padding = new Padding(28, 16, 28, 20),
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight
        };

        _installerPanel.Controls.AddRange(new Control[] { _installerGrid, pkg, barra, header });
    }

    private Button InstallerBotao(string texto, Color cor, EventHandler click)
    {
        var b = new Button
        {
            Text = texto,
            Margin = new Padding(0, 6, 8, 0),
            AutoSize = true,
            Height = 32,
            MinimumSize = new Size(78, 0),
            FlatStyle = FlatStyle.Flat,
            BackColor = cor,
            ForeColor = Color.White,
            Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
            Cursor = Cursors.Hand
        };
        b.FlatAppearance.BorderSize = 0;
        b.MouseEnter += (s, e) => b.BackColor = _hoverBlue;
        b.MouseLeave += (s, e) => b.BackColor = cor;
        b.Click += click;
        return b;
    }

    private Button InstallerChip(string texto, bool ativo, Action aoClicar)
    {
        var b = new Button
        {
            Text = texto,
            Width = 76,
            Height = 28,
            FlatStyle = FlatStyle.Flat,
            BackColor = ativo ? Color.White : _cardBg,
            ForeColor = ativo ? Color.Black : _txtDim,
            Font = new Font("Segoe UI Semibold", 9.5F, FontStyle.Bold),
            Cursor = Cursors.Hand
        };
        b.FlatAppearance.BorderSize = 1;
        b.FlatAppearance.BorderColor = _line;
        b.MouseEnter += (s, e) => { if (b.Tag == null) { b.FlatAppearance.BorderColor = _hoverBlue; b.ForeColor = _txt; } };
        b.MouseLeave += (s, e) => { if (b.Tag == null) { b.FlatAppearance.BorderColor = _line; b.ForeColor = ativo ? Color.Black : _txtDim; } };
        b.Click += (s, e) => aoClicar();
        return b;
    }

    private void RenderInstaller()
    {
        if (_installerGrid is null) return;

        var filtro = _installerFilter.SelectedItem?.ToString() ?? "Todos";
        var busca = _installerSearch.Text == "Buscar aplicativo..." ? "" : _installerSearch.Text;

        var apps = InstallerManager.Catalog.Where(a =>
            (filtro == "Todos" || filtro == "Instalados" || a.Categoria == filtro) &&
            (filtro != "Instalados" || _installerEstado.TryGetValue(a.PackageId, out var inst) && inst) &&
            (string.IsNullOrWhiteSpace(busca) || a.Nome.Contains(busca, StringComparison.OrdinalIgnoreCase))).ToArray();

        // Chave da lista atual: só recria os cards se a lista de apps mudou
        // (evita recriar a cada detecção de estado e o "piscar" da tela).
        var chave = filtro + "|" + busca + "|" + _installerGerenciador + "|" +
                    string.Join(",", apps.Select(a => a.PackageId));
        if (chave == _installerUltimaChave && _installerGrid.Controls.Count > 0)
        {
            // Somente ajusta visibilidade (filtro "Instalados" pode ter mudado via detecção)
            AjustarVisibilidadeInstalados();
            return;
        }
        _installerUltimaChave = chave;

        _installerGrid.SuspendLayout();
        _installerGrid.Controls.Clear();
        _installerCards.Clear();

        foreach (var app in apps)
        {
            var card = CreateAppCard(app);
            _installerGrid.Controls.Add(card);
        }

        if (apps.Length == 0)
        {
            _installerGrid.Controls.Add(new Label
            {
                Text = "Nenhum aplicativo encontrado.",
                ForeColor = _txtDim,
                Font = new Font("Segoe UI", 11F),
                AutoSize = true,
                Margin = new Padding(4, 8, 4, 4)
            });
        }

        _installerGrid.ResumeLayout(true);
        _status.Text = $"{apps.Length} aplicativos | gerenciador: {_installerGerenciador}";
    }

    // Apenas mostra/oculta os cards já criados quando o estado de instalação muda
    // (usado pelo filtro "Instalados"), sem reconstruir o grid.
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

    private Panel CreateAppCard(InstallerManager.AppEntry app)
    {
        const int w = 230, h = 92;
        var card = new Panel
        {
            Size = new Size(w, h),
            Margin = new Padding(0, 0, 14, 14),
            Tag = app,
            BackColor = _cardBg,
            Cursor = Cursors.Hand,
            Padding = new Padding(14)
        };
        bool sel = _installerSelecionados.Contains(app.PackageId);

        // Logo real do app (PNG em assets/logos) ou avatar com inicial como fallback
        var inicial = app.Nome.Length > 0 ? char.ToUpper(app.Nome[0]).ToString() : "?";
        var logoCor = CorDaInicial(app.Nome);
        var logoPath = Path.Combine(AppContext.BaseDirectory, "recursos", "logos", app.PackageId + ".png");
        Image? logoImg = File.Exists(logoPath) ? SafeLoadImage(logoPath) : null;

        var logo = new Panel
        {
            Location = new Point(14, 16),
            Size = new Size(40, 40),
            Tag = "logo",
            BackColor = _cardBg
        };
        logo.Paint += (s, e) =>
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using var path = RoundedRect(new Rectangle(0, 0, 39, 39), 20);
            if (logoImg is null)
            {
                // Sem logo: disco na cor derivada do nome + inicial branca
                g.FillPath(new SolidBrush(logoCor), path);
            }
            else
            {
                g.FillPath(new SolidBrush(_cardBg), path);
                g.SetClip(path);
                var sz = 36;
                g.DrawImage(logoImg, (40 - sz) / 2, (40 - sz) / 2, sz, sz);
                g.ResetClip();
                g.DrawPath(new Pen(_line, 1), path);
            }
        };
        if (logoImg is null)
        {
            var logoTxt = new Label
            {
                Text = inicial,
                Location = new Point(0, 0),
                Size = new Size(40, 40),
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 16F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleCenter
            };
            logo.Controls.Add(logoTxt);
        }

        var (_, estado) = AddCardText(card, w, h, app.Categoria, app.Nome, "Verificando...",
            leftControl: logo);

        var ponto = new Panel
        {
            Location = new Point(w - 24, 18),
            Size = new Size(10, 10),
            Visible = false,
            BackColor = Color.FromArgb(60, 190, 90)
        };
        ponto.Paint += (s, e) =>
        {
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using var path = RoundedRect(new Rectangle(0, 0, 9, 9), 5);
            g.FillPath(new SolidBrush(ponto.BackColor), path);
        };
        card.Controls.Add(ponto);
        _installerCards[app.PackageId] = (card, estado, ponto);

        StyleCardContainer(card);

        // Selection border override
        card.Paint += (s, e) =>
        {
            if (!_installerSelecionados.Contains(app.PackageId)) return;
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using var path = RoundedRect(new Rectangle(0, 0, card.Width - 1, card.Height - 1), 12);
            g.DrawPath(new Pen(Color.White, 2), path);
        };
        card.Click += (s, e) => ToggleSelecao(app, card);
        foreach (Control child in card.Controls)
            child.Click += (s, e) => ToggleSelecao(app, card);

        // Detecta estado em background (protege contra controle ja descartado).
        // Atualiza SÓ os controles do card (sem reconstruir o grid => sem piscar).
        Task.Run(() =>
        {
            var st = InstallerManager.DetectarEstado(app, _installerGerenciador);
            if (card.IsDisposed || estado.IsDisposed || ponto.IsDisposed) return;
            var instalado = st == "Instalado";
            lock (_installerEstado) _installerEstado[app.PackageId] = instalado;
            try
            {
                Invoke(() =>
                {
                    if (card.IsDisposed || estado.IsDisposed || ponto.IsDisposed) return;
                    estado.Text = st == "Instalado" ? "Instalado" : st == "NaoInstalado" ? "Nao instalado" : st;
                    ponto.Visible = instalado;
                    if ((_installerFilter.SelectedItem?.ToString() ?? "") == "Instalados")
                        card.Visible = instalado;
                });
            }
            catch (ObjectDisposedException) { }
        });

        return card;
    }

    private void ToggleSelecao(InstallerManager.AppEntry app, Panel card)
    {
        bool sel = _installerSelecionados.Contains(app.PackageId);
        if (sel) _installerSelecionados.Remove(app.PackageId);
        else _installerSelecionados.Add(app.PackageId);

        // Atualiza só a borda do card clicado (sem recriar a grade)
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
                _status.Text = $"Concluido: {label} de {apps.Length} app(s).";
                RenderInstaller();
            });
        });
    }

    private static Color CorDaInicial(string nome)
    {
        // Paleta discreta em tons de cinza/azul (tema do app), derivada do nome
        var paleta = new[]
        {
            Color.FromArgb(70, 80, 95),
            Color.FromArgb(90, 90, 100),
            Color.FromArgb(60, 100, 110),
            Color.FromArgb(100, 80, 90),
            Color.FromArgb(80, 95, 80),
            Color.FromArgb(95, 95, 110),
            Color.FromArgb(75, 85, 100),
            Color.FromArgb(110, 95, 75)
        };
        int hash = 0;
        foreach (char c in nome) hash = (hash * 31 + c) % paleta.Length;
        return paleta[(hash + paleta.Length) % paleta.Length];
    }

    // Tile de métrica para o dashboard (estilo Fluent/DefenderUI)
    private Panel CreateMetricTile(Label valueLabel, string caption, int x, int y)
    {
        var tile = new Panel
        {
            Location = new Point(x, y),
            Size = new Size(96, 74),
            BackColor = _cardBg,
            Cursor = Cursors.Default
        };

        const int pad = 16;
        tile.Controls.Add(new Label
        {
            Text = caption,
            Location = new Point(pad, 6),
            Size = new Size(64, 14),
            ForeColor = Color.FromArgb(120, 120, 126),
            Font = new Font("Segoe UI", 7.5F, FontStyle.Bold),
            TextAlign = ContentAlignment.MiddleLeft
        });
        valueLabel.Location = new Point(pad, 24);
        valueLabel.Size = new Size(64, 36);
        valueLabel.ForeColor = _txt;
        valueLabel.Font = new Font("Segoe UI Light", 20F, FontStyle.Regular);
        valueLabel.TextAlign = ContentAlignment.MiddleLeft;
        valueLabel.Text = "--";
        tile.Controls.Add(valueLabel);

        StyleCardContainer(tile);
        return tile;
    }

    private PerformanceCounter? _ramCounter;
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
            int instaled = _installerEstado.Count(kv => kv.Value);
            Invoke(() =>
            {
                _metricCpu.Text = $"{Math.Max(cpu, 0):0}%";
                _metricRam.Text = $"{Math.Max(ramPct, 0):0}%";
                _metricDisk.Text = $"{Math.Min(Math.Max(disk, 0), 100):0}%";
                _metricApps.Text = $"{instaled}";
            });
        }
        catch { }
    }

    // ======================= DIAGNÓSTICO DE GARGALOS FIVEM =======================

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
        if (_diagCache != null) return _diagCache;

        var d = new DiagData();
        try
        {
            var script = "$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1;$gpu=Get-CimInstance Win32_VideoController|Select-Object -First 1;$ram=[long](Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory;$cpuName=if($cpu){$cpu.Name}else{''};$cpuClock=if($cpu){[int]$cpu.MaxClockSpeed}else{0};$cpuCores=if($cpu){[int]$cpu.NumberOfCores}else{0};$cpuThreads=if($cpu){[int]$cpu.NumberOfLogicalProcessors}else{0};$gpuName=if($gpu){$gpu.Name}else{''};$gpuVRAM=if($gpu.AdapterRAM){[long]$gpu.AdapterRAM}else{0};$gta='';try{$gta=(Get-ItemProperty 'HKLM:\\SOFTWARE\\WOW6432Node\\Rockstar Games\\Grand Theft Auto V' -Name InstallFolder -ErrorAction Stop).InstallFolder}catch{};if(!$gta){foreach($p in 'C:\\Program Files\\Rockstar Games\\Grand Theft Auto V','C:\\Program Files (x86)\\Steam\\steamapps\\common\\Grand Theft Auto V','C:\\Program Files\\Epic Games\\GTAV'){if(Test-Path $p){$gta=$p;break}}};$dt=-1;$db=-1;if($gta){try{$dl=[System.IO.Path]::GetPathRoot($gta).TrimEnd(':').TrimEnd('\\');$dn=(Get-Partition -DriveLetter $dl|Get-Disk -ErrorAction Stop).Number;$ph=Get-PhysicalDisk|Where-Object DeviceID -eq $dn;if($ph){$dt=[int]$ph.MediaType;$db=[int]$ph.BusType}}catch{}};Write-Output ('{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}' -f $cpuName,$cpuClock,$cpuCores,$cpuThreads,$ram,$gpuName,$gpuVRAM,$gta,$dt,$db)";

            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -Command \"" + script + "\"")
            { RedirectStandardOutput = true, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };

            using var p = Process.Start(psi);
            if (p != null)
            {
                var output = p.StandardOutput.ReadToEnd().Trim();
                var parts = output.Split('|');
                if (parts.Length >= 10)
                {
                    d.CpuName = parts[0];
                    int.TryParse(parts[1], out d.CpuClock);
                    int.TryParse(parts[2], out d.CpuCores);
                    int.TryParse(parts[3], out d.CpuThreads);
                    long.TryParse(parts[4], out d.TotalRam);
                    d.GpuName = parts[5];
                    long.TryParse(parts[6], out d.GpuVram);
                    d.GtaPath = parts[7];
                    int.TryParse(parts[8], out d.DiskMediaType);
                    int.TryParse(parts[9], out d.DiskBusType);
                }
            }
        }
        catch { }

        _diagCache = d;
        return d;
    }

    // ======================= STATUS DE PASTAS FIVEM =======================

    private string? _detectedFiveMPath;
    private string? _detectedGtaVPath;

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
        const int cw = 250, ch = 96;

        var hdr = new Panel
        {
            Width = availW,
            Height = 44,
            BackColor = Color.Transparent,
            Margin = new Padding(0, 0, 0, 4)
        };
        hdr.Controls.Add(new Label
        {
            Text = "Pastas do FiveM",
            Location = new Point(0, 0),
            AutoSize = true,
            Font = new Font("Segoe UI Semibold", 16F, FontStyle.Bold),
            ForeColor = _txt
        });
        _grid.Controls.Add(hdr);

        _grid.Controls.Add(CriarCardPasta("Pasta FiveM", _detectedFiveMPath, cw, ch));
        _grid.Controls.Add(CriarCardPasta("Pasta GTA V", _detectedGtaVPath, cw, ch));

        var hdrA = new Panel
        {
            Width = availW,
            Height = 44,
            BackColor = Color.Transparent,
            Margin = new Padding(0, 8, 0, 4)
        };
        hdrA.Controls.Add(new Label
        {
            Text = "A\u00e7\u00f5es",
            Location = new Point(0, 0),
            AutoSize = true,
            Font = new Font("Segoe UI Semibold", 16F, FontStyle.Bold),
            ForeColor = _txt
        });
        _grid.Controls.Add(hdrA);

        var actionsPnl = new Panel
        {
            Width = availW,
            Height = 48,
            BackColor = Color.Transparent,
            Margin = new Padding(0, 0, 0, 8)
        };
        void AddBtn(string txt, string? path, int x)
        {
            var b = new Button
            {
                Text = txt,
                Location = new Point(x, 6),
                Size = new Size(185, 34),
                FlatStyle = FlatStyle.Flat,
                BackColor = _accent,
                ForeColor = Color.White,
                FlatAppearance = { BorderSize = 0 },
                Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
                Cursor = Cursors.Hand,
                Enabled = path != null
            };
            if (path != null)
                b.Click += (_, _) => System.Diagnostics.Process.Start("explorer.exe", path);
            actionsPnl.Controls.Add(b);
        }
        AddBtn("Abrir pasta FiveM", _detectedFiveMPath, 0);
        AddBtn("Abrir pasta GTA V", _detectedGtaVPath, 197);
        _grid.Controls.Add(actionsPnl);
    }

    private Panel CriarCardPasta(string nome, string? caminho, int w, int h)
    {
        bool encontrada = caminho != null;
        string value = encontrada ? "Detectada" : "N\u00e3o encontrada";
        string desc = encontrada ? caminho! : "N\u00e3o foi poss\u00edvel localizar automaticamente";
        Color cor = encontrada ? Color.FromArgb(60, 190, 90) : Color.FromArgb(220, 70, 70);

        var card = new Panel
        {
            Size = new Size(w, h),
            Margin = new Padding(0, 0, 16, 16),
            Tag = nome,
            BackColor = _cardBg,
            Cursor = Cursors.Default
        };

        var (lblValue, lblDesc) = AddCardText(card, w, h, nome, value, desc);
        lblValue.ForeColor = cor;

        if (encontrada)
        {
            lblDesc.ForeColor = Color.FromArgb(0, 120, 212);
            lblDesc.Cursor = Cursors.Hand;
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

        StyleCardContainer(card);
        return card;
    }

    private void RenderDiagnosticoGargalos()
    {
        int availW = Math.Max(_grid.ClientSize.Width - _grid.Padding.Left - _grid.Padding.Right, 600);
        var header = new Panel
        {
            Width = availW,
            Height = 50,
            BackColor = Color.Transparent,
            Margin = new Padding(0, 0, 0, 8)
        };
        header.Controls.Add(new Label
        {
            Text = "Diagnóstico de Gargalos",
            Location = new Point(0, 0),
            AutoSize = true,
            Font = new Font("Segoe UI Semibold", 16F, FontStyle.Bold),
            ForeColor = _txt
        });
        header.Controls.Add(new Label
        {
            Text = "O que pode estar limitando seu FPS no FiveM",
            Location = new Point(0, 26),
            AutoSize = true,
            Font = new Font("Segoe UI", 10F),
            ForeColor = _txtDim
        });
        _grid.Controls.Add(header);

        var data = ColetarDadosDiagnostico();

        const int cw = 250, ch = 96;
        _grid.Controls.Add(CriarCardDiagnostico("Processador", AvaliarCPU(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Memória RAM", AvaliarRAM(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Placa de Vídeo (VRAM)", AvaliarGPU(data), cw, ch));
        _grid.Controls.Add(CriarCardDiagnostico("Armazenamento do GTA V", AvaliarArmazenamento(data), cw, ch));
    }

    private static (string value, string desc, string status) AvaliarCPU(DiagData data)
    {
        if (string.IsNullOrEmpty(data.CpuName))
            return ("N/A", "Não foi possível detectar o processador", "Mediano");

        var label = $"{data.CpuName} @ {data.CpuClock} MHz";
        if (data.CpuCores >= 6)
            return (label, "Processador atende bem aos requisitos do FiveM", "OK");
        if (data.CpuCores >= 4 && data.CpuClock >= 3000)
            return (label, "Processador atende aos requisitos do FiveM", "OK");
        if (data.CpuCores >= 4 && data.CpuClock >= 2400)
            return (label, "Clock ou núcleos abaixo do recomendado", "Mediano");

        return (label, "Processador abaixo do mínimo exigido pelo FiveM", "Gargalo");
    }

    private static (string value, string desc, string status) AvaliarRAM(DiagData data)
    {
        var ramGb = data.TotalRam / (1024.0 * 1024 * 1024);
        var label = $"{ramGb:F1} GB";
        if (ramGb >= 16)
            return (label, "16 GB ou mais — suficiente para FiveM", "OK");
        if (ramGb >= 8)
            return (label, "Entre 8 e 16 GB — pode limitar em cenários pesados", "Mediano");

        return (label, "Menos de 8 GB — causa travamentos e baixo FPS", "Gargalo");
    }

    private static (string value, string desc, string status) AvaliarGPU(DiagData data)
    {
        if (string.IsNullOrEmpty(data.GpuName))
            return ("N/A", "Não foi possível detectar a placa de vídeo", "Mediano");

        var vramGb = data.GpuVram / (1024.0 * 1024 * 1024);
        var label = vramGb > 0 ? $"{data.GpuName} ({vramGb:F1} GB)" : data.GpuName;
        if (vramGb >= 2)
            return (label, "VRAM suficiente para texturas no FiveM", "OK");
        if (vramGb >= 1)
            return (label, "VRAM limitada — pode causar travamentos ao carregar texturas", "Mediano");

        return (label, "VRAM muito baixa — FiveM pode ficar injogável", "Gargalo");
    }

    private static (string value, string desc, string status) AvaliarArmazenamento(DiagData data)
    {
        if (string.IsNullOrEmpty(data.GtaPath))
            return ("Não localizado", "Instalação do GTA V não encontrada", "Mediano");

        var drive = data.GtaPath.Length >= 2 ? data.GtaPath[..2] : "";
        bool isNvme = data.DiskBusType is 9 or 17;
        bool isHdd = data.DiskMediaType == 1;

        if (isNvme)
            return ($"NVMe ({drive})", "NVMe — carregamento rápido de texturas e assets", "OK");
        if (isHdd)
            return ($"HDD ({drive})", "HDD — engasgos ao carregar texturas e streaming de assets", "Gargalo");

        return ($"SSD SATA ({drive})", "SSD SATA — bom, mas NVMe traria mais desempenho", "Mediano");
    }

    private Panel CriarCardDiagnostico(string nome, (string value, string desc, string status) info, int w, int h)
    {
        Color statusCor = info.status switch
        {
            "OK" => Color.FromArgb(60, 190, 90),
            "Mediano" => Color.FromArgb(230, 190, 60),
            "Gargalo" => Color.FromArgb(220, 70, 70),
            _ => _txtDim
        };

        var card = new Panel
        {
            Size = new Size(w, h),
            Margin = new Padding(0, 0, 16, 16),
            Tag = nome,
            BackColor = _cardBg,
            Cursor = Cursors.Default
        };

        var (lblValue, _) = AddCardText(card, w, h, nome, info.value, info.desc,
            badgeText: info.status, badgeColor: statusCor);
        lblValue.ForeColor = statusCor;

        StyleCardContainer(card);
        return card;
    }

    private static Image? SafeLoadImage(string path)
    {
        try
        {
            // Clone via stream para não travar o arquivo
            using var fs = new FileStream(path, FileMode.Open, FileAccess.Read);
            return Image.FromStream(fs);
        }
        catch
        {
            return null;
        }
    }

    private static GraphicsPath RoundedRect(Rectangle bounds, int radius)
    {
        var r = radius;
        var path = new GraphicsPath();
        path.AddArc(bounds.X, bounds.Y, r, r, 180, 90);
        path.AddArc(bounds.Right - r, bounds.Y, r, r, 270, 90);
        path.AddArc(bounds.Right - r, bounds.Bottom - r, r, r, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - r, r, r, 90, 90);
        path.CloseFigure();
        return path;
    }

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
                _status.Text = $"Concluido: {nome}.";
            });
        });
    }

    private void AppendLog(string text)
    {
        if (_log.InvokeRequired) { _log.Invoke(() => AppendLog(text)); return; }
        _log.AppendText(text + Environment.NewLine);
        _log.ScrollToCaret();
    }
}
