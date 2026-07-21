using System;
using System.IO;
using System.Windows.Controls;

namespace TLOptimizer.Setup;

public enum SetupMode { Install, Repair, Uninstall }

public partial class PageWelcome : UserControl
{
    public bool IsInstalled { get; private set; }
    public SetupMode SelectedMode { get; private set; } = SetupMode.Install;
    public Action? ModeChanged;

    public PageWelcome()
    {
        InitializeComponent();
        DetectInstallation();
    }

    private void DetectInstallation()
    {
        var appDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            "TL Optimizer");
        IsInstalled = File.Exists(Path.Combine(appDir, "TLOptimizer.exe"));

        if (IsInstalled)
        {
            Titulo.Text = "TL Optimizer já está instalado";
            Descricao.Text = "O que você deseja fazer?";
            BoxRecursos.Visibility = System.Windows.Visibility.Collapsed;
            BoxInstalado.Visibility = System.Windows.Visibility.Visible;
            SelectedMode = SetupMode.Repair;
        }
    }

    private void OnModoChanged(object sender, System.Windows.RoutedEventArgs e)
    {
        if (!IsLoaded) return;
        SelectedMode = OptDesinstalar.IsChecked == true ? SetupMode.Uninstall : SetupMode.Repair;
        ModeChanged?.Invoke();
    }
}
