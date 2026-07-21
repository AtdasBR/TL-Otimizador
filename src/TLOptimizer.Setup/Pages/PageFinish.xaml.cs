using System.Windows.Controls;

namespace TLOptimizer.Setup;

public partial class PageFinish : UserControl
{
    public PageFinish() => InitializeComponent();

    public void SetUninstallMode()
    {
        LblIcon.Text = "✗";
        LblIcon.Foreground = System.Windows.Media.Brushes.White;
        LblTitle.Text = "Desinstalação concluída!";
        LblDesc.Text = "O TL Optimizer foi removido do seu computador.";
        LblOQueFazer.Text = "Obrigado por usar o TL Optimizer:";
        TxtItem1.Text = "Se precisar, reinstale quando quiser";
        TxtItem2.Text = "Suas configurações foram preservadas";
        ChkLaunch.Visibility = System.Windows.Visibility.Collapsed;
    }
}
