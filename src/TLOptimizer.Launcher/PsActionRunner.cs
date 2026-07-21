using System.Diagnostics;
using System.Text;

namespace TLOptimizer.Launcher;

/// <summary>
/// Executa uma única ação do otimizador em modo headless (sem janela de console)
/// e devolve a saída de texto para a UI exibir.
/// </summary>
internal static class PsActionRunner
{
    public static string RunAction(string scriptPath, string actionId)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\" -Headless -Acao {actionId}",
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
        if (proc is null) return "[ERRO] Não foi possível iniciar o PowerShell.";

        proc.OutputDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine(e.Data); };
        proc.ErrorDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine("[ERR] " + e.Data); };
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        proc.WaitForExit();
        return sb.ToString().Trim();
    }
}
