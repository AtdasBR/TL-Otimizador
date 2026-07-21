using System.Diagnostics;
using System.Text.Json;

namespace TLOptimizer.Launcher;

/// <summary>
/// Representa o manifesto de atualização servido pelo servidor.
/// </summary>
public sealed class UpdateManifest
{
    public string Version { get; set; } = "0.0";
    public string Notes { get; set; } = "";
    /// <summary>Lista de arquivos relativos (em scripts/) que compõem o otimizador.</summary>
    public List<string> Files { get; set; } = new();
    /// <summary>Bloco de atualização do próprio launcher (app).</summary>
    public LauncherUpdate? Launcher { get; set; }
}

/// <summary>
/// Descreve a atualização disponível do launcher (o próprio executável).
/// </summary>
public sealed class LauncherUpdate
{
    public string Version { get; set; } = "0.0";
    public string MinVersion { get; set; } = "0.0";
    public bool Mandatory { get; set; }
}

/// <summary>
/// Gerencia verificação e aplicação de atualizações do otimizador.
/// O launcher em si é atualizado via instalador/auto-update do Windows; aqui
/// cuidamos apenas dos arquivos do PowerShell que rodam em segundo plano.
/// </summary>
internal static class UpdateManager
{
    public static async Task<UpdateManifest?> FetchManifestAsync(HttpClient client, IProgress<string>? log = null)
    {
        try
        {
            log?.Report("Verificando atualizações...");
            var json = await client.GetStringAsync(AppConfig.UpdateManifestUrl);
            var manifest = JsonSerializer.Deserialize<UpdateManifest>(json);
            return manifest;
        }
        catch (Exception ex)
        {
            log?.Report($"Falha ao verificar atualização: {ex.Message}");
            return null;
        }
    }

    public static string GetInstalledVersion()
    {
        try
        {
            if (File.Exists(AppConfig.VersionFile))
                return File.ReadAllText(AppConfig.VersionFile).Trim();
        }
        catch { }
        return "0.0";
    }

    /// <summary>
    /// Baixa apenas os arquivos cuja versão remota é maior que a instalada.
    /// Retorna true se houve atualização aplicada.
    /// </summary>
    public static async Task<bool> ApplyUpdateAsync(HttpClient client, UpdateManifest manifest, IProgress<string>? log = null)
    {
        if (manifest is null) return false;

        var installed = GetInstalledVersion();
        if (CompareVersions(manifest.Version, installed) <= 0)
        {
            log?.Report("Otimizador já está atualizado.");
            return false;
        }

        Directory.CreateDirectory(AppConfig.InstallDir);

        log?.Report($"Atualizando otimizador para v{manifest.Version}...");
        foreach (var file in manifest.Files)
        {
            var url = AppConfig.FilesBaseUrl + file;
            var dest = Path.Combine(AppConfig.InstallDir, file);
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                var content = await client.GetStringAsync(url);
                await File.WriteAllTextAsync(dest, content);
                log?.Report($"  ✓ {file}");
            }
            catch (Exception ex)
            {
                log?.Report($"  ✗ {file} ({ex.Message})");
            }
        }

        await File.WriteAllTextAsync(AppConfig.VersionFile, manifest.Version);
        log?.Report($"Atualizado para v{manifest.Version}.");
        return true;
    }

    /// <summary>
    /// Verifica se há uma versão mais nova do próprio launcher disponível.
    /// Compara a versão atual (AppConfig.LauncherVersion) com o bloco "launcher"
    /// do manifest remoto. Retorna null se não houver atualização.
    /// </summary>
    public static LauncherUpdate? CheckLauncherUpdate(UpdateManifest? manifest)
    {
        if (manifest?.Launcher is null) return null;
        var remote = manifest.Launcher.Version;
        if (CompareVersions(remote, AppConfig.LauncherVersion) <= 0) return null;
        return manifest.Launcher;
    }

    /// <summary>
    /// Baixa o instalador (setup) da nova versão do GitHub e o executa em modo
    /// silencioso para atualizar o programa e, em seguida, reinicia o app.
    /// O processo atual é encerrado antes de rodar o setup.
    /// </summary>
    public static async Task DownloadAndApplyLauncherUpdateAsync(HttpClient client, LauncherUpdate update, IProgress<string>? log = null)
    {
        var url = string.Format(AppConfig.SetupBaseUrl, update.Version);
        var tmp = Path.Combine(Path.GetTempPath(), $"TLOptimizer-Setup-{update.Version}.exe");
        log?.Report($"Baixando atualização v{update.Version}...");
        var bytes = await client.GetByteArrayAsync(url);
        await File.WriteAllBytesAsync(tmp, bytes);
        log?.Report("Instalador baixado. Aplicando e reiniciando...");

        // Executa o setup silenciosamente; ele sobrescreve a instalação atual.
        // O Inno Setup reinicia o app automaticamente se configurado, mas aqui
        // garantimos o encerramento deste processo para evitar arquivos em uso.
        var psi = new ProcessStartInfo
        {
            FileName = tmp,
            Arguments = "/SILENT /NORESTART",
            UseShellExecute = true,
            CreateNoWindow = true
        };
        Process.Start(psi);

        // Encerra este processo para liberar arquivos e deixar o setup assumir.
        Environment.Exit(0);
    }

    /// <summary>Compara duas versões semânticas simples (a.b.c). Retorna -1, 0 ou 1.</summary>
    public static int CompareVersions(string a, string b)
    {
        var pa = (a ?? "0").Split('.').Select(int.Parse).ToArray();
        var pb = (b ?? "0").Split('.').Select(int.Parse).ToArray();
        var len = Math.Max(pa.Length, pb.Length);
        for (var i = 0; i < len; i++)
        {
            var va = i < pa.Length ? pa[i] : 0;
            var vb = i < pb.Length ? pb[i] : 0;
            if (va != vb) return va > vb ? 1 : -1;
        }
        return 0;
    }
}
