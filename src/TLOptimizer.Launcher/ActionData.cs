namespace TLOptimizer.Launcher;

public sealed record ActionInfo(
    string Detalhes,
    bool DefaultLigado,
    string? Pros = null,
    string? Contras = null,
    bool HasToggle = true
);

internal static class ActionData
{
    public static ActionInfo Get(string id, string nome, string desc, string risco)
    {
        if (_explicit.TryGetValue(id, out var info)) return info;
        return new ActionInfo(
            Detalhes: GerarDetalhes(nome, desc, risco),
            DefaultLigado: risco != "Arriscado",
            Pros: GerarPros(nome, risco),
            Contras: GerarContras(nome, risco),
            HasToggle: !_apenasExecutar.Contains(id)
        );
    }

    private static string GerarDetalhes(string nome, string desc, string risco)
    {
        var nivel = risco switch
        {
            "Seguro" => "operação segura e recomendada",
            "Moderado" => "operação moderada — requer atenção",
            "Arriscado" => "operação avançada — pode afetar o sistema",
            _ => "operação do sistema"
        };
        return $"{desc}.\n\nEsta é uma {nivel}. ";
    }

    private static string GerarPros(string nome, string risco)
    {
        return risco switch
        {
            "Seguro" => "Melhora o desempenho do sistema.\nOperação segura e reversível.\nRecomendado para todos os usuários.",
            "Moderado" => "Pode melhorar o desempenho.\nResultados visíveis em tarefas específicas.\nGeralmente seguro.",
            "Arriscado" => "Pode trazer ganhos de desempenho significativos.\nAjuda em cenários específicos.\nRecomendado para usuários avançados.",
            _ => "Operação padrão do sistema."
        };
    }

    private static string GerarContras(string nome, string risco)
    {
        return risco switch
        {
            "Seguro" => "Nenhum efeito colateral significativo.\nPode exigir reinicialização para aplicar.",
            "Moderado" => "Pode causar pequenas alterações no comportamento do sistema.\nAlgumas funcionalidades podem ser afetadas.\nRecomenda-se criar um ponto de restauração antes.",
            "Arriscado" => "Pode causar instabilidade no sistema.\nAlgumas funcionalidades podem parar de funcionar.\nRecomenda-se fortemente criar backup antes.\nNão recomendado em máquinas de produção.",
            _ => "Sem efeitos colaterais conhecidos."
        };
    }

    private static readonly HashSet<string> _apenasExecutar = new()
    {
        "1","6","7","10","12","13","30","31","32","33","34","35","36",
        "41","52","53","54","55","59","60","61","67","94"
    };

    private static readonly Dictionary<string, ActionInfo> _explicit = new()
    {
        ["17"] = new(
            "Remove arquivos de cache do jogo FiveM (GTA RP), incluindo logs antigos, arquivos temporários de servidores e dados de atualização que acumulam com o tempo de uso.",
            true,
            "Libera vários GB de espaço em disco.\nMelhora o tempo de carregamento do jogo.\nSeguro — o jogo recria o cache automaticamente.",
            "Na próxima vez que jogar, texturas e assets serão baixados novamente.\nPrimeira execução após limpeza pode ser mais lenta.",
            HasToggle: false
        ),
        ["11"] = new(
            "Apaga arquivos temporários do sistema Windows que não estão em uso, incluindo logs de atualizações antigas, arquivos de instalação temporários e cache de componentes.",
            true,
            "Libera espaço em disco imediatamente.\nRemove arquivos desnecessários.\nO Windows recria o que precisar.",
            "Pode remover arquivos temporários de programas abertos.\nFeche programas importantes antes de executar.",
            HasToggle: false
        ),
        ["14"] = new(
            "Limpeza profunda que inclui cache de drivers, fontes não usadas, prefetch, Native Images (NGEN), cache do Windows Installer, assembly cache e muito mais. A limpeza mais completa disponível.",
            false,
            "Libera a maior quantidade de espaço possível.\nRemove resquícios profundos de programas desinstalados.\nLimpa arquivos esquecidos de atualizações antigas do Windows.",
            "Pode tornar a inicialização de programas mais lenta temporariamente (cache sendo reconstruído).\nNão recomendado para usuários inexperientes.\nPode remover fontes instaladas manualmente.",
            HasToggle: false
        ),
        ["15"] = new(
            "Abre a ferramenta interna de Limpeza de Disco do Windows (CleanMgr), permitindo selecionar visualmente quais categorias de arquivos limpar, como arquivos de atualização, lixeira, miniaturas e muito mais.",
            true,
            "Interface visual fácil de usar.\nVocê escolhe exatamente o que limpar.\nFerramenta nativa do Windows.",
            "Não automatiza — você precisa clicar manualmente.\nAlgumas opções podem exigir privilégios de administrador.",
            HasToggle: false
        ),
        ["16"] = new(
            "Executa SFC (System File Checker) e DISM (Deployment Imaging Service) para verificar a integridade de todos os arquivos protegidos do sistema e reparar arquivos corrompidos ou ausentes.",
            true,
            "Repara arquivos corrompidos do Windows.\nRestaura a estabilidade do sistema.\nResolve problemas de tela azul e travamentos.",
            "Pode demorar de 15 a 30 minutos.\nPode exigir reinicialização.\nEm casos extremos, pode solicitar mídia de instalação.",
            HasToggle: false
        ),
        ["8"] = new(
            "Remove aplicativos UWP pré-instalados no Windows (bloatware) como Xbox, Skype, OneDrive, Solitaire, Mixed Reality e outros apps que vêm instalados de fábrica.",
            false,
            "Libera espaço em disco significativo.\nRemove programas desnecessários.\nReduz o consumo de recursos do sistema.",
            "Alguns apps removidos podem ser difíceis de reinstalar.\nPode remover apps que você usa sem perceber.\nAfeta apenas usuários que criarem novas contas.",
            HasToggle: false
        ),
        ["4"] = new(
            "Ajusta o tamanho do arquivo de paginação (memória virtual) para otimizar o desempenho. O Windows gerencia automaticamente, mas um ajuste manual pode melhorar a performance em sistemas com pouca RAM.",
            false,
            "Pode melhorar o desempenho em sistemas com 8 GB ou menos de RAM.\nEvita erros de memória insuficiente.\nÚtil para jogos e edição de vídeo.",
            "Configuração incorreta pode causar instabilidade.\nTamanho muito pequeno pode causar erros de memória.\nTamanho muito grande desperdiça espaço em disco.",
            HasToggle: false
        ),
        ["93"] = new(
            "Desativa completamente o Windows Update, impedindo que o sistema baixe e instale atualizações automaticamente. O sistema ficará isolado sem receber correções de segurança.",
            false,
            "Evita reinicializações inesperadas.\nÚtil em sistemas que precisam ficar ligados por dias.\nEconomiza banda de internet.",
            "O sistema ficará vulnerável a ameaças de segurança.\nPerde correções importantes de bugs.\nRecomenda-se reativar após o período desejado."
        ),
        ["95"] = new(
            "Desativa o Windows Defender (Microsoft Defender Antivirus), incluindo proteção em tempo real, varredura periódica e proteção contra ameaças.",
            false,
            "Melhora o desempenho em sistemas com pouco recurso.\nEvita falsos positivos em certos programas.\nÚtil para usuários com antivírus de terceiros.",
            "O sistema fica desprotegido contra ameaças.\nAlta probabilidade de infecção por malware.\nRecomenda-se apenas se houver outro antivírus instalado."
        ),
    };
}
