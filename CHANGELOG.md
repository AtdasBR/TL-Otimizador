# Changelog

## 1.7.2 — Auto-atualização do launcher
- Ao abrir, o app verifica se há versão nova do **próprio programa** (bloco
  `launcher` do `update-manifest.json`).
- Se houver, exibe um prompt (Sim/Não): "Nova versão disponível — atualizar agora?".
- Ao confirmar, baixa o `TLOptimizer-Setup-{versao}.exe` do GitHub Release,
  roda em modo silencioso (`/SILENT`) e reinicia o app automaticamente.
- `AppConfig.SetupBaseUrl` aponta para
  `https://github.com/AtdasBR/TL-Otimizador/releases/download/v{0}/TLOptimizer-Setup-{0}.exe`.
- Requer um Release publicado no GitHub com a tag `vX.Y.Z` e o setup correspondente.

## 1.7.1 — Atualização definitiva de design (Plus)
- **Visual profissional** preto/branco/cinza estilo Fluent (paleta com profundidade).
- **Sidebar** com marca em gradiente branco e itens ativos em "pill" branco.
- **Cards** com cantos suaves (raio 12), leve realce de vidro no topo, hover-lift
  e borda branca de 2px na seleção.
- **Dashboard de métricas ao vivo** no Gerenciador de Aplicativos: tiles
  CPU / Memória / Disco / Instalados (atualização a cada 1,5s).
- Header do instalador com subtítulo descritivo e painel de métricas à direita.
- Catálogo de **253 apps** com logos oficiais (Simple Icons vetorial / favicon)
  e IDs WinGet confirmados.
- Filtro "Instalados" (mostra só programas já instalados).

## 1.7.0
- Adição em massa de apps sugeridos (Dev, Games, Pro Tools, Multimídia, Utils).
- Exclusão de SpaceSniffer (sem logo acessível).

## 1.6.1
- Filtro "Instalados" no Gerenciador de Aplicativos.

## 1.6.0
- Catálogo massivo de apps (Games, Microsoft Tools, Multimídia, Pro Tools,
  Selfhosted, Utilities) com logos e IDs WinGet validados.

## 1.5.0
- Recuperação de apps com logo de qualidade (Waterfox, Zen, Slack, Teams,
  Proton Mail, Dorion, Oh My Posh, uv, System Informer, VS2022/2026, ChatGPT,
  Codex, Helium, etc.). Remoção de apps sem logo/ID confiável.

## 1.4.x
- Gerenciador de Aplicativos via WinGet/Chocolatey com logos vetoriais.
- Instalador Inno Setup e update-manifest versionados.
