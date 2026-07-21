using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net;
using Svg;

class P {
    public string Pid, Cat, SI, Dom;
    public P(string pid, string cat, string si, string dom){Pid=pid;Cat=cat;SI=si;Dom=dom;}
}

class Program {
    static string Dir = @"C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador\assets\logos";
    static WebClient wc = new WebClient();
    static List<P> rows = new List<P>();
    static void Add(string pid,string cat,string si,string dom)=>rows.Add(new P(pid,cat,si,dom));
    static byte[] Try(string url){
        try { return wc.DownloadData(url); } catch { return null; }
    }
    static void Main(){
        // ===== GAMES =====
        Add("CE-Programming.CEmu","Games","cemu","");
        Add("ElectronicArts.EADesktop","Games","","ea.com");
        Add("EpicGames.EpicGamesLauncher","Games","","epicgames.com");
        Add("NVIDIA.GeForceNOW","Games","nvidia","");
        Add("GOG.Galaxy","Games","","gog.com");
        Add("Heroic-Games-Launcher.HeroicGamesLauncher","Games","heroicgameslauncher","");
        Add("ItchIo.Itch","Games","itchdotio","");
        Add("Modrinth.ModrinthApp","Games","modrinth","");
        Add("Overwolf.Overwolf","Games","","overwolf.com");
        Add("Playnite.Playnite","Games","","playnite.link");
        Add("PrismLauncher.PrismLauncher","Games","prismlauncher","");
        Add("Valve.Steam","Games","","steampowered.com");
        Add("Ubisoft.Connect","Games","ubisoft","");
        Add("VirtualDesktop.VirtualDesktopStreamer","Games","","vrdesktop.net");
        // ===== MICROSOFT TOOLS =====
        Add("Microsoft.Sysinternals.Autoruns","Microsoft Tools","","microsoft.com");
        Add("CodingWondersSoftware.DISMTools.Stable","Microsoft Tools","","microsoft.com");
        Add("Microsoft.DotNet.DesktopRuntime.10","Microsoft Tools","","dotnet.microsoft.com");
        Add("Microsoft.DotNet.DesktopRuntime.6","Microsoft Tools","","dotnet.microsoft.com");
        Add("Microsoft.DotNet.DesktopRuntime.8","Microsoft Tools","","dotnet.microsoft.com");
        Add("Microsoft.DotNet.DesktopRuntime.9","Microsoft Tools","","dotnet.microsoft.com");
        Add("Nlite.NLite","Microsoft Tools","","ntlite.com");
        Add("Microsoft.NuGet","Microsoft Tools","","nuget.org");
        Add("Microsoft.OneDrive","Microsoft Tools","microsoftonedrive","");
        Add("Microsoft.PowerShell","Microsoft Tools","powershell","");
        Add("Microsoft.PowerToys","Microsoft Tools","","microsoft.com");
        Add("Microsoft.Sysinternals.ProcessExplorer","Microsoft Tools","","microsoft.com");
        Add("Microsoft.Sysinternals.ProcessMonitor","Microsoft Tools","","microsoft.com");
        Add("Microsoft.RemoteDesktopClient.RDCman","Microsoft Tools","","microsoft.com");
        Add("Microsoft.Sysinternals.TCPView","Microsoft Tools","","microsoft.com");
        Add("Microsoft.WindowsTerminal","Microsoft Tools","windowsterminal","");
        Add("Microsoft.VCRedist.2015+.x86","Microsoft Tools","","microsoft.com");
        Add("Microsoft.VCRedist.2015+.x64","Microsoft Tools","","microsoft.com");
        // ===== MULTIMEDIA =====
        Add("Adobe.Acrobat.Reader.64-bit","Multimedia Tools","","adobe.com");
        Add("AIMP.AIMP","Multimedia Tools","aimp","");
        Add("Audacity.Audacity","Multimedia Tools","","audacityteam.org");
        Add("BlenderFoundation.Blender","Multimedia Tools","blender","");
        Add("calibre.calibre","Multimedia Tools","calibre","");
        Add("File-New-Project.EarTrumpet","Multimedia Tools","","eartrumpet.app");
        Add("GIMP.GIMP","Multimedia Tools","gimp","");
        Add("HandBrake.HandBrake","Multimedia Tools","handbrake","");
        Add("ImageGlass.ImageGlass","Multimedia Tools","imageglass","");
        Add("IrfanView.IrfanView","Multimedia Tools","","irfanview.com");
        Add("Apple.iTunes","Multimedia Tools","apple","");
        Add("TheDocumentFoundation.LibreOffice","Multimedia Tools","libreoffice","");
        Add("clsid2.mpc-hc","Multimedia Tools","","mpc-hc.org");
        Add("mpc-qt.mpc-qt","Multimedia Tools","","mpc-qt.github.io");
        Add("NAPS2.NAPS2","Multimedia Tools","","apps.microsoft.com");
        Add("nomacs.nomacs","Multimedia Tools","","nomacs.org");
        Add("Notepad++.Notepad++","Multimedia Tools","notepadplusplus","");
        Add("OBSProject.OBSStudio","Multimedia Tools","","obsproject.com");
        Add("Obsidian.Obsidian","Multimedia Tools","obsidian","");
        Add("ONLYOFFICE.DesktopEditors","Multimedia Tools","onlyoffice","");
        Add("dotPDN.Paint.NET","Multimedia Tools","","getpaint.net");
        Add("ShareX.ShareX","Multimedia Tools","sharex","");
        Add("VideoLAN.VLC","Multimedia Tools","vlc","");
        // ===== PRO TOOLS =====
        Add("Famatech.AdvancedIPScanner","Pro Tools","","advanced-ip-scanner.com");
        Add("AntonKeks.AngryIPScanner","Pro Tools","","angryip.org");
        Add("Maxon.Cinebench","Pro Tools","","maxon.net");
        Add("CPUID.CPU-Z","Pro Tools","cpuz","");
        Add("Wagnardsoft.DDU","Pro Tools","","wagnardsoft.com");
        Add("TechPowerUp.GPU-Z","Pro Tools","gpuz","");
        Add("gerardog.gsudo","Pro Tools","","gsudo.dev");
        Add("REALiX.HWiNFO","Pro Tools","hwmonitor","");
        Add("CPUID.HWMonitor","Pro Tools","hwmonitor","");
        Add("MullvadVPN.MullvadBrowser","Pro Tools","mullvad","");
        Add("Insecure.Com.Nmap","Pro Tools","nmap","");
        Add("OpenVPNTechnologies.OpenVPNConnect","Pro Tools","openvpn","");
        Add("Proton.ProtonVPN","Pro Tools","protonvpn","");
        Add("SimonTatham.PuTTY","Pro Tools","","chiark.greenend.org.uk");
        Add("HenryPP.SimpleWall","Pro Tools","","henkemans.dev");
        Add("Ventoy.Ventoy","Pro Tools","","ventoy.net");
        Add("WinSCP.WinSCP","Pro Tools","","winscp.net");
        Add("WireGuard.WireGuard","Pro Tools","wireguard","");
        Add("WiresharkFoundation.Wireshark","Pro Tools","wireshark","");
        // ===== SELFHOSTED =====
        Add("Jellyfin.JellyfinMediaPlayer","Selfhosted Tools","jellyfin","");
        Add("Jellyfin.JellyfinServer","Selfhosted Tools","jellyfin","");
        Add("Team-Kodi.Kodi","Selfhosted Tools","kodi","");
        Add("LocalSend.LocalSend","Selfhosted Tools","localsend","");
        Add("GracefulTee.Moonlight","Selfhosted Tools","","moonlight-stream.org");
        Add("NetBird.NetBird","Selfhosted Tools","","netbird.io");
        Add("Nextcloud.NextcloudDesktop","Selfhosted Tools","nextcloud","");
        Add("Plex.PlexMediaServer","Selfhosted Tools","plex","");
        Add("Plex.Plex","Selfhosted Tools","plex","");
        Add("LizardByte.Sunshine","Selfhosted Tools","","sunshinestream.org");
        // ===== UTILITIES =====
        Add("AgileBits.1Password","Utilities","1password","");
        Add("7zip.7zip","Utilities","7zip","");
        Add("AnyDesk.AnyDesk","Utilities","anydesk","");
        Add("AutoHotkey.AutoHotkey","Utilities","autohotkey","");
        Add("Bitwarden.Bitwarden","Utilities","bitwarden","");
        Add("Bloop.BlurAutoClicker","Utilities","","github.com");
        Add("Klocman.BulkCrapUninstaller","Utilities","","github.com");
        Add("CrystalDewWorld.CrystalDiskInfo","Utilities","","crystalmark.info");
        Add("CrystalDewWorld.CrystalDiskMark","Utilities","","crystalmark.info");
        Add("Deskflow.Deskflow","Utilities","","deskflow.org");
        Add("Dropbox.Dropbox","Utilities","dropbox","");
        Add("Ente.Authenticator","Utilities","","ente.io");
        Add("Voidtools.Everything","Utilities","","voidtools.com");
        Add("FilesCommunity.Files","Utilities","files","");
        Add("HyperbolicSoftware.F.lux","Utilities","","justgetflux.com");
        Add("glzr-io.GlazeWM","Utilities","","github.com");
        Add("Google.GoogleDrive","Utilities","googledrive","");
        Add("GoHugo.Hugo","Utilities","","gohugo.io");
        Add("Tonec.InternetDownloadManager","Utilities","","internetdownloadmanager.com");
        Add("sylikc.JPEGView","Utilities","","github.com");
        Add("KeePassXCTeam.KeePassXC","Utilities","keepassxc","");
        Add("MiniTool.PartitionWizard","Utilities","","minitool.com");
        Add("ShadowChaser.MSEdgeRedirect","Utilities","","github.com");
        Add("MSI.Afterburner","Utilities","","msi.com");
        Add("M2Team.NanaZip","Utilities","","github.com");
        Add("Nilesoft.Shell","Utilities","","nilesoft.org");
        Add("TechPowerUp.NVCleanstall","Utilities","","techpowerup.com");
        Add("valerio.OFGB","Utilities","","github.com");
        Add("OpAutoClicker.OPAutoClicker","Utilities","","github.com");
        Add("OpenRGB.OpenRGB","Utilities","","openrgb.org");
        Add("Oracle.VirtualBox","Utilities","","virtualbox.org");
        Add("Parsec.Parsec","Utilities","","parsec.app");
        Add("Giorgiotani.PeaZip","Utilities","","peazip.github.io");
        Add("NullException.PolicyPlus","Utilities","","github.com");
        Add("Bitsum.ProcessLasso","Utilities","","bitsum.com");
        Add("Proton.ProtonAuthenticator","Utilities","","github.com");
        Add("Proton.ProtonDrive","Utilities","protondrive","");
        Add("Proton.ProtonPass","Utilities","protonpass","");
        Add("qBittorrent.qBittorrent","Utilities","qbittorrent","");
        Add("Revouninstaller.RevoUninstaller","Utilities","","revouninstaller.com");
        Add("Rufus.Rufus","Utilities","","rufus.ie");
        Add("Justin-Roche.SnappyDriverInstallerOrigin","Utilities","","github.com");
        Add("Whirlwind.SignalRGB","Utilities","","signalrgb.com");
        Add("TRlami.StartAllBack","Utilities","","startallback.com");
        Add("TeamViewer.TeamViewer","Utilities","","teamviewer.com");
        Add("GlavSoft.TightVNC","Utilities","","tightvnc.com");
        Add("Ghisler.TotalCommander","Utilities","","ghisler.com");
        Add("JAMSoftware.TreeSizeFree","Utilities","","jam-software.com");
        Add("TranslucentTB.TranslucentTB","Utilities","","github.com");
        Add("MartiCliment.UniGetUI","Utilities","","github.com");
        Add("WinRAR.WinRAR","Utilities","winrar","");
        Add("WiseCleaner.WiseProgramUninstaller","Utilities","","wisecleaner.com");
        Add("AntibodySoftware.WizTree","Utilities","","diskanalyzer.com");
        Add("HxD.HxD","Utilities","","mh-nexus.de");

        int ok=0, miss=0;
        foreach(var r in rows){
            byte[] data=null; string ext="";
            if(!string.IsNullOrEmpty(r.SI)){
                data=Try($"https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/{r.SI}.svg");
                if(data!=null) ext="svg";
            }
            if(data==null && !string.IsNullOrEmpty(r.Dom)){
                data=Try($"https://www.google.com/s2/favicons?domain={r.Dom}&sz=128");
                if(data!=null) ext="png";
            }
            if(data==null){ Console.WriteLine("MISS "+r.Pid); miss++; continue; }
            string src=Path.Combine(Dir,"_gen_"+r.Pid.Replace('.','_')+"."+ext);
            File.WriteAllBytes(src,data);
            string png=Path.Combine(Dir,r.Pid+".png");
            if(ext=="svg"){
                var content=System.Text.Encoding.UTF8.GetString(data);
                content=content.Replace("#000","#FFFFFF",StringComparison.OrdinalIgnoreCase)
                              .Replace("#000000","#FFFFFF",StringComparison.OrdinalIgnoreCase)
                              .Replace("#111","#FFFFFF",StringComparison.OrdinalIgnoreCase)
                              .Replace("#1A1A1A","#FFFFFF",StringComparison.OrdinalIgnoreCase)
                              .Replace("#2D2D2D","#FFFFFF",StringComparison.OrdinalIgnoreCase)
                              .Replace("currentColor","#FFFFFF",StringComparison.OrdinalIgnoreCase);
                var svg=SvgDocument.Open<SvgDocument>(new MemoryStream(System.Text.Encoding.UTF8.GetBytes(content)));
                using(var bmp=svg.Draw(256,256)) bmp.Save(png,ImageFormat.Png);
            } else {
                using(var img=Image.FromFile(src)){
                    var bmp=new Bitmap(256,256);
                    var g=Graphics.FromImage(bmp);
                    g.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.Clear(Color.Black);
                    var ratio=Math.Min(256.0/img.Width,256.0/img.Height);
                    int w=(int)(img.Width*ratio),h=(int)(img.Height*ratio);
                    g.DrawImage(img,(256-w)/2,(256-h)/2,w,h);
                    bmp.Save(png,ImageFormat.Png);
                }
            }
            File.Delete(src);
            Console.WriteLine("OK "+r.Pid); ok++;
        }
        Console.WriteLine($"TOTAL ok={ok} miss={miss}");
    }
}
