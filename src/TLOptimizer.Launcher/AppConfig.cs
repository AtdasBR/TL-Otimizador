namespace TLOptimizer.Launcher;

/// <summary>
/// Configuração central do launcher. Centraliza URLs, versões e caminhos
/// para facilitar manutenção e futuras atualizações.
/// </summary>
internal static class AppConfig
{
    /// <summary>Versão atual do launcher (deve bater com o .csproj).</summary>
    public const string LauncherVersion = "1.7.2";

    /// <summary>Versão mínima aceita do otimizador.</summary>
    public const string OptimizerMinVersion = "1.4";

    /// <summary>
    /// URL do manifest de atualização. Deve ser um JSON acessível publicamente
    /// (GitHub raw, seu site, etc). Veja implantacao/update-manifest.json.
    /// </summary>
    public const string UpdateManifestUrl =
        "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/implantacao/update-manifest.json";

    /// <summary>URL base onde os arquivos do otimizador são hospedados.</summary>
    public const string FilesBaseUrl =
        "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/scripts/";

    /// <summary>
    /// URL base dos instaladores publicados nos Releases do GitHub.
    /// O arquivo segue o padrão TLOptimizer-Setup-{version}.exe.
    /// </summary>
    public const string SetupBaseUrl =
        "https://github.com/AtdasBR/TL-Otimizador/releases/download/v{0}/TLOptimizer-Setup-{0}.exe";

    /// <summary>Nome do script principal do otimizador.</summary>
    public const string OptimizerScriptName = "otimizar-windows.ps1";

    /// <summary>Pasta local onde o otimizador é instalado/atualizado.</summary>
    public static string InstallDir =>
        Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "TLOptimizer");

    /// <summary>Caminho completo do script do otimizador.</summary>
    public static string OptimizerScriptPath =>
        Path.Combine(InstallDir, OptimizerScriptName);

    /// <summary>Arquivo local que guarda a versão do otimizador instalado.</summary>
    public static string VersionFile => Path.Combine(InstallDir, "version.txt");
}
