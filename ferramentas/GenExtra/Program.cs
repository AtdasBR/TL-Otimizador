using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net;
using Svg;

class P2 {
    public string Pid, SI, Dom, Alt;
    public P2(string pid,string si,string dom,string alt){Pid=pid;SI=si;Dom=dom;Alt=alt;}
}
class G2 {
    static string Dir = @"C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador\assets\logos";
    static WebClient wc = new WebClient();
    static byte[] Try(string url){ try { return wc.DownloadData(url); } catch { return null; } }
    static void Main(){
        var rows = new System.Collections.Generic.List<P2>();
        // Pid, SimpleIcon slug, favicon domain, alt url
        rows.Add(new P2("Docker.DockerDesktop","docker","docker.com",""));
        rows.Add(new P2("Postman.Postman","","getpostman.com","https://www.google.com/s2/favicons?domain=postman.com&sz=128"));
        rows.Add(new P2("Kong.Insomnia","insomnia","insomnia.rest",""));
        rows.Add(new P2("DBeaver.DBeaverCommunity","","dbeaver.io","https://www.google.com/s2/favicons?domain=dbeaver.io&sz=128"));
        rows.Add(new P2("Ansgar.HeidiSQL","","heidisql.com","https://www.google.com/s2/favicons?domain=heidisql.com&sz=128"));
        rows.Add(new P2("GitHub.cli","github","github.com",""));
        rows.Add(new P2("Oven.Bun","bun","bun.sh",""));
        rows.Add(new P2("DenoLand.Deno","deno","deno.com",""));
        rows.Add(new P2("HashiCorp.Terraform","terraform","terraform.io",""));
        rows.Add(new P2("JetBrains.IntelliJIDEA.Community","intellijidea","jetbrains.com",""));
        rows.Add(new P2("JetBrains.PyCharm.Community","pycharm","jetbrains.com",""));
        rows.Add(new P2("JetBrains.Rider","rider","jetbrains.com",""));
        rows.Add(new P2("Google.AndroidStudio","android","developer.android.com",""));
        rows.Add(new P2("Atlassian.Sourcetree","","sourcetreeapp.com","https://www.google.com/s2/favicons?domain=sourcetreeapp.com&sz=128"));
        rows.Add(new P2("GitKraken.Fork","","git-fork.com","https://www.google.com/s2/favicons?domain=git-fork.com&sz=128"));
        rows.Add(new P2("Microsoft.PowerShell.7","powershell","microsoft.com",""));
        rows.Add(new P2("Microsoft.WSL","windowsterminal","microsoft.com",""));
        rows.Add(new P2("Redis.RedisInsight","redis","redis.io",""));
        rows.Add(new P2("Oracle.MySQLWorkbench","","mysql.com","https://www.google.com/s2/favicons?domain=mysql.com&sz=128"));
        rows.Add(new P2("PostgreSQL.PostgreSQL","postgresql","postgresql.org",""));
        rows.Add(new P2("Microsoft.VisualStudio.2022.BuildTools","visualstudio","microsoft.com",""));
        rows.Add(new P2("Blizzard.BattleNet","battlenet","blizzard.com",""));
        rows.Add(new P2("Microsoft.XboxApp","xbox","xbox.com",""));
        rows.Add(new P2("NordVPN.NordVPN","nordvpn","nordvpn.com",""));
        rows.Add(new P2("Tailscale.Tailscale","tailscale","tailscale.com",""));
        rows.Add(new P2("Inkscape.Inkscape","inkscape","inkscape.org",""));
        rows.Add(new P2("Krita.Krita","krita","krita.org",""));
        rows.Add(new P2("Stremio.Stremio","","stremio.com","https://www.google.com/s2/favicons?domain=stremio.com&sz=128"));
        rows.Add(new P2("PeterPawlowski.foobar2000","","foobar2000.org","https://www.google.com/s2/favicons?domain=foobar2000.org&sz=128"));
        rows.Add(new P2("MusicBee.MusicBee","","musicbee.io","https://www.google.com/s2/favicons?domain=musicbee.io&sz=128"));
        rows.Add(new P2("Notion.Notion","notion","notion.so",""));
        rows.Add(new P2("Joplin.Joplin","joplin","joplinapp.org",""));
        rows.Add(new P2("Logseq.Logseq","logseq","logseq.com",""));
        rows.Add(new P2("Greenshot.Greenshot","greenshot","greenshot.org",""));
        rows.Add(new P2("Flow-Launcher.Flow-Launcher","","flowlauncher.app","https://www.google.com/s2/favicons?domain=flowlauncher.app&sz=128"));
        rows.Add(new P2("Mumble.Mumble","mumble","mumble.info",""));
        rows.Add(new P2("BleachBit.BleachBit","bleachbit","bleachbit.org",""));
        rows.Add(new P2("Piriform.CCleaner","","ccleaner.com","https://www.google.com/s2/favicons?domain=ccleaner.com&sz=128"));
        rows.Add(new P2("GlassWire.GlassWire","glasswire","glasswire.com",""));
        rows.Add(new P2("UderzoSoftware.SpaceSniffer","","spacesniffer.net","https://www.google.com/s2/favicons?domain=spacesniffer.net&sz=128"));
        rows.Add(new P2("Listary.Listary","","listary.com","https://www.google.com/s2/favicons?domain=listary.com&sz=128"));
        rows.Add(new P2("LaurentGomila.Keypirinha","keypirinha","keypirinha.com",""));
        rows.Add(new P2("Toggl.TogglDesktop","toggl","toggl.com",""));
        rows.Add(new P2("Gwidon.MersennePrime.Overseer","","mersenne.org","https://www.google.com/s2/favicons?domain=mersenne.org&sz=128"));
        rows.Add(new P2("Geeks3D.FurMark","","geeks3d.com","https://www.google.com/s2/favicons?domain=geeks3d.com&sz=128"));
        rows.Add(new P2("GenuineSoftware.Speccy","","ccleaner.com","https://www.google.com/s2/favicons?domain=ccleaner.com&sz=128"));
        rows.Add(new P2("FinalWire.AIDA64.Extreme","aida64","aida64.com",""));

        int ok=0, miss=0;
        foreach(var r in rows){
            byte[] data=null; string ext="";
            if(!string.IsNullOrEmpty(r.SI)){ data=Try($"https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/{r.SI}.svg"); if(data!=null) ext="svg"; }
            if(data==null && !string.IsNullOrEmpty(r.Dom)){ data=Try($"https://www.google.com/s2/favicons?domain={r.Dom}&sz=128"); if(data!=null) ext="png"; }
            if(data==null && !string.IsNullOrEmpty(r.Alt)){ data=Try(r.Alt); if(data!=null) ext="png"; }
            if(data==null){ Console.WriteLine("MISS "+r.Pid); miss++; continue; }
            string png=Path.Combine(Dir,r.Pid+".png");
            if(ext=="svg"){
                var content=System.Text.Encoding.UTF8.GetString(data);
                content=content.Replace("#000","#FFFFFF",StringComparison.OrdinalIgnoreCase).Replace("#000000","#FFFFFF",StringComparison.OrdinalIgnoreCase).Replace("#111","#FFFFFF",StringComparison.OrdinalIgnoreCase).Replace("#1A1A1A","#FFFFFF",StringComparison.OrdinalIgnoreCase).Replace("#2D2D2D","#FFFFFF",StringComparison.OrdinalIgnoreCase).Replace("currentColor","#FFFFFF",StringComparison.OrdinalIgnoreCase);
                var svg=SvgDocument.Open<SvgDocument>(new MemoryStream(System.Text.Encoding.UTF8.GetBytes(content)));
                using(var bmp=svg.Draw(256,256)) bmp.Save(png,ImageFormat.Png);
            } else {
                using(var img=Image.FromFile(WriteTemp(data,ext))){
                    var bmp=new Bitmap(256,256); var g=Graphics.FromImage(bmp);
                    g.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic; g.Clear(Color.Black);
                    var ratio=Math.Min(256.0/img.Width,256.0/img.Height); int w=(int)(img.Width*ratio),h=(int)(img.Height*ratio);
                    g.DrawImage(img,(256-w)/2,(256-h)/2,w,h); bmp.Save(png,ImageFormat.Png);
                }
            }
            Console.WriteLine("OK "+r.Pid); ok++;
        }
        Console.WriteLine($"TOTAL ok={ok} miss={miss}");
    }
    static string WriteTemp(byte[] d,string ext){ string t=Path.GetTempFileName(); File.WriteAllBytes(t,d); return t; }
}
