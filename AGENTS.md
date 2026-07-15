# AGENTS.md — TL Optimizer

## Inicialização
- Script deve maximizar a janela do console automaticamente (Add-Type + ShowWindow via user32.dll) antes de qualquer output visual.
- BufferSize.Width fixo em 120 colunas.
- Clear-Host antes de renderizar boot/logo/menu.

## Sistema visual (bordas)
- Toda tela usa exclusivamente as 6 funções centrais: Show-TopBorder, Show-MidBorder, Show-BotBorder, Show-SubBorder, Show-BoxLine, Show-BoxTitle. Proibido Write-Host solto desenhando borda própria.
- Bordas duplas (estilo 0x2554), nunca simples.
- Largura calculada dinamicamente com base na maior linha do submenu atual, com teto máximo de 120 colunas.

## Sistema de tema
- Fonte única de cor: $script:c / $Theme. Proibido qualquer -ForegroundColor hardcoded ou ANSI fixo fora dessa fonte.
- Trocar de tema deve forçar redraw completo da tela atual (menu, submenu, boot, mensagens de status) — nada pode ficar preso na cor antiga.

## Metadados de função ($script:FuncInfo)
Toda função de ação/toggle exposta em algum menu PRECISA ter entrada completa nesta estrutura, com os campos:
- NomeExibido → nome em português simples, sem sigla técnica, sem nome cru de serviço do Windows, sem jargão de programador. Nome técnico real fica só no código, nunca na tela.
- Descricao → 1 linha, até ~70 caracteres, explicando o efeito prático (não a implementação).
- ComoUsar → como ativar/desativar ou o que acontece ao confirmar.
- NivelRisco → Seguro | Moderado | Arriscado.
- MotivoRisco → obrigatório se NivelRisco != Seguro; explica o que pode quebrar e como reverter.
Função sem entrada completa = erro visível de desenvolvimento, nunca fallback silencioso.

## Fluxo de execução por risco
- Seguro → executa direto, sem confirmação extra.
- Moderado/Arriscado → mostra MotivoRisco e pede confirmação (S/N) antes de executar. Cancelar não pode ter nenhum efeito colateral.
- Comando "?N" disponível em toda opção, mostrando descrição completa sem executar nada.

## Layout de texto longo
- Truncar com "..." é último recurso, nunca solução padrão.
- Ordem de resolução: (1) borda dinâmica, (2) quebrar NomeExibido em duas linhas dentro da opção, (3) truncar — e só truncar se o "?N" já garantir acesso ao texto completo.

## Convenção de nomenclatura de funções
- `Show-*` → renderização de tela/submenu (nunca modifica estado).
- `Run-*` → abre submenu interativo com opções (ex: Run-Rede, Run-Visual).
- `Tweak-*` → ação única de tweak via registro/serviço (ex: Tweak-Hibernation).
- `Clear-*` → limpeza de cache/log/arquivos temporários.
- `Set-*` → configuração pontual (DNS, plano de energia).
- `Undo-*` → reversão de alterações via backup salvo.
- `Backup-*` → salva estado anterior antes de qualquer modificação (JSON em $backupDir).

## Backup antes de modificar sistema
- Toda função que altera registro, serviço, rede ou visual DEVE chamar a função `Backup-*` correspondente antes de qualquer modificação.
- Backups são salvos em JSON no diretório $backupDir e usados pelo sistema Undo.

## Log-Tweak obrigatório
- Toda ação executada deve chamar `Log-Tweak` para registrar no histórico de undo. Isso alimenta o `Show-UndoLog` e o sistema de reversão individual.

## Wait-Key ao final
- Toda ação de mão única (não submenu) termina com `Wait-Key` — o usuário precisa ver o resultado antes de voltar ao menu.

## Escopo $script:
- Toda variável global (tema, config, backupDir, tweakLog, versao, FuncInfo) usa `$script:` — proibido variável solta no escopo global sem prefixo.

## Submenu data flow (Show-GenericoSubmenu)
1. Caller cria array de hashtables: `$itens = @(@{Nome="X"; Selected=$true})`.
2. Passa para `Show-GenericoSubmenu -Itens $itens`, que renderiza com base em `$script:FuncInfo[$item.Nome]`.
3. Retorna `$itens` com `Selected` atualizado pelo usuário.
4. Caller itera `Where-Object { $_.Selected }` aplicando a ação correspondente ao `$_.Nome`.

## Tratamento de erro
- Toda função que mexe em registro, serviço, arquivo do sistema ou app UWP precisa de try/catch — proibido falha silenciosa.
- Variáveis usadas dentro de try devem ser inicializadas antes (ex: $null) para não quebrar o catch/finally.

## Checklist obrigatório antes de declarar qualquer feature concluída
1. Parse/syntax check sem erros.
2. Nenhuma cor hardcoded fora de $script:c/$Theme.
3. Nenhuma função nova sem entrada completa em $script:FuncInfo.
4. Nenhum nome exibido com sigla técnica ou jargão.
5. Nenhuma linha estourando a largura de 120 colunas sem passar pela ordem de resolução acima.
6. Simulação de navegação confirmando que a opção nova não quebra o submenu onde foi inserida.
7. Relatório indicando explicitamente se algum item acima não pôde ser cumprido, e por quê — nunca omitir.
