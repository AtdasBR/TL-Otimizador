using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Threading;

namespace TLOptimizer.Launcher;

/// <summary>
/// Catálogo de aplicativos e operações reais via WinGet (com fallback Chocolatey).
/// Tudo em modo headless (sem janela de console).
/// </summary>
internal static class InstallerManager
{
    public const string Winget = "winget";
    public const string Chocolatey = "choco";

    public class AppEntry
    {
        public string Id { get; set; } = "";
        public string Nome { get; set; } = "";
        public string Categoria { get; set; } = "";
        public string PackageId { get; set; } = ""; // id do winget
        public string ChocoId { get; set; } = "";   // id do choco (opcional)
        public string Estado { get; set; } = "Desconhecido"; // NaoInstalado | Instalado | Atualizavel
    }

    public static readonly AppEntry[] Catalog = new[]
    {
        // Navegadores (apenas com logo vetorial atual e ID WinGet confirmado)
        App("Google Chrome", "Navegadores", "Google.Chrome"),
        App("Mozilla Firefox", "Navegadores", "Mozilla.Firefox"),
        App("Microsoft Edge", "Navegadores", "Microsoft.Edge"),
        App("Opera", "Navegadores", "Opera.Opera"),
        App("Brave", "Navegadores", "Brave.Brave"),
        App("Chromium", "Navegadores", "Chromium.Chromium"),
        App("Firefox ESR", "Navegadores", "Mozilla.Firefox.ESR"),
        App("Floorp", "Navegadores", "Ablaze.Floorp"),
        App("LibreWolf", "Navegadores", "LibreWolf.LibreWolf"),
        App("Mullvad Browser", "Navegadores", "MullvadVPN.MullvadBrowser"),
        App("Tor Browser", "Navegadores", "TorProject.TorBrowser"),
        App("Vivaldi", "Navegadores", "Vivaldi.Vivaldi"),
        App("Waterfox", "Navegadores", "Waterfox.Waterfox"),
        App("Zen Browser", "Navegadores", "Zen.Zen"),
        // Comunicação
        App("Discord", "Comunicação", "Discord.Discord"),
        App("Slack", "Comunicação", "Slack.Slack"),
        App("Microsoft Teams", "Comunicação", "Microsoft.Teams"),
        App("Proton Mail", "Comunicação", "Proton.ProtonMail"),
        App("Dorion", "Comunicação", "Dorion.Dorion"),
        App("WhatsApp", "Comunicação", "WhatsApp.WhatsApp"),
        App("Telegram", "Comunicação", "Telegram.TelegramDesktop"),
        App("Skype", "Comunicação", "Microsoft.Skype"),
        App("Zoom", "Comunicação", "Zoom.Zoom"),
        App("Betterbird", "Comunicação", "Betterbird.Betterbird"),
        App("Chatterino", "Comunicação", "ChatterinoTeam.Chatterino"),
        App("Element", "Comunicação", "Element.Element"),
        App("Signal", "Comunicação", "OpenWhisperSystems.Signal"),
        App("TeamSpeak 3", "Comunicação", "TeamSpeakSystems.TeamSpeak"),
        App("Thunderbird", "Comunicação", "Mozilla.Thunderbird"),
        App("Vesktop", "Comunicação", "Vencord.Vesktop"),
        App("Viber", "Comunicação", "Rakuten.Viber"),
        // Desenvolvimento
        App("Visual Studio Code", "Desenvolvimento", "Microsoft.VisualStudioCode"),
        App("Git", "Desenvolvimento", "Git.Git", "git"),
        App("Node.js (LTS)", "Desenvolvimento", "OpenJS.NodeJS.LTS", "nodejs-lts"),
        App("Python", "Desenvolvimento", "Python.Python.3.12", "python"),
        App("GitHub Desktop", "Desenvolvimento", "GitHub.GitHubDesktop"),
        App("Java JDK", "Desenvolvimento", "Oracle.JavaRuntimeEnvironment", "adoptopenjdk"),
        App("Claude Desktop", "Desenvolvimento", "Anthropic.Claude"),
        App("Claude Code", "Desenvolvimento", "Anthropic.ClaudeCode"),
        App("CMake", "Desenvolvimento", "Kitware.CMake"),
        App("Cursor", "Desenvolvimento", "Anysphere.Cursor"),
        App("Go", "Desenvolvimento", "GoLang.Go"),
        App("Amazon Corretto 21 (LTS)", "Desenvolvimento", "Amazon.Corretto.21"),
        App("JetBrains Toolbox", "Desenvolvimento", "JetBrains.Toolbox"),
        App("Lazygit", "Desenvolvimento", "JesseDuffield.lazygit"),
        App("Lua", "Desenvolvimento", "Lua.Lua"),
        App("Neovim", "Desenvolvimento", "Neovim.Neovim"),
        App("NodeJS", "Desenvolvimento", "OpenJS.NodeJS"),
        App("pnpm", "Desenvolvimento", "pnpm.pnpm"),
        App("Python 3.13", "Desenvolvimento", "Python.Python.3.13"),
        App("Ruby", "Desenvolvimento", "RubyInstallerTeam.Ruby"),
        App("Rust", "Desenvolvimento", "Rustlang.Rust.MSVC"),
        App("Sublime Text", "Desenvolvimento", "SublimeHQ.SublimeText"),
        App("Unity", "Desenvolvimento", "Unity.Unity"),
        App("VS Codium", "Desenvolvimento", "VSCodium.VSCodium"),
        App("Yarn", "Desenvolvimento", "Yarn.Yarn"),
        App("Zed", "Desenvolvimento", "Zed.Zed"),
        App("Oh My Posh", "Desenvolvimento", "JanDeDobbeleer.OhMyPosh"),
        App("Astral uv", "Desenvolvimento", "Astral.uv"),
        App("System Informer", "Desenvolvimento", "SystemInformer.SystemInformer"),
        App("Visual Studio 2022", "Desenvolvimento", "Microsoft.VisualStudio.2022.Community"),
        App("Visual Studio 2026", "Desenvolvimento", "Microsoft.VisualStudio.2026.Community"),
        App("ChatGPT Desktop", "Desenvolvimento", "OpenAI.ChatGPT"),
        App("Codex", "Desenvolvimento", "OpenAI.Codex", "codex"),
        App("Codex CLI", "Desenvolvimento", "jcv8000.Codex"),
        App("Helium", "Desenvolvimento", "Helium.Helium"),
        // Jogos
        App("Steam", "Jogos", "Valve.Steam"),
        App("Epic Games", "Jogos", "EpicGames.EpicGamesLauncher"),
        App("EA App", "Jogos", "ElectronicArts.EADesktop"),
        App("GOG Galaxy", "Jogos", "GOG.Galaxy"),
        App("FiveM", "Jogos", "FiveM.FiveM"),
        // Multimídia
        App("VLC", "Multimídia", "VideoLAN.VLC"),
        App("Spotify", "Multimídia", "Spotify.Spotify"),
        App("OBS Studio", "Multimídia", "OBSProject.OBSStudio"),
        App("Audacity", "Multimídia", "Audacity.Audacity"),
        // Microsoft
        App("Microsoft Office", "Microsoft", "Microsoft.Office", "office365business"),
        // Utilitários
        App("7-Zip", "Utilitários", "7zip.7zip", "7zip"),
        App("WinRAR", "Utilitários", "RARLab.WinRAR"),
        App("Notepad++", "Utilitários", "Notepad++.Notepad++"),
        App("PowerToys", "Utilitários", "Microsoft.PowerToys"),
        App("Everything", "Utilitários", "Voidtools.Everything"),
        // Drivers
        App("DirectX", "Drivers", "Microsoft.DirectX", "directx"),
        App("Visual C++ Redist", "Drivers", "Microsoft.VCRedist.2015+.x64", "vcredist2015"),
        // Segurança
        App("Malwarebytes", "Segurança", "Malwarebytes.Malwarebytes"),
        // Ferramentas do Sistema
        App("CPU-Z", "Ferramentas do Sistema", "CPUID.CPU-Z"),
        App("HWMonitor", "Ferramentas do Sistema", "CPUID.HWMonitor"),
        App("CrystalDiskInfo", "Ferramentas do Sistema", "CrystalDewWorld.CrystalDiskInfo"),
        App("Rufus", "Ferramentas do Sistema", "Rufus.Rufus"),
        // ===== Games =====
        App("Cemu", "Games", "CE-Programming.CEmu"),
        App("GeForce NOW", "Games", "NVIDIA.GeForceNOW"),
        App("Heroic Games Launcher", "Games", "Heroic-Games-Launcher.HeroicGamesLauncher"),
        App("Itch.io", "Games", "ItchIo.Itch"),
        App("Modrinth App", "Games", "Modrinth.ModrinthApp"),
        App("Overwolf", "Games", "Overwolf.Overwolf"),
        App("Playnite", "Games", "Playnite.Playnite"),
        App("Prism Launcher", "Games", "PrismLauncher.PrismLauncher"),
        App("Ubisoft Connect", "Games", "Ubisoft.Connect"),
        App("Virtual Desktop Streamer", "Games", "VirtualDesktop.VirtualDesktopStreamer"),
        // ===== Microsoft Tools =====
        App("Autoruns", "Microsoft Tools", "Microsoft.Sysinternals.Autoruns"),
        App("DISMTools", "Microsoft Tools", "CodingWondersSoftware.DISMTools.Stable"),
        App(".NET Desktop Runtime 10", "Microsoft Tools", "Microsoft.DotNet.DesktopRuntime.10"),
        App(".NET Desktop Runtime 6", "Microsoft Tools", "Microsoft.DotNet.DesktopRuntime.6"),
        App(".NET Desktop Runtime 8", "Microsoft Tools", "Microsoft.DotNet.DesktopRuntime.8"),
        App(".NET Desktop Runtime 9", "Microsoft Tools", "Microsoft.DotNet.DesktopRuntime.9"),
        App("NTLite", "Microsoft Tools", "Nlite.NLite"),
        App("NuGet", "Microsoft Tools", "Microsoft.NuGet"),
        App("OneDrive", "Microsoft Tools", "Microsoft.OneDrive"),
        App("PowerShell", "Microsoft Tools", "Microsoft.PowerShell"),
        App("Process Explorer", "Microsoft Tools", "Microsoft.Sysinternals.ProcessExplorer"),
        App("Process Monitor", "Microsoft Tools", "Microsoft.Sysinternals.ProcessMonitor"),
        App("RDCMan", "Microsoft Tools", "Microsoft.RemoteDesktopClient.RDCman"),
        App("TCPView", "Microsoft Tools", "Microsoft.Sysinternals.TCPView"),
        App("Windows Terminal", "Microsoft Tools", "Microsoft.WindowsTerminal"),
        App("Visual C++ 2015-2022 32-bit", "Microsoft Tools", "Microsoft.VCRedist.2015+.x86", "vcredist2015"),
        // ===== Multimedia Tools =====
        App("Adobe Acrobat Reader", "Multimedia Tools", "Adobe.Acrobat.Reader.64-bit"),
        App("AIMP", "Multimedia Tools", "AIMP.AIMP"),
        App("Blender", "Multimedia Tools", "BlenderFoundation.Blender"),
        App("Calibre", "Multimedia Tools", "calibre.calibre"),
        App("EarTrumpet", "Multimedia Tools", "File-New-Project.EarTrumpet"),
        App("GIMP", "Multimedia Tools", "GIMP.GIMP"),
        App("HandBrake", "Multimedia Tools", "HandBrake.HandBrake"),
        App("ImageGlass", "Multimedia Tools", "ImageGlass.ImageGlass"),
        App("IrfanView", "Multimedia Tools", "IrfanView.IrfanView"),
        App("iTunes", "Multimedia Tools", "Apple.iTunes"),
        App("LibreOffice", "Multimedia Tools", "TheDocumentFoundation.LibreOffice"),
        App("Media Player Classic - HC", "Multimedia Tools", "clsid2.mpc-hc"),
        App("mpc-qt", "Multimedia Tools", "mpc-qt.mpc-qt"),
        App("NAPS2", "Multimedia Tools", "NAPS2.NAPS2"),
        App("nomacs", "Multimedia Tools", "nomacs.nomacs"),
        App("Obsidian", "Multimedia Tools", "Obsidian.Obsidian"),
        App("ONLYOFFICE Desktop", "Multimedia Tools", "ONLYOFFICE.DesktopEditors"),
        App("Paint.NET", "Multimedia Tools", "dotPDN.Paint.NET"),
        App("ShareX", "Multimedia Tools", "ShareX.ShareX"),
        // ===== Pro Tools =====
        App("Advanced IP Scanner", "Pro Tools", "Famatech.AdvancedIPScanner"),
        App("Angry IP Scanner", "Pro Tools", "AntonKeks.AngryIPScanner"),
        App("Cinebench R23", "Pro Tools", "Maxon.Cinebench"),
        App("Display Driver Uninstaller", "Pro Tools", "Wagnardsoft.DDU"),
        App("GPU-Z", "Pro Tools", "TechPowerUp.GPU-Z"),
        App("gsudo", "Pro Tools", "gerardog.gsudo"),
        App("HWiNFO", "Pro Tools", "REALiX.HWiNFO"),
        App("Nmap", "Pro Tools", "Insecure.Com.Nmap"),
        App("OpenVPN Connect", "Pro Tools", "OpenVPNTechnologies.OpenVPNConnect"),
        App("Proton VPN", "Pro Tools", "Proton.ProtonVPN"),
        App("Simplewall", "Pro Tools", "HenryPP.SimpleWall"),
        App("Ventoy", "Pro Tools", "Ventoy.Ventoy"),
        App("WinSCP", "Pro Tools", "WinSCP.WinSCP"),
        App("WireGuard", "Pro Tools", "WireGuard.WireGuard"),
        App("Wireshark", "Pro Tools", "WiresharkFoundation.Wireshark"),
        // ===== Selfhosted Tools =====
        App("Jellyfin Media Player", "Selfhosted Tools", "Jellyfin.JellyfinMediaPlayer"),
        App("Jellyfin Server", "Selfhosted Tools", "Jellyfin.JellyfinServer"),
        App("Kodi Media Center", "Selfhosted Tools", "Team-Kodi.Kodi"),
        App("LocalSend", "Selfhosted Tools", "LocalSend.LocalSend"),
        App("Moonlight", "Selfhosted Tools", "GracefulTee.Moonlight"),
        App("NetBird", "Selfhosted Tools", "NetBird.NetBird"),
        App("Nextcloud Desktop", "Selfhosted Tools", "Nextcloud.NextcloudDesktop"),
        App("Plex Media Server", "Selfhosted Tools", "Plex.PlexMediaServer"),
        App("Plex Desktop", "Selfhosted Tools", "Plex.Plex"),
        App("Sunshine", "Selfhosted Tools", "LizardByte.Sunshine"),
        // ===== Utilities =====
        App("1Password", "Utilities", "AgileBits.1Password"),
        App("AnyDesk", "Utilities", "AnyDesk.AnyDesk"),
        App("AutoHotkey", "Utilities", "AutoHotkey.AutoHotkey"),
        App("Bitwarden", "Utilities", "Bitwarden.Bitwarden"),
        App("BlurAutoClicker", "Utilities", "Bloop.BlurAutoClicker"),
        App("Bulk Crap Uninstaller", "Utilities", "Klocman.BulkCrapUninstaller"),
        App("Crystal Disk Mark", "Utilities", "CrystalDewWorld.CrystalDiskMark"),
        App("Deskflow", "Utilities", "Deskflow.Deskflow"),
        App("Dropbox", "Utilities", "Dropbox.Dropbox"),
        App("Ente Auth", "Utilities", "Ente.Authenticator"),
        App("Files", "Utilities", "FilesCommunity.Files"),
        App("F.lux", "Utilities", "HyperbolicSoftware.F.lux"),
        App("GlazeWM", "Utilities", "glzr-io.GlazeWM"),
        App("Google Drive", "Utilities", "Google.GoogleDrive"),
        App("Hugo", "Utilities", "GoHugo.Hugo"),
        App("Internet Download Manager", "Utilities", "Tonec.InternetDownloadManager"),
        App("JPEG View", "Utilities", "sylikc.JPEGView"),
        App("KeePassXC", "Utilities", "KeePassXCTeam.KeePassXC"),
        App("MiniTool Partition Wizard", "Utilities", "MiniTool.PartitionWizard"),
        App("MSEdgeRedirect", "Utilities", "ShadowChaser.MSEdgeRedirect"),
        App("MSI Afterburner", "Utilities", "MSI.Afterburner"),
        App("NanaZip", "Utilities", "M2Team.NanaZip"),
        App("Nilesoft Shell", "Utilities", "Nilesoft.Shell"),
        App("NVCleanstall", "Utilities", "TechPowerUp.NVCleanstall"),
        App("OFGB", "Utilities", "valerio.OFGB"),
        App("OPAutoClicker", "Utilities", "OpAutoClicker.OPAutoClicker"),
        App("OpenRGB", "Utilities", "OpenRGB.OpenRGB"),
        App("Oracle VirtualBox", "Utilities", "Oracle.VirtualBox"),
        App("Parsec", "Utilities", "Parsec.Parsec"),
        App("PeaZip", "Utilities", "Giorgiotani.PeaZip"),
        App("Policy Plus", "Utilities", "NullException.PolicyPlus"),
        App("Process Lasso", "Utilities", "Bitsum.ProcessLasso"),
        App("Proton Authenticator", "Utilities", "Proton.ProtonAuthenticator"),
        App("Proton Drive", "Utilities", "Proton.ProtonDrive"),
        App("Proton Pass", "Utilities", "Proton.ProtonPass"),
        App("qBittorrent", "Utilities", "qBittorrent.qBittorrent"),
        App("Revo Uninstaller", "Utilities", "Revouninstaller.RevoUninstaller"),
        App("Snappy Driver Installer Origin", "Utilities", "Justin-Roche.SnappyDriverInstallerOrigin"),
        App("SignalRGB", "Utilities", "Whirlwind.SignalRGB"),
        App("StartAllBack", "Utilities", "TRlami.StartAllBack"),
        App("TeamViewer", "Utilities", "TeamViewer.TeamViewer"),
        App("TightVNC", "Utilities", "GlavSoft.TightVNC"),
        App("Total Commander", "Utilities", "Ghisler.TotalCommander"),
        App("TreeSize Free", "Utilities", "JAMSoftware.TreeSizeFree"),
        App("TranslucentTB", "Utilities", "TranslucentTB.TranslucentTB"),
        App("UniGetUI", "Utilities", "MartiCliment.UniGetUI"),
        App("Wise Program Uninstaller", "Utilities", "WiseCleaner.WiseProgramUninstaller"),
        App("WizTree", "Utilities", "AntibodySoftware.WizTree"),
        App("HxD Hex Editor", "Utilities", "HxD.HxD"),
        // ===== Extras sugeridos =====
        // Desenvolvimento
        App("Docker Desktop", "Desenvolvimento", "Docker.DockerDesktop"),
        App("Postman", "Desenvolvimento", "Postman.Postman"),
        App("Insomnia", "Desenvolvimento", "Kong.Insomnia"),
        App("DBeaver", "Desenvolvimento", "DBeaver.DBeaverCommunity"),
        App("HeidiSQL", "Desenvolvimento", "Ansgar.HeidiSQL"),
        App("GitHub CLI", "Desenvolvimento", "GitHub.cli"),
        App("Bun", "Desenvolvimento", "Oven.Bun"),
        App("Deno", "Desenvolvimento", "DenoLand.Deno"),
        App("Terraform", "Desenvolvimento", "HashiCorp.Terraform"),
        App("IntelliJ IDEA", "Desenvolvimento", "JetBrains.IntelliJIDEA.Community"),
        App("PyCharm", "Desenvolvimento", "JetBrains.PyCharm.Community"),
        App("Rider", "Desenvolvimento", "JetBrains.Rider"),
        App("Android Studio", "Desenvolvimento", "Google.AndroidStudio"),
        App("Sourcetree", "Desenvolvimento", "Atlassian.Sourcetree"),
        App("Fork", "Desenvolvimento", "GitKraken.Fork"),
        App("PowerShell 7", "Desenvolvimento", "Microsoft.PowerShell.7"),
        App("WSL", "Desenvolvimento", "Microsoft.WSL"),
        App("Redis Insight", "Desenvolvimento", "Redis.RedisInsight"),
        App("MySQL Workbench", "Desenvolvimento", "Oracle.MySQLWorkbench"),
        App("PostgreSQL", "Desenvolvimento", "PostgreSQL.PostgreSQL"),
        App("Visual Studio Build Tools", "Desenvolvimento", "Microsoft.VisualStudio.2022.BuildTools"),
        // Games
        App("Battle.net", "Games", "Blizzard.BattleNet"),
        App("Xbox App", "Games", "Microsoft.XboxApp"),
        // Pro Tools
        App("NordVPN", "Pro Tools", "NordVPN.NordVPN"),
        App("Tailscale", "Pro Tools", "Tailscale.Tailscale"),
        App("Prime95", "Pro Tools", "mersenne.prime95"),
        App("FurMark", "Pro Tools", "Geeks3D.FurMark"),
        App("Speccy", "Pro Tools", "GenuineSoftware.Speccy"),
        App("AIDA64 Extreme", "Pro Tools", "FinalWire.AIDA64.Extreme"),
        // Multimedia Tools
        App("Inkscape", "Multimedia Tools", "Inkscape.Inkscape"),
        App("Krita", "Multimedia Tools", "Krita.Krita"),
        App("Stremio", "Multimedia Tools", "Stremio.Stremio"),
        App("foobar2000", "Multimedia Tools", "PeterPawlowski.foobar2000"),
        App("MusicBee", "Multimedia Tools", "MusicBee.MusicBee"),
        // Utilities
        App("Notion", "Utilities", "Notion.Notion"),
        App("Joplin", "Utilities", "Joplin.Joplin"),
        App("Logseq", "Utilities", "Logseq.Logseq"),
        App("Greenshot", "Utilities", "Greenshot.Greenshot"),
        App("Flow Launcher", "Utilities", "Flow-Launcher.Flow-Launcher"),
        App("Mumble", "Utilities", "Mumble.Mumble"),
        App("BleachBit", "Utilities", "BleachBit.BleachBit"),
        App("CCleaner", "Utilities", "Piriform.CCleaner"),
        App("GlassWire", "Utilities", "GlassWire.GlassWire"),
        App("Listary", "Utilities", "Listary.Listary"),
        App("Keypirinha", "Utilities", "LaurentGomila.Keypirinha"),
        App("Toggl", "Utilities", "Toggl.TogglDesktop"),
    };

    private static AppEntry App(string nome, string cat, string pkg, string choco = "")
        => new() { Id = pkg, Nome = nome, Categoria = cat, PackageId = pkg, ChocoId = string.IsNullOrEmpty(choco) ? pkg : choco };

    public static string[] Categorias =>
        Catalog.Select(a => a.Categoria).Distinct().OrderBy(x => x).ToArray();

    public static string DetectarEstado(AppEntry app, string gerenciador)
    {
        try
        {
            if (gerenciador == Chocolatey)
            {
                var outp = RunCapture("choco", $"list --local-only --limit-output");
                return outp.Contains(app.ChocoId, StringComparison.OrdinalIgnoreCase) ? "Instalado" : "NaoInstalado";
            }
            var instalados = ObterInstaladosWinget();
            return instalados.Contains(app.PackageId) ? "Instalado" : "NaoInstalado";
        }
        catch
        {
            return "NaoInstalado";
        }
    }

    public static string Instalar(AppEntry app, string gerenciador)
    {
        if (gerenciador == Chocolatey)
            return RunCapture("choco", $"install {app.ChocoId} -y");
        return RunCapture("winget", $"install --id \"{app.PackageId}\" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity");
    }

    public static string Desinstalar(AppEntry app, string gerenciador)
    {
        if (gerenciador == Chocolatey)
            return RunCapture("choco", $"uninstall {app.ChocoId} -y");
        return RunCapture("winget", $"uninstall --id \"{app.PackageId}\" --disable-interactivity");
    }

    public static string Atualizar(AppEntry app, string gerenciador)
    {
        if (gerenciador == Chocolatey)
            return RunCapture("choco", $"upgrade {app.ChocoId} -y");
        return RunCapture("winget", $"upgrade --id \"{app.PackageId}\" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity");
    }

    private static readonly SemaphoreSlim _wingetGate = new(2, 2);
    private static HashSet<string>? _wingetCache;
    private static readonly object _cacheLock = new();
    private static DateTime _cacheStamp = DateTime.MinValue;
    private static readonly TimeSpan _cacheMaxAge = TimeSpan.FromSeconds(30);

    public static void InvalidateCache() { lock (_cacheLock) { _wingetCache = null; } }

    private static HashSet<string> ObterInstaladosWinget()
    {
        lock (_cacheLock)
        {
            if (_wingetCache != null && DateTime.UtcNow - _cacheStamp < _cacheMaxAge)
                return _wingetCache;
        }
        var raw = RunCapture("winget", "list --disable-interactivity");
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var linha in raw.Split('\n', StringSplitOptions.RemoveEmptyEntries))
        {
            // Formato: Nome Id Versão Disponível Fonte
            var cols = linha.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (cols.Length >= 2 && cols[1].Contains('.', StringComparison.Ordinal))
                set.Add(cols[1]);
        }
        lock (_cacheLock)
        {
            _wingetCache = set;
            _cacheStamp = DateTime.UtcNow;
        }
        return set;
    }

    private static string RunCapture(string fileName, string args)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = args,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            WindowStyle = ProcessWindowStyle.Hidden,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };
        var sb = new StringBuilder();
        using var proc = Process.Start(psi);
        if (proc is null) return "[ERRO] Nao foi possivel iniciar " + fileName + ".";
        proc.OutputDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine(e.Data); };
        proc.ErrorDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine("[ERR] " + e.Data); };
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        if (!proc.WaitForExit(15000))
        {
            try { proc.Kill(); } catch { }
            return "NaoInstalado";
        }
        return sb.ToString().Trim();
    }
}
