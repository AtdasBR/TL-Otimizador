# TL Optimizer — Arquitetura

Projeto profissional no estilo Chris Titus WinUtil, composto por 3 camadas
bem separadas para facilitar manutenção e atualizações sem reinstalar.

```
TL-Otimizador/
├── scripts/                       # Arquivos do OTIMIZADOR (PowerShell)
│   └── otimizar-windows.ps1       #   Script principal (já existente, ~2990 linhas)
├── src/TLOptimizer.Launcher/     # LAUNCHER em C# (.NET 8, WinForms)
│   ├── TLOptimizer.Launcher.csproj
│   ├── Program.cs                 #   Entry point / orquestração
│   ├── SplashForm.cs              #   Splash screen com barra de progresso
│   ├── UpdateManager.cs           #   Verifica/aplica atualizações do PS
│   ├── PowerShellRunner.cs        #   Executa o PS em segundo plano
│   ├── AppConfig.cs               #   Constantes (URLs, versões, caminhos)
│   ├── app.manifest               #   Manifesto Windows (estilo moderno)
│   └── icon.ico                   #   Ícone do app
├── deploy/                        # ARQUIVOS DE DISTRIBUIÇÃO
│   ├── update-manifest.json       #   Manifesto de atualização (servido no GitHub)
│   ├── icon.ico
│   └── tloptimizer.iss            #   Script do Inno Setup (instalador)
├── build/
│   ├── publish/                   #   Saída do dotnet publish (launcher + scripts)
│   └── installer/                 #   Saída do ISCC (TLOptimizer-Setup-x.y.z.exe)
└── build/build.bat                # Script de build automatizado
```

## Fluxo de execução

1. O usuário abre o atalho (Área de Trabalho / Menu Iniciar) → `TLOptimizer.exe`.
2. O launcher mostra a **splash screen** com barra de progresso.
3. Verifica `deploy/update-manifest.json` (remoto) e compara com a versão
   instalada em `%LOCALAPPDATA%\TLOptimizer\version.txt`.
4. Se houver versão nova, baixa **apenas os arquivos alterados** (o `.ps1`)
   para `%LOCALAPPDATA%\TLOptimizer\`.
5. Abre a **interface WinForms nativa** (`MainForm`) com visual profissional
   preto/branco/cinza (estilo Fluent): sidebar com navegação, abas por
   categoria (Limpeza, Tweaks, Rede, Visual, Privacidade, Sistema), cards
   arredondados com indicador de risco (verde/amarelo/vermelho), painel de log,
   e a seção **Gerenciador de Aplicativos** — com dashboard de métricas ao vivo
   (CPU/Memória/Disco/Instalados), busca, filtros por categoria e por
   "Instalados", e instalação/atualização/remoção em lote via WinGet/Chocolatey
   usando logos oficiais dos apps.
6. Ao clicar numa ação, o launcher chama o PowerShell em **modo headless**
   (`otimizar-windows.ps1 -Headless -Acao <id>`) — sem nenhuma janela de cmd —
   e exibe a saída no painel de log da própria janela.

> O otimizador original (menu interativo em console) continua funcional se o
> `.ps1` for executado diretamente. O modo `-Headless` é usado apenas pela UI.

## Atualizações

- **Launcher (C#):** atualizado via reinstalação do setup ou auto-update do
  Windows (futuro).
- **Otimizador (PS):** atualizado automaticamente pelo próprio launcher em
  runtime, sem reinstalar o programa. Basta subir novo `otimizar-windows.ps1`
  + `update-manifest.json` no repositório.

### Para lançar uma nova versão do otimizador
1. Edite `scripts/otimizar-windows.ps1`.
2. Suba para o repo (`master`).
3. Atualize `deploy/update-manifest.json` → `"version": "X.Y"`.
4. Pronto — o launcher de todos os usuários baixa sozinho na próxima abertura.

## Build

Requer: .NET 8 SDK + Inno Setup 6.

```bat
build\build.bat              :: compila o launcher (publish self-contained)
ISCC.exe deploy\tloptimizer.iss   :: gera o instalador
```

Ou manualmente:
```bat
dotnet publish src\TLOptimizer.Launcher\TLOptimizer.Launcher.csproj ^
  -c Release -o build\publish -p:PublishSingleFile=true ^
  -p:SelfContained=true -p:RuntimeIdentifier=win-x64
```
