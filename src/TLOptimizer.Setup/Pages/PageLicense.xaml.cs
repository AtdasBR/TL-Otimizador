using System;
using System.Windows.Controls;

namespace TLOptimizer.Setup;

public partial class PageLicense : UserControl
{
    public bool Accepted => ChkAccept.IsChecked == true;
    public event Action? AcceptChanged;

    public PageLicense()
    {
        InitializeComponent();
        TxtTerms.Text = """
TERMOS DE USO E RESPONSABILIDADE — TL OPTIMIZER

1. CIÊNCIA DO USUÁRIO
   Ao utilizar este software, você declara estar ciente de
   que ele realiza alterações no sistema operacional Windows.

2. CLASSIFICAÇÃO DAS AÇÕES
   • RECOMENDADAS (verde)  — Alterações seguras, baixo risco
   • MEDIANAS (amarelo)    — Impacto moderado, leia a descrição
   • CRÍTICAS (vermelho)   — Apenas para usuários experientes

3. ISENÇÃO DE RESPONSABILIDADE
   O usuário assume TOTAL responsabilidade por qualquer dano
   ou perda de dados decorrente do uso deste software.

4. RECOMENDAÇÕES
   • Faça backup completo antes de ações críticas
   • Crie um ponto de restauração do Windows antes de usar
   • Leia a descrição de cada ação antes de ativá-la
   • A execução requer privilégios de administrador

5. PRIVACIDADE
   Este software NÃO coleta, armazena ou transmite dados
   pessoais do usuário.

6. SUPORTE
   https://github.com/AtdasBR/TL-Otimizador
""";
    }

    private void OnAcceptChanged(object sender, System.Windows.RoutedEventArgs e)
    {
        AcceptChanged?.Invoke();
    }
}
