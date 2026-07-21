using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net;
using System.Text;
using Svg;

class GenOriginal
{
    static string Dir = @"C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador\assets\logos";
    static WebClient wc = new WebClient();
    static byte[] Try(string url)
    {
        try { wc.Headers["User-Agent"] = "Mozilla/5.0"; return wc.DownloadData(url); }
        catch { return null; }
    }

    // PackageId -> (slug Simple Icons confirmado OU null, domínio p/ favicon, url direta OU null)
    static readonly (string Pid, string Slug, string Dom, string Url)[] Map = new (string Pid, string Slug, string Dom, string Url)[]
    {
        ("CE-Programming.CEmu", null, "cemu.info", null),
        ("NVIDIA.GeForceNOW", null, "nvidia.com", null),
        ("Heroic-Games-Launcher.HeroicGamesLauncher", "heroicgameslauncher", null, null),
        ("ItchIo.Itch", "itchdotio", null, null),
        ("Modrinth.ModrinthApp", "modrinth", null, null),
        ("PrismLauncher.PrismLauncher", null, "prismlauncher.com", null),
        ("Ubisoft.Connect", "ubisoft", null, null),
        ("Microsoft.OneDrive", null, "onedrive.com", null),
        ("Microsoft.PowerShell", null, null, "https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png"),
        ("Microsoft.WindowsTerminal", null, null, "https://raw.githubusercontent.com/microsoft/terminal/main/res/terminal.ico"),
        ("AIMP.AIMP", null, "aimp.ru", null),
        ("BlenderFoundation.Blender", "blender", null, null),
        ("calibre.calibre", null, "calibre-ebook.com", null),
        ("GIMP.GIMP", "gimp", null, null),
        ("HandBrake.HandBrake", null, "handbrake.fr", null),
        ("ImageGlass.ImageGlass", null, "imageglass.org", null),
        ("Apple.iTunes", "apple", null, null),
        ("TheDocumentFoundation.LibreOffice", "libreoffice", null, null),
        ("Notepad++.Notepad++", "notepadplusplus", null, null),
        ("Obsidian.Obsidian", "obsidian", null, null),
        ("ONLYOFFICE.DesktopEditors", "onlyoffice", null, null),
        ("ShareX.ShareX", "sharex", null, null),
        ("VideoLAN.VLC", null, "vlc.com", null),
        ("CPUID.CPU-Z", null, "cpuid.com", null),
        ("TechPowerUp.GPU-Z", null, "techpowerup.com", null),
        ("REALiX.HWiNFO", null, "hwinfo.com", null),
        ("CPUID.HWMonitor", null, "cpuid.com", null),
        ("MullvadVPN.MullvadBrowser", "mullvad", null, null),
        ("Insecure.Com.Nmap", null, "nmap.org", null),
        ("OpenVPNTechnologies.OpenVPNConnect", "openvpn", null, null),
        ("Proton.ProtonVPN", "protonvpn", null, null),
        ("WireGuard.WireGuard", "wireguard", null, null),
        ("WiresharkFoundation.Wireshark", "wireshark", null, null),
        ("Jellyfin.JellyfinMediaPlayer", "jellyfin", null, null),
        ("Jellyfin.JellyfinServer", "jellyfin", null, null),
        ("Team-Kodi.Kodi", "kodi", null, null),
        ("LocalSend.LocalSend", "localsend", null, null),
        ("Nextcloud.NextcloudDesktop", "nextcloud", null, null),
        ("Plex.PlexMediaServer", "plex", null, null),
        ("Plex.Plex", "plex", null, null),
        ("AgileBits.1Password", "1password", null, null),
        ("7zip.7zip", "7zip", null, null),
        ("AnyDesk.AnyDesk", "anydesk", null, null),
        ("AutoHotkey.AutoHotkey", "autohotkey", null, null),
        ("Bitwarden.Bitwarden", "bitwarden", null, null),
        ("Dropbox.Dropbox", "dropbox", null, null),
        ("FilesCommunity.Files", "files", null, null),
        ("Google.GoogleDrive", null, "google.com", null),
        ("KeePassXCTeam.KeePassXC", "keepassxc", null, null),
        ("Proton.ProtonDrive", "protondrive", null, null),
        ("Proton.ProtonPass", null, "proton.me", null),
        ("qBittorrent.qBittorrent", "qbittorrent", null, null),
        ("WinRAR.WinRAR", null, "win-rar.com", null),
        ("Docker.DockerDesktop", "docker", null, null),
        ("Kong.Insomnia", "insomnia", null, null),
        ("GitHub.cli", "github", null, null),
        ("Oven.Bun", "bun", null, null),
        ("DenoLand.Deno", "deno", null, null),
        ("HashiCorp.Terraform", "terraform", null, null),
        ("JetBrains.IntelliJIDEA.Community", "intellijidea", null, null),
        ("JetBrains.PyCharm.Community", "pycharm", null, null),
        ("JetBrains.Rider", "rider", null, null),
        ("Google.AndroidStudio", "androidstudio", null, null),
        ("Microsoft.PowerShell.7", null, null, "https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png"),
        ("Microsoft.WSL", null, "docs.microsoft.com", null),
        ("Redis.RedisInsight", "redis", null, null),
        ("PostgreSQL.PostgreSQL", "postgresql", null, null),
        ("Microsoft.VisualStudio.2022.BuildTools", null, "visualstudio.microsoft.com", null),
        ("Blizzard.BattleNet", "battledotnet", null, null),
        ("Microsoft.XboxApp", null, "xbox.com", null),
        ("NordVPN.NordVPN", "nordvpn", null, null),
        ("Tailscale.Tailscale", "tailscale", null, null),
        ("Inkscape.Inkscape", "inkscape", null, null),
        ("Krita.Krita", "krita", null, null),
        ("Notion.Notion", "notion", null, null),
        ("Joplin.Joplin", "joplin", null, null),
        ("Logseq.Logseq", "logseq", null, null),
        ("Greenshot.Greenshot", null, "greenshot.org", null),
        ("Mumble.Mumble", "mumble", null, null),
        ("BleachBit.BleachBit", null, "bleachbit.org", null),
        ("GlassWire.GlassWire", null, "glasswire.com", null),
        ("LaurentGomila.Keypirinha", null, "keypirinha.com", null),
        ("Toggl.TogglDesktop", "toggl", null, null),
        ("FinalWire.AIDA64.Extreme", null, "aida64.com", null),
    };

    static void Main()
    {
        int ok = 0, miss = 0;
        foreach (var m in Map)
        {
            byte[] data = null; string ext = "";
            if (!string.IsNullOrEmpty(m.Url))
            {
                data = Try(m.Url);
                if (data != null) ext = m.Url.EndsWith(".svg") ? "svg" : "png";
            }
            if (data == null && !string.IsNullOrEmpty(m.Slug))
            {
                data = Try($"https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/{m.Slug}.svg");
                if (data != null) ext = "svg";
            }
            if (data == null && !string.IsNullOrEmpty(m.Dom))
            {
                data = Try($"https://www.google.com/s2/favicons?domain={m.Dom}&sz=128");
                if (data != null) ext = "png";
            }
            if (data == null) { Console.WriteLine("MISS " + m.Pid); miss++; continue; }

            string png = Path.Combine(Dir, m.Pid + ".png");
            if (ext == "svg")
            {
                // COR ORIGINAL: mantém a cor nativa do Simple Icon (não força branco)
                var svg = SvgDocument.Open<SvgDocument>(new MemoryStream(data));
                using (var bmp = svg.Draw(256, 256)) bmp.Save(png, ImageFormat.Png);
            }
            else
            {
                using (var img = Image.FromStream(new MemoryStream(data)))
                {
                    var bmp = new Bitmap(256, 256);
                    var g = Graphics.FromImage(bmp);
                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.Clear(Color.Transparent);
                    var ratio = Math.Min(256.0 / img.Width, 256.0 / img.Height);
                    int w = (int)(img.Width * ratio), h = (int)(img.Height * ratio);
                    g.DrawImage(img, (256 - w) / 2, (256 - h) / 2, w, h);
                    bmp.Save(png, ImageFormat.Png);
                }
            }
            Console.WriteLine("OK " + m.Pid);
            ok++;
        }
        Console.WriteLine($"TOTAL ok={ok} miss={miss}");
    }
}
