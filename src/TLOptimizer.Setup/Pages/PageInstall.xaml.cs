using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;

namespace TLOptimizer.Setup;

public partial class PageInstall : UserControl
{
    private MainWindow _parent = null!;
    private bool _isRepair;

    public PageInstall() => InitializeComponent();

    public void StartUninstall(MainWindow parent)
    {
        _parent = parent;
        SetProgress("Preparando desinstalação...", 0);
        Task.Run(RunUninstallAsync);
    }

    public void StartInstall(MainWindow parent, bool isRepair = false)
    {
        _parent = parent;
        _isRepair = isRepair;
        SetProgress(isRepair ? "Preparando reparo..." : "Preparando instalação...", 0);
        Task.Run(RunInstallAsync);
    }

    private async Task RunUninstallAsync()
    {
        try
        {
            SetProgress("Encerrando processos...", 5);
            foreach (var name in new[] { "TLOptimizer", "TLOptimizer.Setup" })
                foreach (var proc in Process.GetProcessesByName(name))
                    try { proc.Kill(); proc.WaitForExit(3000); } catch { }
            await Task.Delay(500);

            var appDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                "TL Optimizer");
            var scriptsDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "TLOptimizer");
            var roamingDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "TLOptimizer");
            var commonDesktop = Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory);
            var commonPrograms = Environment.GetFolderPath(Environment.SpecialFolder.CommonPrograms);

            SetProgress("Removendo atalhos...", 15);
            var desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            var programs = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
            foreach (var dir in new[] { desktop, commonDesktop })
                try { File.Delete(Path.Combine(dir, "TL Optimizer.lnk")); } catch { }
            foreach (var dir in new[] { programs, commonPrograms })
            {
                try { File.Delete(Path.Combine(dir, "TL Optimizer.lnk")); } catch { }
                try { Directory.Delete(Path.Combine(dir, "TL Optimizer"), true); } catch { }
            }

            SetProgress("Removendo arquivos do programa...", 30);
            ForceDeleteDir(appDir);
            foreach (var dir in new[] { scriptsDir, roamingDir })
                if (Directory.Exists(dir))
                    SafeDeleteDir(dir);

            SetProgress("Limpando arquivos temporários...", 45);
            var temp = Path.GetTempPath();
            foreach (var f in Directory.GetFiles(temp, "TLOptimizer*"))
                try { File.Delete(f); } catch { }
            foreach (var f in Directory.GetFiles(temp, "TLOptimizer-Setup*"))
                try { File.Delete(f); } catch { }

            SetProgress("Removendo registro do sistema...", 65);
            foreach (var hive in new[] { Registry.LocalMachine, Registry.CurrentUser })
            {
                try
                {
                    using var key = hive.OpenSubKey(@"Software\AtdasBR", true);
                    if (key?.GetSubKeyNames().Contains("TLOptimizer") == true)
                        key.DeleteSubKey("TLOptimizer");
                    if (key?.SubKeyCount == 0)
                        hive.DeleteSubKey(@"Software\AtdasBR", false);
                }
                catch { }
            }
            try
            {
                foreach (var hive in new[] { Registry.LocalMachine, Registry.CurrentUser })
                    hive.DeleteSubKeyTree(
                        @"Software\Microsoft\Windows\CurrentVersion\Uninstall\TL Optimizer", false);
            }
            catch { }

            SetProgress("Desinstalação concluída!", 100);
            await Task.Delay(300);
            _parent.Dispatcher.Invoke(() => _parent.OnInstallComplete());
        }
        catch (Exception ex)
        {
            _parent.Dispatcher.Invoke(() =>
            {
                MessageBox.Show("Erro na desinstalação:\n" + ex.Message,
                    "TL Optimizer", MessageBoxButton.OK, MessageBoxImage.Error);
                _parent.OnInstallComplete();
            });
        }
    }

    private static void ForceDeleteDir(string dir)
    {
        if (!Directory.Exists(dir)) return;
        try { SafeDeleteDir(dir); }
        catch
        {
            var isLocked = Directory.GetFiles(dir, "*", SearchOption.AllDirectories)
                .Any(f => { try { using var fs = File.Open(f, FileMode.Open, FileAccess.Read, FileShare.None); return false; } catch { return true; } });
            if (isLocked)
            {
                var me = Process.GetCurrentProcess().MainModule?.FileName ?? "";
                if (me.StartsWith(dir, StringComparison.OrdinalIgnoreCase))
                {
                    var bat = Path.Combine(Path.GetTempPath(), "tl_cleanup.bat");
                    File.WriteAllText(bat,
                        "@echo off\r\n" +
                        "timeout /t 2 /nobreak > nul\r\n" +
                        "taskkill /f /im TLOptimizer.exe /t > nul 2>&1\r\n" +
                        "taskkill /f /im TLOptimizer.Setup.exe /t > nul 2>&1\r\n" +
                        "takeown /f \"" + dir + "\" /r /d y > nul 2>&1\r\n" +
                        "icacls \"" + dir + "\" /grant Administradores:F /t /q > nul 2>&1\r\n" +
                        "rd /s /q \"" + dir + "\" > nul 2>&1\r\n" +
                        "del /q \"" + bat + "\" > nul 2>&1\r\n");
                    var psi = new ProcessStartInfo("cmd", "/c start /min \"\" \"" + bat + "\"")
                    { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden, UseShellExecute = false };
                    Process.Start(psi);
                    return;
                }
            }
            SafeDeleteDir(dir);
        }
    }

    private static void SafeDeleteDir(string dir)
    {
        for (int i = 0; i < 3; i++)
        {
            try { Directory.Delete(dir, true); return; }
            catch { System.Threading.Thread.Sleep(500); }
        }
    }

    private async Task RunInstallAsync()
    {
        try
        {
            var processPath = Environment.ProcessPath ?? throw new InvalidOperationException("Não foi possível determinar o caminho do executável");
            var exeDir = Path.GetDirectoryName(processPath)!;
            var srcDirs = new[]
            {
                Path.Combine(exeDir, "pacote"),
                Path.Combine(exeDir, "..", "..", "..", "..", "dist", "publicacao"),
                Path.Combine(exeDir, "..", "publicacao"),
                exeDir
            };

            string? publishDir = null;
            foreach (var d in srcDirs)
            {
                var resolved = Path.GetFullPath(d);
                if (File.Exists(Path.Combine(resolved, "TLOptimizer.exe")))
                { publishDir = resolved; break; }
            }

            if (publishDir == null)
                throw new Exception("Arquivos de instalação não encontrados.\n\n" +
                    "Coloque o instalador na mesma pasta da pasta 'pacote' que contém o TLOptimizer.exe.\n" +
                    "Caminhos procurados:\n" + string.Join("\n", srcDirs.Select(Path.GetFullPath)));

            var appDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                "TL Optimizer");
            var scriptsDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "TLOptimizer");

            SetProgress("Verificando diretórios...", 5);
            Directory.CreateDirectory(appDir);
            Directory.CreateDirectory(scriptsDir);
            Directory.CreateDirectory(Path.Combine(appDir, "recursos", "logos"));

            SetProgress("Copiando executável...", 15);
            SafeCopy(Path.Combine(publishDir, "TLOptimizer.exe"),
                     Path.Combine(appDir, "TLOptimizer.exe"), force: true);
            var isRunningFromAppDir = processPath.StartsWith(appDir, StringComparison.OrdinalIgnoreCase);
            if (!isRunningFromAppDir)
                SafeCopy(processPath, Path.Combine(appDir, "Desinstalar.exe"), force: true);
            Report(("OK", 25));

            SetProgress("Copiando configurações...", 30);
            foreach (var f in Directory.GetFiles(publishDir, "*.json"))
                SafeCopy(f, Path.Combine(appDir, Path.GetFileName(f)));
            foreach (var f in Directory.GetFiles(publishDir, "*.ico"))
                SafeCopy(f, Path.Combine(appDir, Path.GetFileName(f)));
            Report(("OK", 40));

            SetProgress("Copiando logos...", 45);
            var logosDir = Path.Combine(publishDir, "recursos", "logos");
            if (Directory.Exists(logosDir))
            {
                var logos = Directory.GetFiles(logosDir, "*.png");
                for (int i = 0; i < logos.Length; i++)
                {
                    SafeCopy(logos[i], Path.Combine(appDir, "recursos", "logos", Path.GetFileName(logos[i])));
                    var pct = 45 + (int)((i + 1.0) / logos.Length * 20);
                    Report(($"Copiando logos... ({i + 1}/{logos.Length})", pct));
                }
            }

            SetProgress("Copiando scripts...", 70);
            var scriptsSrc = Path.Combine(publishDir, "scripts");
            if (Directory.Exists(scriptsSrc))
                foreach (var f in Directory.GetFiles(scriptsSrc, "*.ps1"))
                    SafeCopy(f, Path.Combine(scriptsDir, Path.GetFileName(f)));
            Report(("OK", 75));

            SetProgress("Criando atalhos...", 80);
            CriarAtalho(appDir);
            CriarAtalhoDesinstalar(appDir);

            SetProgress("Configurando registro...", 85);
            using (var key = Registry.LocalMachine.CreateSubKey(@"Software\AtdasBR\TLOptimizer"))
            {
                key.SetValue("Installed", "1");
                key.SetValue("InstallPath", appDir);
                key.SetValue("Version", "1.7.2");
            }
            using (var key = Registry.LocalMachine.CreateSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\Uninstall\TL Optimizer"))
            {
                key.SetValue("DisplayName", "TL Optimizer");
                key.SetValue("DisplayVersion", "1.7.2");
                key.SetValue("Publisher", "AtdasBR");
                key.SetValue("InstallLocation", appDir);
                key.SetValue("UninstallString", "\"" + Path.Combine(appDir, "Desinstalar.exe") + "\"");
                key.SetValue("DisplayIcon", Path.Combine(appDir, "TLOptimizer.exe"));
                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
            }

            SetProgress("Instalação concluída!", 100);
            await Task.Delay(300);

            _parent.Dispatcher.Invoke(() => _parent.OnInstallComplete());
        }
        catch (Exception ex)
        {
            _parent.Dispatcher.Invoke(() =>
            {
                MessageBox.Show("Erro na instalação:\n" + ex.Message + "\n\n" + ex.GetType().Name,
                    "TL Optimizer", MessageBoxButton.OK, MessageBoxImage.Error);
                _parent.OnInstallComplete();
            });
        }
    }

    private bool SafeCopy(string src, string dest, bool force = false)
    {
        try
        {
            if (!force && _isRepair && File.Exists(dest))
            {
                var srcInfo = new FileInfo(src);
                var dstInfo = new FileInfo(dest);
                if (srcInfo.Length == dstInfo.Length && srcInfo.LastWriteTime == dstInfo.LastWriteTime)
                    return true;
            }
            File.Copy(src, dest, true);
            return true;
        }
        catch { return false; }
    }

    private void SetProgress(string text, int pct)
    {
        Report((text, Math.Clamp(pct, 0, 100)));
        System.Threading.Thread.Sleep(80);
    }

    private void Report((string text, int pct) state)
    {
        _parent.Dispatcher.Invoke(() =>
        {
            LblFile.Text = state.text;
            ProgressBar.Value = state.pct;
            LblPercent.Text = state.pct + "%";
        });
    }

    private static void CriarAtalhoDesinstalar(string appDir)
    {
        var alvo = "\"" + appDir + "\\Desinstalar.exe\"";
        try
        {
            var ps = "$s=New-Object -ComObject WScript.Shell;" +
                     "$s=$s.CreateShortcut([Environment]::GetFolderPath('Programs')+'\\TL Optimizer\\Desinstalar.lnk');" +
                     "$s.TargetPath='" + alvo + "';" +
                     "$s.WorkingDirectory='" + appDir + "';" +
                     "$s.Description='Remover o TL Optimizer do computador';" +
                     "$s.Save()";
            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -ExecutionPolicy Bypass -Command \"" + ps.Replace("\"", "\\\"") + "\"")
            { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
            using var p = Process.Start(psi);
            p?.WaitForExit(3000);
        }
        catch { }
    }

    private static void CriarAtalho(string appDir)
    {
        var alvo = appDir + "\\TLOptimizer.exe";
        try
        {
            var ps = "$s=New-Object -ComObject WScript.Shell;" +
                     "$s=$s.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\\TL Optimizer.lnk');" +
                     "$s.TargetPath='" + alvo + "';" +
                     "$s.WorkingDirectory='" + appDir + "';" +
                     "$s.Description='TL Optimizer - Otimizador de Windows';" +
                     "$s.Save()";
            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -ExecutionPolicy Bypass -Command \"" + ps.Replace("\"", "\\\"") + "\"")
            { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
            using var p = Process.Start(psi);
            p?.WaitForExit(3000);
        }
        catch { }
        try
        {
            var ps = "$s=New-Object -ComObject WScript.Shell;" +
                     "$s=$s.CreateShortcut([Environment]::GetFolderPath('Programs')+'\\TL Optimizer.lnk');" +
                     "$s.TargetPath='" + alvo + "';" +
                     "$s.WorkingDirectory='" + appDir + "';" +
                     "$s.Description='TL Optimizer - Otimizador de Windows';" +
                     "$s.Save()";
            var psi = new ProcessStartInfo("powershell",
                "-NoProfile -ExecutionPolicy Bypass -Command \"" + ps.Replace("\"", "\\\"") + "\"")
            { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
            using var p = Process.Start(psi);
            p?.WaitForExit(3000);
        }
        catch { }
    }
}
