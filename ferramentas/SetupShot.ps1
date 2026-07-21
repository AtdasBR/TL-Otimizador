$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Threading;
public class Shot {
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, int f);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static void Cap(string exe, string outp) {
    var p = Process.Start(exe);
    Thread.Sleep(2500);
    IntPtr h = p.MainWindowHandle;
    if (h == IntPtr.Zero) { System.IO.File.WriteAllText(outp+".nohandle","x"); p.Kill(); return; }
    GetWindowRect(h, out RECT r);
    int w = r.R-r.L; int hh = r.B-r.T;
    var bmp = new Bitmap(w, hh);
    var g = Graphics.FromImage(bmp);
    PrintWindow(h, g.GetHdc(), 0);
    g.ReleaseHdc();
    bmp.Save(outp, ImageFormat.Png);
    bmp.Dispose();
    var b2 = new Bitmap(outp);
    long leftSum=0, rightSum=0, leftN=0, rightN=0;
    for(int y=20;y<hh-20;y+=4){
      for(int x=5;x<160;x+=4){ var c=b2.GetPixel(x,y); leftSum+=c.R+c.G+c.B; leftN++; }
      for(int x=200;x<w-20;x+=4){ var c=b2.GetPixel(x,y); rightSum+=c.R+c.G+c.B; rightN++; }
    }
    b2.Dispose();
    System.IO.File.WriteAllText(outp+".analysis", "leftAvg="+(leftSum/leftN)+" rightAvg="+(rightSum/rightN)+" w="+w+" h="+hh);
    p.Kill();
  }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing,System.Windows.Forms
[Shot]::Cap("C:\Users\Administrator\.gemini\antigravity\scratch\TL-Otimizador\build\installer\TLOptimizer-Setup-1.7.2.exe", "C:\temp\setupshot.png")
Start-Sleep -Seconds 1
if(Test-Path "C:\temp\setupshot.png.analysis"){ Get-Content "C:\temp\setupshot.png.analysis" } else { Write-Host "sem analise" }
Get-Process -Name "TLOptimizer-Setup-1.7.2" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
