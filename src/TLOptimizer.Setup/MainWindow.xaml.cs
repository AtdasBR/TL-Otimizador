using System;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;

namespace TLOptimizer.Setup;

public partial class MainWindow : Window
{
    private int _step;

    public string CurrentStep => _step switch
    {
        0 => "Boas-vindas",
        1 => "Termos de uso",
        2 => "Instalação",
        _ => "Concluído"
    };

    private readonly PageWelcome _welcome = new();
    private readonly PageLicense _license = new();
    private readonly PageInstall _install = new();
    private readonly PageFinish _finish = new();

    public MainWindow()
    {
        InitializeComponent();
        DataContext = this;
        _license.AcceptChanged += () =>
        {
            BtnNext.IsEnabled = _license.Accepted;
            LblStatus.Text = _license.Accepted ? "" : "Marque a aceitação dos termos para continuar";
        };
        _welcome.ModeChanged += () =>
        {
            if (_step == 0)
                BtnNext.Content = _welcome.SelectedMode == SetupMode.Uninstall ? "Desinstalar →" : "Reparar →";
        };
        ShowPage(0);
    }

    private void ShowPage(int step)
    {
        _step = step;
        PageContent.Content = step switch
        {
            0 => _welcome,
            1 => _license,
            2 => _install,
            _ => _finish
        };
        BtnBack.Visibility = step > 0 && step < 3 ? Visibility.Visible : Visibility.Collapsed;
        BtnNext.Content = step switch
        {
            0 when _welcome.IsInstalled => _welcome.SelectedMode == SetupMode.Uninstall ? "Desinstalar →" : "Reparar →",
            0 => "Prosseguir →",
            1 => "Aceitar e instalar",
            2 when _welcome.SelectedMode == SetupMode.Uninstall => "Desinstalando...",
            2 => "Instalando...",
            _ => "Concluir"
        };
        BtnNext.IsEnabled = step switch
        {
            0 => true,
            1 => _license.Accepted,
            2 => false,
            _ => true
        };
        LblStatus.Text = step switch
        {
            0 => "",
            1 => "Leia os termos antes de aceitar",
            2 when _welcome.SelectedMode == SetupMode.Uninstall => "Removendo arquivos...",
            2 => "Copiando arquivos...",
            _ => ""
        };
    }

    private void BtnNext_Click(object sender, RoutedEventArgs e)
    {
        if (_step == 0)
        {
            if (_welcome.IsInstalled)
            {
                ShowPage(2);
                if (_welcome.SelectedMode == SetupMode.Uninstall)
                {
                    LblStatus.Text = "Desinstalando...";
                    _install.StartUninstall(this);
                }
                else
                {
                    LblStatus.Text = "Reparando...";
                    _install.StartInstall(this, isRepair: true);
                }
            }
            else
            {
                ShowPage(1);
            }
        }
        else if (_step == 1) { ShowPage(2); LblStatus.Text = "Instalando..."; _install.StartInstall(this, isRepair: false); }
        else if (_step == 3)
        {
            if (_finish.ChkLaunch.IsChecked == true && _welcome.SelectedMode != SetupMode.Uninstall)
                try { Process.Start(Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                    "TL Optimizer", "TLOptimizer.exe")); } catch { }
            Close();
        }
    }

    private void BtnBack_Click(object sender, RoutedEventArgs e)
    {
        if (_step > 0) ShowPage(_step - 1);
    }

    private void BtnCancel_Click(object sender, RoutedEventArgs e)
    {
        var msg = _welcome.SelectedMode == SetupMode.Uninstall
            ? "Deseja cancelar a desinstalação?"
            : "Deseja cancelar a instalação?";
        if (MessageBox.Show(msg, "TL Optimizer",
                MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes)
            Close();
    }

    public void OnInstallComplete()
    {
        if (_welcome.SelectedMode == SetupMode.Uninstall)
            _finish.SetUninstallMode();
        ShowPage(3);
        BtnNext.Content = "Concluir";
        BtnNext.IsEnabled = true;
    }
}
