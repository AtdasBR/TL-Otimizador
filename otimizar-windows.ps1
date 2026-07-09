$ErrorActionPreference = "Continue"
$backupDir = "$env:LOCALAPPDATA\Otimizador"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$scriptUrl = "https://is.gd/tlotimizador"
$rawUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/otimizar-windows.ps1"
$script:versao = "1.2"

$script:temaArquivo = "$backupDir\tema.json"
$script:temas = @{
    Padrao = @{ Cyan = "Cyan"; DarkCyan = "DarkCyan"; DarkGray = "DarkGray"; Gray = "Gray"; Green = "Green"; Magenta = "Magenta"; Red = "Red"; White = "White"; Yellow = "Yellow" }
    Claro  = @{ Cyan = "DarkBlue"; DarkCyan = "Blue"; DarkGray = "DarkGray"; Gray = "DarkGray"; Green = "DarkGreen"; Magenta = "DarkMagenta"; Red = "Red"; White = "Black"; Yellow = "DarkYellow" }
    Matrix = @{ Cyan = "Green"; DarkCyan = "DarkGreen"; DarkGray = "DarkGreen"; Gray = "Green"; Green = "Green"; Magenta = "Green"; Red = "Red"; White = "Green"; Yellow = "Yellow" }
    Synthwave = @{ Cyan = "Cyan"; DarkCyan = "Magenta"; DarkGray = "DarkMagenta"; Gray = "Cyan"; Green = "Green"; Magenta = "Magenta"; Red = "Red"; White = "White"; Yellow = "Yellow" }
}
$script:temaAtual = "Padrao"
$script:c = $script:temas.Padrao.Clone()
$script:carregouTema = $false

function CarregarTema {
    if (Test-Path $script:temaArquivo) {
        try {
            $dados = Get-Content $script:temaArquivo -Raw | ConvertFrom-Json
            $script:temaAtual = $dados.Tema
            if ($script:temas.ContainsKey($script:temaAtual)) {
                $script:c = $script:temas[$script:temaAtual].Clone()
            } else { $script:c = $script:temas.Padrao.Clone(); $script:temaAtual = "Padrao" }
        } catch { $script:c = $script:temas.Padrao.Clone(); $script:temaAtual = "Padrao" }
    } else { $script:c = $script:temas.Padrao.Clone() }
}
function SalvarTema {
    @{ Tema = $script:temaAtual } | ConvertTo-Json | Set-Content $script:temaArquivo -Force
}
function EscolherTema {
    $lista = @()
    $temp = 1
    foreach ($t in $script:temas.Keys | Sort-Object) {
        $marcador = if ($t -eq $script:temaAtual) { "[X]" } else { "[ ]" }
        $lista += "$("{0,2}" -f $temp). $marcador $t"
        $temp++
    }
    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=46
        $top = "  $([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$("$h"*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$("$h"*$w)$([char]0x255D)"
        Write-Host $top -ForegroundColor $script:c.Cyan
        Write-Host "  $v  Digite NUMERO para escolher o tema         $v" -ForegroundColor $script:c.DarkCyan
        Write-Host $sep -ForegroundColor $script:c.Cyan
        $temp = 1
        foreach ($t in $script:temas.Keys | Sort-Object) {
            $marcador = if ($t -eq $script:temaAtual) { "[X]" } else { "[ ]" }
            $corItem = if ($t -eq $script:temaAtual) { $script:c.Green } else { $script:c.DarkGray }
            Write-Host "  $v  $("{0,2}" -f $temp). $marcador $("{0,-20}" -f $t)     $v" -ForegroundColor $corItem
            $temp++
        }
        Write-Host $bot -ForegroundColor $script:c.Cyan
        Write-Host ""
        $choice = Read-Host "Numero (ou V para voltar)"
        if ($choice -eq "V" -or $choice -eq "v") { SalvarTema; return }
        $num = [int]::TryParse($choice, [ref]$null)
        if ($num -and [int]$choice -ge 1 -and [int]$choice -le $script:temas.Count) {
            $chaves = @($script:temas.Keys | Sort-Object)
            $script:temaAtual = $chaves[[int]$choice - 1]
            $script:c = $script:temas[$script:temaAtual].Clone()
            SalvarTema
            Write-Host "Tema alterado para: $($script:temaAtual)" -ForegroundColor $script:c.Green
            Start-Sleep 1
        }
    } while ($true)
}

function VerificarAtualizacao {
    param([switch]$Silencioso)
    try {
        $resp = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -ErrorAction Stop
        if ($resp.Content -match '\$script:versao\s*=\s*"([^"]+)"') {
            $novaVer = $Matches[1]
            if ($novaVer -ne $script:versao) {
                Write-Host "Nova versao ($novaVer) disponivel!" -ForegroundColor $script:c.Yellow
                if ($PSCommandPath) {
                    Write-Host "Atualizando..." -NoNewline
                    [System.IO.File]::WriteAllText($PSCommandPath, $resp.Content, [System.Text.UTF8Encoding]::new($false))
                    Write-Host " OK" -ForegroundColor $script:c.Green
                    Write-Host "Execute 'tl' novamente para usar a nova versao." -ForegroundColor $script:c.Green
                } else {
                    Write-Host "Reexecute o comando abaixo para obter a nova versao:" -ForegroundColor $script:c.Yellow
                    Write-Host "  iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.Cyan
                }
                Start-Sleep -Seconds 3; exit
            } elseif (-not $Silencioso) {
                Write-Host "Voce ja esta na versao mais recente ($script:versao)." -ForegroundColor $script:c.Green
            }
        } elseif (-not $Silencioso) {
            Write-Host "Nao foi possivel ler a versao remota." -ForegroundColor $script:c.Yellow
        }
    } catch { if (-not $Silencioso) { Write-Host "Falha na conexao: $($_.Exception.Message)" -ForegroundColor $script:c.Red } }
}

function Get-SystemSpecs {
    if (-not $script:specsCache) {
        try { $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption -replace 'Microsoft ','' } catch { $os = "Windows" }
        try { $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop).Name -replace '\s+',' ' } catch { $cpu = "N/A" }
        try { $cores = (Get-CimInstance Win32_Processor -ErrorAction Stop).NumberOfCores } catch { $cores = 0 }
        try { $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB, 1) } catch { $ram = "N/A" }
        try { $gpu = ((Get-CimInstance Win32_VideoController -ErrorAction Stop).Name -join ', ') } catch { $gpu = "N/A" }
        $discos = @()
        try { 
            $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
            foreach ($d in $drives) {
                $total = [math]::Round($d.Size/1GB)
                $livre = [math]::Round($d.FreeSpace/1GB)
                $pct = [math]::Round(($total - $livre) / $total * 100)
                $cheio = [math]::Round($pct / 100 * 8)
                $bar = "$([char]0x2588)" * [Math]::Min($cheio, 8) + "$([char]0x2591)" * (8 - [Math]::Min($cheio, 8))
                $discos += @{ Letra = $d.DeviceID -replace ':'; Total = $total; Livre = $livre; Pct = $pct; Bar = $bar }
            }
        } catch { $discos = @() }
        try { $tpm = if ((Get-CimInstance Win32_Tpm -ErrorAction Stop).IsEnabled_InitialValue -eq $true) { "2.0" } else { "Ausente" } } catch { $tpm = "N/A" }
        try { $net4 = if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction Stop).Install -eq 1) { "Ativado" } else { "Ausente" } } catch { $net4 = "N/A" }
        try { $fuso = (Get-TimeZone).DisplayName -replace '.*UTC.*UTC','UTC' } catch { $fuso = "N/A" }
        $script:specsCache = @{ OS = $os; CPU = "$cpu ($cores nucleos)"; RAM = "$ram GB"; GPU = $gpu; Discos = $discos; Usuario = $env:USERNAME; PC = $env:COMPUTERNAME; TPM = $tpm; Net4 = $net4; Fuso = $fuso }
    }
    try { $ramLivre = [math]::Round((Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory / 1MB, 1) } catch { $ramLivre = 0 }
    try {
        $boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
        $uptime = [DateTime]::Now - $boot
        $dias = $uptime.Days; $horas = $uptime.Hours
        $uptimeStr = if ($dias -gt 0) { "$dias dia(s) $horas h" } else { "$horas h" }
    } catch { $uptimeStr = "N/A" }
    return @{ OS = $script:specsCache.OS; CPU = $script:specsCache.CPU; RAM = "$($script:specsCache.RAM) ($ramLivre GB livre)"; GPU = $script:specsCache.GPU; Discos = $script:specsCache.Discos; Uptime = $uptimeStr; Usuario = $script:specsCache.Usuario; PC = $script:specsCache.PC; TPM = $script:specsCache.TPM; Net4 = $script:specsCache.Net4; Fuso = $script:specsCache.Fuso }
}

function Show-Banner {
    Clear-Host
    $t=[char]0x2554;$r=[char]0x2557;$b=[char]0x255A;$e=[char]0x255D;$h=[char]0x2550;$v=[char]0x2551
    $ln = "  $t$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    Write-Host $ln -ForegroundColor $script:c.Cyan
    Write-Host "  $v            TL OPTIMIZER                $v" -ForegroundColor $script:c.Cyan
    Write-Host "  $v              v$($script:versao)                    $v" -ForegroundColor $script:c.DarkGray
    Write-Host ($ln -replace $t,$b -replace $r,$e) -ForegroundColor $script:c.Cyan
    Write-Host ""
}
function Show-Help {
    Clear-Host
    $c=[char]0x250C;$h=[char]0x2500;$v=[char]0x2502;$b=[char]0x2514;$r=[char]0x2510;$e=[char]0x2518
    $top = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    $sep = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    $bot = "  $b$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$e"

    Write-Host $top -ForegroundColor $script:c.Cyan
    Write-Host "  $v  ### O QUE CADA OPCAO FAZ ###                    $v" -ForegroundColor $script:c.White
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   1. LIMPEZA RAPIDA                               $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Apaga arquivos temporarios e libera espaco no   $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   disco. Leve e seguro, pode fazer sem medo.      $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   2. LIMPEZA PROFUNDA                             $v" -ForegroundColor $script:c.Magenta
    Write-Host "  $v   Uma limpeza mais forte que libera varios GBs.   $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   Remove cache de programas, logs antigos e mais. $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   3. DESLIGAR SERVICOS                            $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Mostra uma lista de servicos do Windows.        $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   Digite o NUMERO para marcar/desmarcar.          $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   [X] = vai ser desligado | [ ] = vai ser ligado  $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   [A] Aplica | [T] Marca tudo | [V] Voltar                $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   4. MELHORAR INTERNET                            $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Troca o DNS para Cloudflare (mais rapido),      $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   reseta a placa de rede e ajusta conexao.        $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   Desmarcou um item? Ele volta ao normal.         $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   5. ACELERAR VISUAL                              $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Desliga animacoes, transparencia e efeitos.     $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   O Windows fica mais leve, principalmente em     $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   PCs mais antigos. Desmarcou, volta ao original. $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   6. EXECUTAR TUDO                                $v" -ForegroundColor $script:c.Magenta
    Write-Host "  $v   Roda as opcoes 3, 4 e 5 de uma vez so, com     $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   tudo marcado. Nao precisa ficar escolhendo.     $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   7. PONTO DE RESTAURACAO                         $v" -ForegroundColor $script:c.Yellow
    Write-Host "  $v   Cria um ponto no Windows pra voltar atras       $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   se algo der errado. Faca antes de mexer.        $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   8, 9, 10. DESFAZER                              $v" -ForegroundColor $script:c.Cyan
    Write-Host "  $v   Restaura o que foi alterado em cada categoria   $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   usando o backup salvo automaticamente.          $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   11. GERENCIAR NAVEGADORES                        $v" -ForegroundColor $script:c.Yellow
    Write-Host "  $v   Detecta navegadores instalados e permite         $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   desinstalar varios de uma vez.                    $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   12. DESINSTALADOR UNIVERSAL                       $v" -ForegroundColor $script:c.Magenta
    Write-Host "  $v   Lista todos os programas instalados, desinstala    $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   e limpa arquivos e registros residuais.            $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   13. DRIVER UPDATER                                 $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Baixa instaladores de Driver Easy, Driver Booster   $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   e Snappy Driver Installer Lite.                     $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   14. VERIFICAR ATUALIZACAO                           $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   Checa se ha versao nova no GitHub e baixa            $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   automaticamente.                                     $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   15. ESCOLHER TEMA                                    $v" -ForegroundColor $script:c.Yellow
    Write-Host "  $v   Altera as cores do otimizador. Temas:                $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   Padrao, Claro, Matrix, Synthwave.                    $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v   16. AJUDA (esta tela)                                $v" -ForegroundColor $script:c.Yellow
    Write-Host "  $v   0. SAIR                                         $v" -ForegroundColor $script:c.Red
    Write-Host $bot -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "  Como usar: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.Cyan
    Write-Host "  Depois de instalado (tl), e so digitar 'tl'" -ForegroundColor $script:c.DarkGray
    Write-Host "  Backups ficam em: %LOCALAPPDATA%\Otimizador" -ForegroundColor $script:c.DarkGray
    Write-Host "  Tudo pode ser desfeito pelas opcoes 8, 9 e 10." -ForegroundColor $script:c.DarkGray
}

function Show-Menu {
    Show-Banner
    $sp = Get-SystemSpecs
    $tt=[char]0x2554;$tr=[char]0x2557;$tb=[char]0x255A;$te=[char]0x255D;$th=[char]0x2550;$tv=[char]0x2551
    $st = "  $tt$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$tr"
    $sb = "  $tb$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$th$te"
    $sf = "  $tv  {0,-38} $tv"
    Write-Host $st -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "SO:     $($sp.OS)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "CPU:    $($sp.CPU)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "RAM:    $($sp.RAM)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "GPU:    $($sp.GPU)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "Uptime: $($sp.Uptime)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "Usuario: $($sp.Usuario)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "PC: $($sp.PC)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "TPM: $($sp.TPM)   NET 4: $($sp.Net4)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "Fuso: $($sp.Fuso)") -ForegroundColor $script:c.DarkGray
    foreach ($d in $sp.Discos) {
        Write-Host ($sf -f "Disco $($d.Letra):  $($d.Livre)/$($d.Total) GB  $($d.Bar)  $($d.Pct)%") -ForegroundColor $script:c.DarkGray
    }
    Write-Host $sb -ForegroundColor $script:c.DarkGray
    Write-Host ""

    $t=[char]0x250C;$h=[char]0x2500;$v=[char]0x2502;$b=[char]0x2514
    $r=[char]0x2510;$e=[char]0x2518;$d=[char]0x25CF;$s=[char]0x25C9
    $c=[char]0x250C;$a=[char]0x2510;$l=[char]0x2514;$k=[char]0x2518

    $top = "  $t$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$a"
    $mid = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$k"
    $bot = "  $l$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$k"
    $fmt = "     {0,-2}. {1}  {2,-27} "
    $df = "  $v {0,-38} $v"

    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "1", $d, "Limpeza rapida") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "Remove arquivos temporarios") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "2", $s, "Limpeza profunda") + "$v") -ForegroundColor $script:c.Magenta
    Write-Host ($df -f "Limpa bem mais fundo, libera GBs") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "3", $d, "Desligar servicos") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "Acelera o PC desligando servicos") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "4", $d, "Melhorar internet") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "DNS Cloudflare, reset de rede, TCP") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "5", $d, "Acelerar visual") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "Desliga animacoes e efeitos visuais") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "6", $s, "EXECUTAR TUDO") + "$v") -ForegroundColor $script:c.Magenta
    Write-Host ($df -f "Roda servicos + internet + visual") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "7", $d, "Ponto de restauracao") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ($df -f "Cria checkpoint pra voltar se der erro") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "8", $d, "Desfazer - Servicos") + "$v") -ForegroundColor $script:c.Cyan
    Write-Host ("  $v" + ($fmt -f "9", $d, "Desfazer - Rede") + "$v") -ForegroundColor $script:c.Cyan
    Write-Host ("  $v" + ($fmt -f "10", $d, "Desfazer - Visual") + "$v") -ForegroundColor $script:c.Cyan
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "11", $d, "Gerenciar navegadores") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ($df -f "Lista e desinstala navegadores") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "12", $s, "Desinstalador universal") + "$v") -ForegroundColor $script:c.Magenta
    Write-Host ($df -f "Remove programas e limpa residuos") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "13", $d, "Driver Updater") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "Baixa atualizadores de drivers") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "14", $d, "Verificar atualizacao") + "$v") -ForegroundColor $script:c.Green
    Write-Host ($df -f "Checa e baixa versao mais recente") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "15", $d, "Escolher tema") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ($df -f "Altera as cores do otimizador") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host ("  $v" + ($fmt -f "16", $d, "Ajuda") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ($df -f "Explica cada opcao em detalhes") -ForegroundColor $script:c.DarkGray
    Write-Host $mid -ForegroundColor $script:c.DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor $script:c.DarkCyan
    Write-Host "  $v             [0]  X  Sair                  $v" -ForegroundColor $script:c.Red
    Write-Host $bot -ForegroundColor $script:c.DarkCyan
    Write-Host ""
}

function Backup-Servicos {
    $servicos = @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","DiagTrack","dmwappushservice","WSearch","SysMain","TabletInputService","RemoteRegistry","RemoteDesktopServices","TermService","lfsvc","MapsBroker","WbioSrvc")
    $backup = @()
    foreach ($nome in $servicos) {
        $svc = Get-Service -Name $nome -ErrorAction SilentlyContinue
        if ($svc) {
            $backup += [PSCustomObject]@{
                Nome       = $nome
                StartupType = $svc.StartType
                Status     = $svc.Status
            }
        }
    }
    $backup | ConvertTo-Json | Set-Content "$backupDir\servicos_backup.json" -Force
    Write-Host "Backup dos servicos salvo." -ForegroundColor $script:c.Gray
}

function Backup-Rede {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" }
    $dnsBackup = @()
    foreach ($adapter in $adapters) {
        $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $dnsBackup += [PSCustomObject]@{
            InterfaceIndex = $adapter.ifIndex
            InterfaceName  = $adapter.Name
            DnsServers     = $dns
        }
    }
    $autoTuning = (netsh int tcp show global | Select-String "Receive Window Auto-Tuning" | ForEach-Object { $_ -replace '.*level\s*:\s*','' })
    $obj = [PSCustomObject]@{ Dns = $dnsBackup; AutoTuning = $autoTuning }
    $obj | ConvertTo-Json -Depth 3 | Set-Content "$backupDir\rede_backup.json" -Force
    Write-Host "Backup da rede salvo." -ForegroundColor $script:c.Gray
}

function Backup-Visual {
    $itens = @(
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"}
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"}
        @{Path = "HKCU:\Control Panel\Desktop"; Name = "UserPreferencesMask"}
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewShadow"}
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"}
    )
    $dados = @()
    foreach ($item in $itens) {
        $val = Get-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $item.Name -ErrorAction SilentlyContinue
        if ($val -ne $null) {
            if ($val -is [byte[]]) {
                $val = [System.BitConverter]::ToString($val) -replace '-', ' '
            }
            $dados += [PSCustomObject]@{ Path = $item.Path; Name = $item.Name; Value = $val }
        }
    }
    $dados | ConvertTo-Json | Set-Content "$backupDir\visual_backup.json" -Force
    Write-Host "Backup do visual salvo." -ForegroundColor $script:c.Gray
}

function New-PontoRestauracao {
    Show-Banner
    Write-Host ">>> PONTO DE RESTAURACAO <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "ERRO: Precisa ser ADMINISTRADOR!" -ForegroundColor $script:c.Red
        Wait-Key; return
    }
    $desc = Read-Host "Descricao do ponto (ex: Antes da otimizacao)"
    if (-not $desc) { $desc = "Antes da otimizacao" }
    try {
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "Ponto de restauracao '$desc' criado com sucesso!" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "Erro ao criar ponto de restauracao." -ForegroundColor $script:c.Red
        Write-Host "Ative a Protecao do Sistema: Painel de Controle > Sistema > Protecao do Sistema" -ForegroundColor $script:c.Yellow
    }
    Wait-Key
}

function Run-Limpeza {
    Write-Host ">>> LIMPEZA DE DISCO <<<" -ForegroundColor $script:c.Magenta
    Write-Host "NOTA: Limpeza nao pode ser desfeita. Os arquivos serao excluidos permanentemente." -ForegroundColor $script:c.Yellow
    Write-Host ""

    Write-Host "[1/5] Limpando arquivos temporarios..." -NoNewline
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[2/5] Limpando cache do sistema..." -NoNewline
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[3/5] Executando Cleanmgr..." -NoNewline
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[4/5] Esvaziando lixeira..." -NoNewline
    (New-Object -ComObject Shell.Application).Namespace(0xa).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[5/5] Limpando cache DNS..." -NoNewline
    ipconfig /flushdns | Out-Null
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host ""; Write-Host "Limpeza concluida!" -ForegroundColor $script:c.Green
}

function Wrap-Texto {
    param([string]$Texto, [int]$Largura = 48)
    $linhas = @()
    while ($Texto.Length -gt $Largura) {
        $quebra = $Texto.LastIndexOf(' ', $Largura)
        if ($quebra -le 0) { $quebra = $Largura }
        $linhas += $Texto.Substring(0, $quebra).TrimEnd()
        $Texto = $Texto.Substring($quebra).TrimStart()
    }
    if ($Texto) { $linhas += $Texto }
    return $linhas
}

function Show-ServicosSubmenu {
    param([array]$Servicos, [string]$Titulo)

    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=54
        $top = "  $([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$("$h"*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$("$h"*$w)$([char]0x255D)"
        $sub = "  $([char]0x255F)$("$h"*$w)$([char]0x2562)"

        $i = 1
        foreach ($s in $Servicos) {
            $check = if ($s.Selected) { "[X]" } else { "[ ]" }
            $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
            $status = if ($svc) { "$($svc.Status)" } else { "AUSENTE" }
            $cor = if ($s.Selected) { "Green" } else { "DarkGray" }
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor $script:c.Cyan
                Write-Host "  $v  Digite NUMERO para marcar/desmarcar               $v" -ForegroundColor $script:c.DarkCyan
                Write-Host $sep -ForegroundColor $script:c.Cyan
            }
            Write-Host "  $v  $("{0,2}" -f $i). $check $("{0,-30}" -f $s.Desc) $("{0,-12}" -f $status) $v" -ForegroundColor $cor
            foreach ($linha in (Wrap-Texto -Texto $s.Detalhe -Largura 48)) {
                Write-Host "  $v  $("{0,-50}" -f "  $linha") $v" -ForegroundColor $script:c.DarkGray
            }
            $i++
        }

        Write-Host $sub -ForegroundColor $script:c.Cyan
        Write-Host "  $v  [A] Aplicar  [T] Marcar todos  [V] Voltar                $v" -ForegroundColor $script:c.Yellow
        Write-Host $bot -ForegroundColor $script:c.Cyan
        Write-Host ""
        $choice = Read-Host "Escolha"
        if ($choice -eq "V" -or $choice -eq "v") { return $null }
        if ($choice -eq "A" -or $choice -eq "a") { return $Servicos }
        if ($choice -eq "T" -or $choice -eq "t") { foreach ($s in $Servicos) { $s.Selected = $true }; continue }
        $num = [int]::TryParse($choice, [ref]$null)
        if ($num -and [int]$choice -ge 1 -and [int]$choice -le $Servicos.Count) {
            $Servicos[[int]$choice - 1].Selected = -not $Servicos[[int]$choice - 1].Selected
        }
    } while ($true)
}

function Run-Servicos {
    param([switch]$SkipMenu)
    $servicos = @(
        @{Nome = "XblAuthManager"; Desc = "Autenticacao Xbox"; Selected = $true; Detalhe = "Autenticacao de contas Xbox Live. Desligar: jogos Xbox podem perder acesso online, mas outros jogos e o sistema continuam normais."}
        @{Nome = "XblGameSave"; Desc = "Save game Xbox"; Selected = $true; Detalhe = "Salva jogos Xbox na nuvem. Desligar: voce perde salvamento na nuvem, mas saves locais continuam funcionando."}
        @{Nome = "XboxNetApiSvc"; Desc = "Rede Xbox"; Selected = $true; Detalhe = "Conecta jogos Xbox a internet. Desligar: multiplayer em jogos Xbox para de funcionar. Jogos de outras plataformas nao sao afetados."}
        @{Nome = "XboxGipSvc"; Desc = "Perifericos Xbox"; Selected = $true; Detalhe = "Suporte a controles Xbox. Desligar: controle Xbox pode nao funcionar corretamente no PC."}
        @{Nome = "DiagTrack"; Desc = "Tracking Microsoft"; Selected = $true; Detalhe = "Coleta dados de uso e envia para a Microsoft. Desligar: mais privacidade e menos consumo de recursos. Recomendado para todos."}
        @{Nome = "dmwappushservice"; Desc = "Roteamento WAP"; Selected = $true; Detalhe = "Roteamento de mensagens de operadoras. Desligar: nenhum impacto para usuarios comuns. Servico desnecessario."}
        @{Nome = "WSearch"; Desc = "Windows Search"; Selected = $true; Detalhe = "Indexa arquivos para buscas rapidas. Desligar: pesquisas ficam mais lentas, mas libera CPU e RAM significativamente."}
        @{Nome = "SysMain"; Desc = "SysMain (Superfetch)"; Selected = $true; Detalhe = "Pre-carrega programas na memoria. Desligar: em SSD nao faz diferenca. Em HD pode deixar abertura de programas um pouco mais lenta."}
        @{Nome = "TabletInputService"; Desc = "Entrada Tablet"; Selected = $true; Detalhe = "Suporte a caneta e toque. Desligar: sem impacto em PCs sem tela touch ou caneta."}
        @{Nome = "RemoteRegistry"; Desc = "Registro Remoto"; Selected = $true; Detalhe = "Permite editar o registro do Windows pela rede. Desligar: mais seguro, impede acesso remoto ao registro."}
        @{Nome = "RemoteDesktopServices"; Desc = "Area Remota"; Selected = $true; Detalhe = "Permite acessar este PC de outro lugar. Desligar: nao sera possivel usar area de trabalho remota (RDP)."}
        @{Nome = "TermService"; Desc = "Servico Terminal"; Selected = $true; Detalhe = "Necessario para area de trabalho remota (RDP). Desligar: mesmo efeito do item acima, impede acesso remoto."}
        @{Nome = "lfsvc"; Desc = "Geolocalizacao"; Selected = $true; Detalhe = "Servico de localizacao do Windows. Desligar: apps como Mapas e Clima nao detectam sua localizacao automaticamente."}
        @{Nome = "MapsBroker"; Desc = "Download Mapas"; Selected = $true; Detalhe = "Gerenciador de mapas baixados. Desligar: app Windows Maps pode nao funcionar direito, mas nao afeta Google Maps ou outros."}
        @{Nome = "WbioSrvc"; Desc = "Biometria"; Selected = $true; Detalhe = "Leitor de digital e reconhecimento facial. Desligar: Windows Hello e leitor de digital param de funcionar."}
    )

    if ($SkipMenu) { $selecionados = $servicos }
    else { $selecionados = Show-ServicosSubmenu -Servicos $servicos -Titulo "DESATIVAR SERVICOS" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> ATIVANDO/DESATIVANDO SERVICOS <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""; Backup-Servicos

    $paraDesativar = $selecionados | Where-Object { $_.Selected }
    $paraAtivar = $selecionados | Where-Object { -not $_.Selected }

    foreach ($s in $paraDesativar) {
        Write-Host "DESATIVAR  [$($s.Desc)] ($($s.Nome))..." -NoNewline
        $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name $s.Nome -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s.Nome -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " DESATIVADO" -ForegroundColor $script:c.Green
        } elseif ($svc) {
            Set-Service -Name $s.Nome -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " JA DESATIVADO" -ForegroundColor $script:c.Yellow
        } else {
            Write-Host " NAO ENCONTRADO" -ForegroundColor $script:c.Gray
        }
    }

    foreach ($s in $paraAtivar) {
        Write-Host "REATIVAR   [$($s.Desc)] ($($s.Nome))..." -NoNewline
        $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $s.Nome -StartupType Automatic -ErrorAction SilentlyContinue
            if ($svc.Status -ne "Running") {
                Start-Service -Name $s.Nome -ErrorAction SilentlyContinue
            }
            Write-Host " ATIVADO" -ForegroundColor $script:c.Cyan
        } else {
            Write-Host " NAO ENCONTRADO" -ForegroundColor $script:c.Gray
        }
    }

    Write-Host ""; Write-Host "Servicos ajustados! Use [8] no menu para desfazer." -ForegroundColor $script:c.Green
}

function Run-Rede {
    param([switch]$SkipMenu)
    $itens = @(
        @{Nome = "LiberarRenovarIP"; Desc = "Liberar e renovar IP"; Selected = $true; Detalhe = "Libera o endereco IP atual e pega um novo do roteador. Resolve problemas de conexao quando a internet para de funcionar do nada."}
        @{Nome = "ResetWinsock"; Desc = "Resetar Winsock e TCP/IP"; Selected = $true; Detalhe = "Reseta a pilha de rede do Windows. Corrige erros de conexao, DNS e rede que outros metodos nao resolvem."}
        @{Nome = "DNSCloudflare"; Desc = "DNS Cloudflare (1.1.1.1)"; Selected = $true; Detalhe = "Troca o DNS do Windows para Cloudflare (1.1.1.1). Navegacao mais rapida, mais privacidade e acesso a sites bloqueados pelo provedor."}
        @{Nome = "AutoTuning"; Desc = "Ajustar auto-tuning TCP"; Selected = $true; Detalhe = "Ajusta o algoritmo de auto-tuning TCP para o padrao (normal). Pode melhorar velocidade de download em conexoes com latencia alta."}
    )

    if ($SkipMenu) { $selecionados = $itens }
    else { $selecionados = Show-GenericoSubmenu -Itens $itens -Titulo "OTIMIZAR REDE" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> APLICANDO OTIMIZACOES DE REDE <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""; Backup-Rede

    $paraOtimizar = $selecionados | Where-Object { $_.Selected }
    $paraReverter = $selecionados | Where-Object { -not $_.Selected }
    $backupRede = Get-Content "$backupDir\rede_backup.json" | ConvertFrom-Json -ErrorAction SilentlyContinue

    foreach ($item in $paraOtimizar) {
        switch ($item.Nome) {
            "LiberarRenovarIP" {
                Write-Host "[Liberando e renovando IP]..." -NoNewline
                ipconfig /release | Out-Null; ipconfig /renew | Out-Null
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "ResetWinsock" {
                Write-Host "[Resetando Winsock e TCP/IP]..." -NoNewline
                netsh int ip reset | Out-Null; netsh winsock reset | Out-Null
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSCloudflare" {
                Write-Host "[DNS Cloudflare (1.1.1.1)]..." -NoNewline
                $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" }
                foreach ($adapter in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
                }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "AutoTuning" {
                Write-Host "[Ajustando auto-tuning TCP]..." -NoNewline
                netsh int tcp set global autotuninglevel=normal | Out-Null
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
        }
    }

    foreach ($item in $paraReverter) {
        switch ($item.Nome) {
            "LiberarRenovarIP" {
                Write-Host "[Liberar/renovar IP - NAO REVERTIVEL]..." -ForegroundColor $script:c.DarkGray
            }
            "ResetWinsock" {
                Write-Host "[Reset Winsock - NAO REVERTIVEL]..." -ForegroundColor $script:c.DarkGray
            }
            "DNSCloudflare" {
                if ($backupRede -and $backupRede.Dns) {
                    Write-Host "[Restaurando DNS original]..." -NoNewline
                    foreach ($d in $backupRede.Dns) {
                        if ($d.DnsServers -and $d.DnsServers.Count -gt 0) {
                            Set-DnsClientServerAddress -InterfaceIndex $d.InterfaceIndex -ServerAddresses $d.DnsServers -ErrorAction SilentlyContinue
                        } else {
                            Set-DnsClientServerAddress -InterfaceIndex $d.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
                        }
                    }
                    Write-Host " RESTAURADO" -ForegroundColor $script:c.Cyan
                } else {
                    Write-Host "[DNS - SEM BACKUP]" -ForegroundColor $script:c.DarkGray
                }
            }
            "AutoTuning" {
                if ($backupRede -and $backupRede.AutoTuning) {
                    Write-Host "[Restaurando auto-tuning ($($backupRede.AutoTuning))]..." -NoNewline
                    netsh int tcp set global autotuninglevel=$($backupRede.AutoTuning) | Out-Null
                    Write-Host " RESTAURADO" -ForegroundColor $script:c.Cyan
                } else {
                    Write-Host "[Auto-tuning - SEM BACKUP]" -ForegroundColor $script:c.DarkGray
                }
            }
        }
    }

    Write-Host ""; Write-Host "Rede otimizada! Use [9] no menu para desfazer." -ForegroundColor $script:c.Green
}

function Show-GenericoSubmenu {
    param([array]$Itens, [string]$Titulo)

    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=46
        $top = "  $([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$("$h"*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$("$h"*$w)$([char]0x255D)"
        $sub = "  $([char]0x255F)$("$h"*$w)$([char]0x2562)"

        $i = 1
        foreach ($item in $Itens) {
            $check = if ($item.Selected) { "[X]" } else { "[ ]" }
            $cor = if ($item.Selected) { "Green" } else { "DarkGray" }
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor $script:c.Cyan
                Write-Host "  $v  Digite NUMERO para marcar/desmarcar          $v" -ForegroundColor $script:c.DarkCyan
                Write-Host $sep -ForegroundColor $script:c.Cyan
            }
            Write-Host "  $v  $("{0,2}" -f $i). $check $("{0,-35}" -f $item.Desc) $v" -ForegroundColor $cor
            foreach ($linha in (Wrap-Texto -Texto $item.Detalhe -Largura 40)) {
                Write-Host "  $v  $("{0,-42}" -f "  $linha")   $v" -ForegroundColor $script:c.DarkGray
            }
            $i++
        }

        Write-Host $sub -ForegroundColor $script:c.Cyan
        Write-Host "  $v  [A] Aplicar  [T] Marcar todos  [V] Voltar           $v" -ForegroundColor $script:c.Yellow
        Write-Host $bot -ForegroundColor $script:c.Cyan
        Write-Host ""
        $choice = Read-Host "Escolha"
        if ($choice -eq "V" -or $choice -eq "v") { return $null }
        if ($choice -eq "A" -or $choice -eq "a") { return $Itens }
        if ($choice -eq "T" -or $choice -eq "t") { foreach ($item in $Itens) { $item.Selected = $true }; continue }
        $num = [int]::TryParse($choice, [ref]$null)
        if ($num -and [int]$choice -ge 1 -and [int]$choice -le $Itens.Count) {
            $Itens[[int]$choice - 1].Selected = -not $Itens[[int]$choice - 1].Selected
        }
    } while ($true)
}

function Run-Visual {
    param([switch]$SkipMenu)
    $itens = @(
        @{Nome = "ModoDesempenho"; Desc = "Modo desempenho (VisualFX)"; Selected = $true; Detalhe = "Muda o Windows para o modo de melhor desempenho. Desliga todas as animacoes, sombras e efeitos de uma vez. O sistema fica mais leve e responsivo."}
        @{Nome = "Transparencia"; Desc = "Desativar transparencia"; Selected = $true; Detalhe = "Desliga o efeito de transparencia nas janelas e barra de tarefas (Acrylic). Reduz o uso da placa de video e melhora desempenho."}
        @{Nome = "Animacoes"; Desc = "Desativar animacoes"; Selected = $true; Detalhe = "Desliga animacoes de abrir, fechar e minimizar janelas. Tudo fica mais instantaneo, o PC parece mais rapido no dia a dia."}
        @{Nome = "SombrasEfeitos"; Desc = "Desativar sombras e efeitos"; Selected = $true; Detalhe = "Desliga sombras de janelas e animacoes da barra de tarefas. Ganho pequeno de desempenho, mas em PCs fracos faz diferenca."}
    )

    if ($SkipMenu) { $selecionados = $itens }
    else { $selecionados = Show-GenericoSubmenu -Itens $itens -Titulo "AJUSTES VISUAIS" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> APLICANDO AJUSTES VISUAIS <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""; Backup-Visual

    $paraAplicar = $selecionados | Where-Object { $_.Selected }
    $paraReverter = $selecionados | Where-Object { -not $_.Selected }
    $backupVisual = Get-Content "$backupDir\visual_backup.json" | ConvertFrom-Json -ErrorAction SilentlyContinue

    foreach ($item in $paraAplicar) {
        switch ($item.Nome) {
            "ModoDesempenho" {
                Write-Host "[Modo desempenho]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "Transparencia" {
                Write-Host "[Desativando transparencia]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "Animacoes" {
                Write-Host "[Desativando animacoes]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "SombrasEfeitos" {
                Write-Host "[Desativando sombras e efeitos]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
        }
    }

    foreach ($item in $paraReverter) {
        if (-not $backupVisual) { Write-Host "[$($item.Desc) - SEM BACKUP]" -ForegroundColor $script:c.DarkGray; continue }
        $mapa = @{ModoDesempenho="VisualFXSetting"; Transparencia="EnableTransparency"; Animacoes="UserPreferencesMask"; SombrasEfeitos="ListviewShadow"}
        $regName = $mapa[$item.Nome]
        $reg = $backupVisual | Where-Object { $_.Name -eq $regName }
        if (-not $reg) { Write-Host "[$($item.Desc) - SEM BACKUP]" -ForegroundColor $script:c.DarkGray; continue }
        Write-Host "[Restaurando $($item.Desc)]..." -NoNewline
        $val = $reg.Value
        if ($val -match '^[0-9A-F ]+$') {
            $bytes = $val -split ' ' | ForEach-Object { [byte]("0x$_") }
            Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $bytes -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value ([int]$val) -ErrorAction SilentlyContinue
        }
        if ($item.Nome -eq "SombrasEfeitos") {
            $reg2 = $backupVisual | Where-Object { $_.Name -eq "TaskbarAnimations" }
            if ($reg2) {
                Set-ItemProperty -Path $reg2.Path -Name $reg2.Name -Value ([int]$reg2.Value) -ErrorAction SilentlyContinue
            }
        }
        Write-Host " RESTAURADO" -ForegroundColor $script:c.Cyan
    }

    Write-Host ""; Write-Host "Ajustes visuais aplicados! Use [10] no menu para desfazer." -ForegroundColor $script:c.Green
}

function Undo-Servicos {
    Show-Banner
    Write-Host ">>> DESFAZER - SERVICOS <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\servicos_backup.json")) {
        Write-Host "Nenhum backup de servicos encontrado." -ForegroundColor $script:c.Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\servicos_backup.json" | ConvertFrom-Json
    foreach ($item in $backup) {
        Write-Host "[$($item.Nome)]..." -NoNewline
        $svc = Get-Service -Name $item.Nome -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $item.Nome -StartupType $item.StartupType -ErrorAction SilentlyContinue
            if ($item.Status -eq "Running") { Start-Service -Name $item.Nome -ErrorAction SilentlyContinue }
            Write-Host " RESTAURADO ($($item.StartupType), $($item.Status))" -ForegroundColor $script:c.Green
        } else { Write-Host " NAO ENCONTRADO" -ForegroundColor $script:c.Gray }
    }
    Write-Host ""; Write-Host "Servicos restaurados!" -ForegroundColor $script:c.Green
    Remove-Item "$backupDir\servicos_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Undo-Rede {
    Show-Banner
    Write-Host ">>> DESFAZER - REDE <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\rede_backup.json")) {
        Write-Host "Nenhum backup de rede encontrado." -ForegroundColor $script:c.Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\rede_backup.json" | ConvertFrom-Json

    if ($backup.AutoTuning) {
        Write-Host "[Auto-Tuning TCP] Restaurando..." -NoNewline
        netsh int tcp set global autotuninglevel=$($backup.AutoTuning) | Out-Null
        Write-Host " OK ($($backup.AutoTuning))" -ForegroundColor $script:c.Green
    }

    foreach ($adapter in $backup.Dns) {
        Write-Host "[DNS - $($adapter.InterfaceName)]..." -NoNewline
        if ($adapter.DnsServers -and $adapter.DnsServers.Count -gt 0) {
            $servers = @($adapter.DnsServers | ForEach-Object { "$_" })
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers -ErrorAction SilentlyContinue
            Write-Host " RESTAURADO ($($servers -join ', '))" -ForegroundColor $script:c.Green
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            Write-Host " RESTAURADO (DHCP)" -ForegroundColor $script:c.Green
        }
    }

    Write-Host ""; Write-Host "Rede restaurada!" -ForegroundColor $script:c.Green
    Remove-Item "$backupDir\rede_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Undo-Visual {
    Show-Banner
    Write-Host ">>> DESFAZER - VISUAL <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\visual_backup.json")) {
        Write-Host "Nenhum backup de visual encontrado." -ForegroundColor $script:c.Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\visual_backup.json" | ConvertFrom-Json
    foreach ($item in $backup) {
        Write-Host "[$($item.Path) > $($item.Name)]..." -NoNewline
        try {
            $val = $item.Value
            if ($item.Name -eq "UserPreferencesMask") {
                $val = [byte[]]($item.Value -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })
            }
            Set-ItemProperty -Path $item.Path -Name $item.Name -Value $val -ErrorAction Stop
            Write-Host " RESTAURADO" -ForegroundColor $script:c.Green
        } catch { Write-Host " ERRO" -ForegroundColor $script:c.Red }
    }
    Write-Host ""; Write-Host "Ajustes visuais restaurados!" -ForegroundColor $script:c.Green
    Remove-Item "$backupDir\visual_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Run-LimpezaExtrema {
    Write-Host ">>> LIMPEZA EXTREMA (SEGURA) <<<" -ForegroundColor $script:c.Magenta
    Write-Host "Limpa profundamente sem risco ao sistema." -ForegroundColor $script:c.Yellow
    Write-Host ""

    Write-Host "[ 1/18] Arquivos temporarios (Windows + Usuario)..." -NoNewline
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 2/18] Cache do Windows (Prefetch, INetCache)..." -NoNewline
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 3/18] Cache do Windows Update (seguro - redownload)..." -NoNewline
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Start-Service bits -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 4/18] Relatorios de erro (WER)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 5/18] Dumps de memoria (crash files)..." -NoNewline
    Remove-Item -Path "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 6/18] Logs do Windows..." -NoNewline
    Get-ChildItem -Path "C:\Windows\Logs" -Recurse -Include "*.log","*.etl" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\System32\LogFiles" -Recurse -Include "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 7/18] Cache de miniaturas (thumbnails)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.db" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 8/18] Cache de fontes..." -NoNewline
    Stop-Service FontCache -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service FontCache -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[ 9/18] Cache Delivery Optimization..." -NoNewline
    Remove-Item -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[10/18] Temporarios de instalacao (setup)..." -NoNewline
    Remove-Item -Path "C:\`$Windows.~BT" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\`$Windows.~WS" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Setup\Scripts\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Panther\*.log" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[11/18] Cache do .NET Framework..." -NoNewline
    Remove-Item -Path "C:\Windows\Microsoft.NET\Framework\*\NativeImages\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Microsoft.NET\Framework64\*\NativeImages\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[12/18] Cache do DirectX Shader..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\DirectX\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Users\*\AppData\Local\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[13/18] Cache do Windows Defender..." -NoNewline
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Scans\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Network Inspection System\Support\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[14/18] Arquivos temporarios do Office..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Office\*.tmp" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Office\*.log" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[15/18] Cache de navegadores (Edge + Chrome)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[16/18] Cache DNS e lixeira..." -NoNewline
    ipconfig /flushdns | Out-Null
    (New-Object -ComObject Shell.Application).Namespace(0xa).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[17/18] Limpeza via CleanMgr (modo extremo)..." -NoNewline
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host "[18/18] Executando DISM (limpeza de componentes)..." -NoNewline
    dism /online /cleanup-image /StartComponentCleanup /Quiet /NoRestart | Out-Null
    dism /online /cleanup-image /SPSuperseded /Quiet /NoRestart | Out-Null
    Write-Host " OK" -ForegroundColor $script:c.Green

    Write-Host ""; Write-Host "LIMPEZA EXTREMA CONCLUIDA!" -ForegroundColor $script:c.Green
    Write-Host "Alguns GB de espaco foram liberados." -ForegroundColor $script:c.Yellow
}
function Run-Browsers {
    $itens = @(
        @{Nome = "Microsoft Edge";  Desc = "Microsoft Edge";    Selected = $false; URL = "https://www.microsoft.com/edge/download"; Detalhe = "Navegador padrao do Windows. Leve e integrado ao sistema. Recomendado para uso basico."}
        @{Nome = "Google Chrome";   Desc = "Google Chrome";     Selected = $false; URL = "https://dl.google.com/chrome/install/standalonesetup64.exe"; Detalhe = "O navegador mais popular do mundo. Rapido, com muitas extensoes e sincronizacao de conta Google."}
        @{Nome = "Mozilla Firefox"; Desc = "Mozilla Firefox";   Selected = $false; URL = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"; Detalhe = "Navegador focado em privacidade e codigo aberto. Bloqueador de rastreadores nativo."}
        @{Nome = "Brave";           Desc = "Brave";             Selected = $false; URL = "https://laptop-updates.brave.com/latest/winx64"; Detalhe = "Navegador com bloqueador de anuncios e rastreadores nativo. Recompensa usuarios com criptomoedas."}
        @{Nome = "Opera";           Desc = "Opera";             Selected = $false; URL = "https://net.geo.opera.com/opera/stable/windows"; Detalhe = "Navegador com VPN gratuita integrada, bloqueador de anuncios e Messenger na barra lateral."}
        @{Nome = "Opera GX";        Desc = "Opera GX";          Selected = $false; URL = "https://net.geo.opera.com/opera_gx/stable/windows"; Detalhe = "Navegador para gamers com limitador de CPU/RAM, integracao com Twitch e Discord."}
        @{Nome = "Vivaldi";         Desc = "Vivaldi";           Selected = $false; URL = "https://downloads.vivaldi.com/stable/VivaldiSetup.exe"; Detalhe = "Navegador altamente personalizavel. Ideal para quem gosta de configurar cada detalhe."}
        @{Nome = "Tor Browser";     Desc = "Tor Browser";       Selected = $false; URL = "https://www.torproject.org/dist/torbrowser/latest/torbrowser-install-win64.exe"; Detalhe = "Navegador focado em anonimato. Roteia o trafego por varios servidores ao redor do mundo."}
    )
    $selecionados = Show-GenericoSubmenu -Itens $itens -Titulo "INSTALAR NAVEGADORES"
    if ($selecionados -eq $null) { return }
    $paraInstalar = $selecionados | Where-Object { $_.Selected }
    if ($paraInstalar.Count -eq 0) { Write-Host "Nenhum navegador selecionado." -ForegroundColor $script:c.Yellow; Wait-Key; return }
    Show-Banner
    Write-Host ">>> BAIXANDO E INSTALANDO NAVEGADORES <<<" -ForegroundColor $script:c.Magenta
    Write-Host "NOTA: A instalacao pode abrir janelas de confirmacao." -ForegroundColor $script:c.Yellow
    Write-Host ""
    foreach ($b in $paraInstalar) {
        Write-Host "[$($b.Nome)] Baixando..." -NoNewline
        $dest = "$env:TEMP\install_$($b.Nome -replace ' ','').exe"
        try {
            Invoke-WebRequest -Uri $b.URL -OutFile $dest -UseBasicParsing -ErrorAction Stop
            Write-Host " OK" -ForegroundColor $script:c.Green
            Write-Host "         Instalando..." -NoNewline
            Start-Process -FilePath $dest -ArgumentList "/silent /install" -Wait -ErrorAction SilentlyContinue
            Write-Host " OK" -ForegroundColor $script:c.Green
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host " ERRO: $($_.Exception.Message)" -ForegroundColor $script:c.Red
        }
    }
    Write-Host ""; Write-Host "Instalacao concluida!" -ForegroundColor $script:c.Green; Wait-Key
}

function Run-DriverUpdater {
    $itens = @(
        @{Nome = "Driver Easy";       Desc = "Driver Easy";        URL = "https://www.drivereasy.com/download-free/"; DownloadURL = "https://www.drivereasy.com/DriverEasy_Setup.exe"; Detalhe = "Escaneia o PC e encontra drivers desatualizados. Versao gratuita baixa um driver por vez. Interface simples e intuitiva."}
        @{Nome = "Driver Booster";    Desc = "Driver Booster";     URL = "https://www.iobit.com/pt/driver-booster.php"; DownloadURL = "https://download.iobit.com/driver_booster_setup.exe"; Detalhe = "Da IObit. Atualiza drivers com um clique, tem modo game e faz backup antes de atualizar. Versao gratuita tem limite de velocidade."}
        @{Nome = "Snappy Driver Installer"; Desc = "SDI"; URL = "https://www.snappy-driver-installer.org/download/"; DownloadURL = "https://DriverOff.net/sdi/SDI_R2601.7z"; Detalhe = "Ferramenta portatil que baixa e instala drivers. Codigo aberto, sem propagandas e sem limitacoes."}
    )
    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=46
        $top = "  $([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$("$h"*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$("$h"*$w)$([char]0x255D)"
        $i = 1
        foreach ($item in $itens) {
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor $script:c.Cyan
                Write-Host "  $v  Digite NUMERO para instalar ou desinstalar    $v" -ForegroundColor $script:c.DarkCyan
                Write-Host $sep -ForegroundColor $script:c.Cyan
            }
            Write-Host "  $v  $("{0,2}" -f $i). $("{0,-38}" -f $item.Desc) $v" -ForegroundColor $script:c.White
            foreach ($linha in (Wrap-Texto -Texto $item.Detalhe -Largura 40)) {
                Write-Host "  $v  $("{0,-42}" -f "  $linha")   $v" -ForegroundColor $script:c.DarkGray
            }
            $i++
        }
        Write-Host $bot -ForegroundColor $script:c.Cyan
        Write-Host ""
        $choice = Read-Host "Numero (ou V para voltar)"
        if ($choice -eq "V" -or $choice -eq "v") { return }
        $num = [int]::TryParse($choice, [ref]$null)
        if (-not $num -or [int]$choice -lt 1 -or [int]$choice -gt $itens.Count) { continue }
        $item = $itens[[int]$choice - 1]
        Show-Banner
        Write-Host "  $([char]0x2554)$("$h"*$w)$([char]0x2557)" -ForegroundColor $script:c.Cyan
        Write-Host "  $v  $($item.Desc)  $v" -ForegroundColor $script:c.White
        Write-Host "  $([char]0x2560)$("$h"*$w)$([char]0x2563)" -ForegroundColor $script:c.Cyan
        Write-Host "  $v  [I] Instalar - baixar e instalar automaticamente $v" -ForegroundColor $script:c.Green
        Write-Host "  $v  [D] Desinstalar - remover do PC               $v" -ForegroundColor $script:c.Red
        Write-Host "  $v  [V] Voltar                                    $v" -ForegroundColor $script:c.Yellow
        Write-Host "  $([char]0x255A)$("$h"*$w)$([char]0x255D)" -ForegroundColor $script:c.Cyan
        Write-Host ""
        $acao = Read-Host "Escolha"
        switch ($acao.ToUpper()) {
            "I" {
                Show-Banner
                Write-Host "Baixando $($item.Desc)..." -ForegroundColor $script:c.Green
                Write-Host "" -ForegroundColor $script:c.DarkGray
                $tempDir = "$env:TEMP\TLDriverUpd"
                $null = New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction SilentlyContinue
                $fileName = ($item.DownloadURL -split '/')[-1]
                $filePath = "$tempDir\$fileName"
                try {
                    $oldPref = $ProgressPreference
                    $ProgressPreference = 'SilentlyContinue'
                    $job = Start-Job -ScriptBlock { param($u,$p) try { Invoke-WebRequest -Uri $u -OutFile $p -UseBasicParsing -ErrorAction Stop; $true } catch { $false } } -ArgumentList $item.DownloadURL, $filePath
                    $spin = @('|', '/', '-', '\')
                    $i = 0
                    while ($job.State -eq 'Running') {
                        Write-Host "`r  $($spin[$i % 4]) Baixando..." -NoNewline -ForegroundColor $script:c.DarkCyan
                        $i++; Start-Sleep -Milliseconds 200
                    }
                    $ProgressPreference = $oldPref
                    $ok = $job | Receive-Job -Wait
                    $job | Remove-Job -Force
                    if (-not $ok) { throw "Falha no download." }
                    $tam = [math]::Round((Get-Item $filePath -ErrorAction SilentlyContinue).Length/1MB, 1)
                    Write-Host "`r  OK $tam MB" -ForegroundColor $script:c.Green
                    if ($fileName -match '\.zip$') {
                        $extractDir = "$tempDir\SDI"
                        Write-Host "Extraindo arquivos..." -NoNewline
                        Expand-Archive -Path $filePath -DestinationPath $extractDir -Force -ErrorAction Stop
                        Write-Host " OK" -ForegroundColor $script:c.Green
                    } elseif ($fileName -match '\.7z$') {
                        $7zPaths = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe", "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe")
                        $7z = $null
                        foreach ($p in $7zPaths) { if (Test-Path $p) { $7z = $p; break } }
                        if (-not $7z) { throw "7-Zip nao encontrado. Instale 7-Zip ou baixe manualmente." }
                        $extractDir = "$tempDir\SDI"
                        Write-Host "Extraindo com 7-Zip..." -NoNewline
                        & $7z x $filePath -o"$extractDir" -y -bso0 | Out-Null
                        if ($LASTEXITCODE -ne 0) { throw "Erro na extracao (codigo $LASTEXITCODE)." }
                        Write-Host " OK" -ForegroundColor $script:c.Green
                    } else {
                        Write-Host "Iniciando instalador..." -ForegroundColor $script:c.Cyan
                        Start-Process $filePath; return
                    }
                    $exe = Get-ChildItem $extractDir -Filter "*.exe" -Recurse | Where-Object { $_.Name -match '^SDI' } | Select-Object -First 1
                    if (-not $exe) { $exe = Get-ChildItem $extractDir -Filter "*.exe" -Recurse | Select-Object -First 1 }
                    if ($exe) {
                        Write-Host "Iniciando $($exe.Name)..." -ForegroundColor $script:c.Cyan
                        Start-Process $exe.FullName
                    } else { throw "Nenhum executavel encontrado na extracao." }
                    Write-Host ""; Write-Host "Instalador iniciado! Siga as instrucoes na tela." -ForegroundColor $script:c.Yellow
                } catch {
                    Write-Host "`r  FALHOU: $($_.Exception.Message)" -ForegroundColor $script:c.Red
                    Write-Host ""; Write-Host "Deseja abrir a pagina de download no navegador? (S/N)" -ForegroundColor $script:c.Yellow
                    $fallback = Read-Host
                    if ($fallback -eq "S" -or $fallback -eq "s") {
                        try { Start-Process $item.URL -ErrorAction Stop; Write-Host "Pagina aberta no navegador!" -ForegroundColor $script:c.Green }
                        catch { Write-Host "Erro ao abrir navegador." -ForegroundColor $script:c.Red }
                    }
                }
                Wait-Key
            }
            "D" {
                Show-Banner
                $nomeBusca = $item.Nome -replace ' Installer Lite','' -replace ' Lite',''
                Write-Host ">>> DESINSTALAR $($item.Nome) <<<" -ForegroundColor $script:c.Magenta
                Write-Host ""
                Write-Host "Procurando no sistema..." -NoNewline
                $chaves = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
                $prog = $null
                foreach ($chave in $chaves) {
                    $prog = Get-ItemProperty $chave -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$nomeBusca*" } | Select-Object -First 1
                    if ($prog) { break }
                }
                if (-not $prog) {
                    Write-Host " NAO ENCONTRADO" -ForegroundColor $script:c.Red
                    Write-Host "$($item.Nome) nao esta instalado no sistema." -ForegroundColor $script:c.Yellow
                    Wait-Key; continue
                }
                Write-Host " ENCONTRADO" -ForegroundColor $script:c.Green
                Write-Host "Programa: $($prog.DisplayName)" -ForegroundColor $script:c.Cyan
                Write-Host "Confirmar desinstalacao? (S/N)" -ForegroundColor $script:c.Yellow
                $conf = Read-Host
                if ($conf -ne "S" -and $conf -ne "s") { continue }
                Write-Host ""
                Write-Host "[1/3] Executando desinstalador..." -NoNewline
                try {
                    $uninst = $prog.UninstallString
                    Write-Host " $uninst" -ForegroundColor $script:c.DarkGray
                    Start-Process cmd.exe -ArgumentList '/c', $uninst -Wait -ErrorAction Stop
                    Write-Host " OK" -ForegroundColor $script:c.Green
                } catch { Write-Host " FALHOU ($($_.Exception.Message))" -ForegroundColor $script:c.Red }
                $nomeBase = $prog.DisplayName -replace '[\d\.\s\(\)]+$','' -replace '^The ',''
                Write-Host "[2/3] Limpando arquivos residuais..." -NoNewline
                $pastas = @("$env:PROGRAMFILES\$nomeBase*", "${env:ProgramFiles(x86)}\$nomeBase*", "$env:LOCALAPPDATA\$nomeBase*", "$env:APPDATA\$nomeBase*", "$env:PROGRAMDATA\$nomeBase*", "$env:USERPROFILE\$nomeBase*")
                foreach ($pasta in $pastas) { Remove-Item $pasta -Recurse -Force -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
                Write-Host "[3/3] Limpando registros..." -NoNewline
                $regs = @("HKCU:\Software\$nomeBase", "HKLM:\Software\$nomeBase", "HKLM:\Software\WOW6432Node\$nomeBase")
                foreach ($r in $regs) { Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue }
                Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($prog.DisplayName)" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green
                Write-Host ""; Write-Host "Desinstalacao concluida!" -ForegroundColor $script:c.Green; Wait-Key
            }
        }
    } while ($true)
}

function Run-UniversalUninstaller {
    $paths = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $todos = @()
    foreach ($p in $paths) {
        Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.UninstallString } | ForEach-Object {
            $todos += @{ Nome = $_.DisplayName; Uninst = $_.UninstallString; Pub = $_.Publisher }
        }
    }
    $todos = $todos | Sort-Object Nome
    if ($todos.Count -eq 0) { Write-Host "Nenhum programa encontrado." -ForegroundColor $script:c.Yellow; Wait-Key; return }

    $filtro = ""
    do {
        Clear-Host; Show-Banner
        $lista = if ($filtro) { $todos | Where-Object { $_.Nome -match $filtro } } else { $todos }
        $h=[char]0x2550;$v=[char]0x2551
        $top = "  $([char]0x2554)$("$h"*58)$([char]0x2557)"
        $bot = "  $([char]0x255A)$("$h"*58)$([char]0x255D)"
        Write-Host $top -ForegroundColor $script:c.Magenta
        Write-Host "  $v              DESINSTALADOR UNIVERSAL                  $v" -ForegroundColor $script:c.Magenta
        Write-Host "  $v  /texto = buscar   NUMERO = desinstalar   [V] Voltar $v" -ForegroundColor $script:c.DarkCyan
        Write-Host "  $v  Filtro: $(if ($filtro) { $filtro } else { '(todos)' })                          $v" -ForegroundColor $script:c.Yellow
        Write-Host $bot -ForegroundColor $script:c.Magenta
        if ($lista.Count -eq 0) {
            Write-Host "  Nenhum programa encontrado com esse filtro." -ForegroundColor $script:c.DarkGray
        } else {
            $i = 1
            foreach ($item in $lista) {
                Write-Host "  $("{0,3}" -f $i). $("{0,-55}" -f $(if ($item.Nome.Length -gt 55) { $item.Nome.Substring(0,52) + '...' } else { $item.Nome }))" -ForegroundColor $script:c.Gray
                $i++
            }
        }
        Write-Host "  ---- $($lista.Count) programa(s) ----" -ForegroundColor $script:c.DarkGray
        Write-Host ""
        $cmd = Read-Host "Comando"
        if ($cmd -eq "V" -or $cmd -eq "v") { return }
        if ($cmd -eq "U" -or $cmd -eq "u") {
            Write-Host "Digite o NUMERO do programa para desinstalar." -ForegroundColor $script:c.Yellow; Start-Sleep 1; continue
        }
        if ($cmd -match '^/\s*(.+)$') { $filtro = $Matches[1]; continue }
        $num = [int]::TryParse($cmd, [ref]$null)
        if ($num -and [int]$cmd -ge 1 -and [int]$cmd -le $lista.Count) {
            $prog = $lista[[int]$cmd - 1]
            Write-Host "`nDESINSTALAR: $($prog.Nome)?" -ForegroundColor $script:c.Yellow
            $conf = Read-Host "Confirmar? (S/N)"
            if ($conf -ne "S" -and $conf -ne "s") { continue }
            Show-Banner
            Write-Host ">>> DESINSTALANDO $($prog.Nome) <<<" -ForegroundColor $script:c.Magenta
            Write-Host ""
            Write-Host "[1/3] Executando desinstalador..." -NoNewline
            try {
                $uninst = $prog.Uninst
                Write-Host " $uninst" -ForegroundColor $script:c.DarkGray
                Start-Process cmd.exe -ArgumentList '/c', $uninst -Wait -ErrorAction Stop
                Write-Host " OK" -ForegroundColor $script:c.Green
            } catch { Write-Host " FALHOU ($($_.Exception.Message))" -ForegroundColor $script:c.Red }
            $nomeBase = $prog.Nome -replace '[\d\.\s\(\)]+$','' -replace '^The ',''
            $pubBase = if ($prog.Pub) { $prog.Pub -replace '[\s\,]+$','' } else { "" }
            Write-Host "[2/3] Limpando arquivos residuais..." -NoNewline
            $pastas = @("$env:PROGRAMFILES\$nomeBase*", "$env:ProgramFiles(x86)\$nomeBase*", "$env:LOCALAPPDATA\$nomeBase*", "$env:APPDATA\$nomeBase*", "$env:PROGRAMDATA\$nomeBase*", "$env:USERPROFILE\$nomeBase*")
            foreach ($pasta in $pastas) { Remove-Item $pasta -Recurse -Force -ErrorAction SilentlyContinue }
            if ($pubBase) { Remove-Item "$env:PROGRAMDATA\$pubBase*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:LOCALAPPDATA\$pubBase*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:APPDATA\$pubBase*" -Recurse -Force -ErrorAction SilentlyContinue }
            Write-Host " OK" -ForegroundColor $script:c.Green
            Write-Host "[3/3] Limpando registros..." -NoNewline
            $regs = @("HKCU:\Software\$nomeBase", "HKLM:\Software\$nomeBase", "HKLM:\Software\WOW6432Node\$nomeBase")
            foreach ($r in $regs) { Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue }
            if ($pubBase) { Remove-Item "HKCU:\Software\$pubBase" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "HKLM:\Software\$pubBase" -Recurse -Force -ErrorAction SilentlyContinue }
            Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($prog.Nome)" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " OK" -ForegroundColor $script:c.Green
            Write-Host ""; Write-Host "Desinstalacao e limpeza concluidas!" -ForegroundColor $script:c.Green; Wait-Key; return
        }
        if ($cmd -eq "") { continue }
        Write-Host "Comando invalido!" -ForegroundColor $script:c.Red; Start-Sleep 1
    } while ($true)
}

function Wait-Key {
    Write-Host ""; Write-Host "Pressione ENTER para voltar ao menu..." -ForegroundColor $script:c.Gray
    $null = Read-Host
}

function Show-Welcome {
    Clear-Host
    $b = [char]0x2554; $b2 = [char]0x2557; $b3 = [char]0x255A; $b4 = [char]0x255D; $h2 = [char]0x2550; $v2 = [char]0x2551
    Write-Host "  $b$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b2" -ForegroundColor $script:c.Cyan
    Write-Host "  $v2       T L   O P T I M I Z E R         $v2" -ForegroundColor $script:c.Cyan
    Write-Host "  $b3$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b4" -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "   TL Optimizer foi carregado via iwr | iex." -ForegroundColor $script:c.Yellow
    Write-Host "   Escolha como deseja usa-lo:" -ForegroundColor $script:c.Yellow
    Write-Host ""
    Write-Host "   [P] Portatil  - Roda agora, nada e salvo no PC." -ForegroundColor $script:c.Green
    Write-Host "                  Use quando quiser testar ou usar" -ForegroundColor $script:c.DarkGray
    Write-Host "                  uma unica vez. Comando sempre funciona." -ForegroundColor $script:c.DarkGray
    Write-Host ""
    Write-Host "   [I] Instalar  - Salva em $env:USERPROFILE\TL-Optimizer" -ForegroundColor $script:c.Cyan
    Write-Host "                  e registra no perfil do PowerShell." -ForegroundColor $script:c.Cyan
    Write-Host "                  Depois e so digitar 'tl' de qualquer lugar." -ForegroundColor $script:c.DarkGray
    Write-Host ""
}

function Install-Local {
    $targetDir = "$env:USERPROFILE\TL-Optimizer"
    $scriptPath = "$targetDir\otimizar-windows.ps1"
    Write-Host "Instalando em $targetDir..." -ForegroundColor $script:c.Cyan
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    try {
        iwr -useb "$scriptUrl" -OutFile $scriptPath -ErrorAction Stop
        Write-Host "Script salvo." -ForegroundColor $script:c.Green
    } catch {
        Write-Host "Erro ao baixar o script. Salvando da memoria..." -ForegroundColor $script:c.Yellow
        if ($global:MyInvocation.MyCommand.ScriptContents) {
            $global:MyInvocation.MyCommand.ScriptContents | Set-Content -Path $scriptPath -Force
        } else {
            Write-Host "Nao foi possivel salvar. Verifique a conexao." -ForegroundColor $script:c.Red
            Wait-Key; return
        }
    }
    $profileLine = "`n# TL Optimizer`nfunction tl-optimizer { & `"$scriptPath`" }`nSet-Alias -Name tl -Value tl-optimizer -Force"
    $profilePath = $PROFILE.CurrentUserAllHosts
    $dir = Split-Path $profilePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not (Test-Path $profilePath) -or (Get-Content $profilePath -Raw) -notmatch '# TL Optimizer') {
        Add-Content -Path $profilePath -Value $profileLine -Force
        Write-Host "Alias 'tl' adicionado ao perfil PowerShell." -ForegroundColor $script:c.Green
    } else {
        Write-Host "Alias 'tl' ja existe no perfil." -ForegroundColor $script:c.Yellow
    }
    $shortcutPath = "$env:USERPROFILE\Desktop\TL Optimizer.lnk"
    try {
        $wshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $shortcut.WorkingDirectory = $targetDir
        $shortcut.Description = "TL Optimizer - Otimizador de Windows"
        $shortcut.Save()
        Write-Host "Atalho criado na Area de Trabalho." -ForegroundColor $script:c.Green
    } catch {
        Write-Host "Nao foi possivel criar atalho na Area de Trabalho." -ForegroundColor $script:c.DarkGray
    }
    Write-Host "`nInstalacao concluida! Reinicie o PowerShell e digite 'tl'." -ForegroundColor $script:c.Green
    Wait-Key
    & $scriptPath
    exit
}

function Run-Tudo {
    Show-Banner
    Write-Host "Executando TODAS as otimizacoes..." -ForegroundColor $script:c.Magenta
    Write-Host "Backups serao salvos automaticamente." -ForegroundColor $script:c.Yellow
    Write-Host ""
    Backup-Servicos; Backup-Rede; Backup-Visual
    Write-Host ""; Run-LimpezaExtrema; Write-Host ""; Run-Servicos -SkipMenu; Write-Host ""; Run-Rede -SkipMenu; Write-Host ""; Run-Visual -SkipMenu
    Write-Host ""; Write-Host "TODAS AS OTIMIZACOES CONCLUIDAS!" -ForegroundColor $script:c.Green
    Write-Host "Use [8], [9] e [10] no menu para desfazer cada categoria." -ForegroundColor $script:c.Yellow
    Write-Host "Recomendado reiniciar o PC." -ForegroundColor $script:c.Yellow
    Wait-Key
}

# === CARREGAR TEMA ===
CarregarTema

# === ADMIN CHECK ===
$isAdmin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $isAdmin.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($PSCommandPath) {
        Write-Host "Reiniciando como ADMINISTRADOR..." -ForegroundColor $script:c.Yellow
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } else {
        Write-Host "ERRO: TL Optimizer precisa de privilegios de ADMINISTRADOR." -ForegroundColor $script:c.Red
        Write-Host "Feche este PowerShell e abra como Administrador:" -ForegroundColor $script:c.Yellow
        Write-Host "  1. Clique em Iniciar, digite 'PowerShell'" -ForegroundColor $script:c.Yellow
        Write-Host "  2. Clique com direito > Executar como administrador" -ForegroundColor $script:c.Yellow
        Write-Host "  3. Cole o comando novamente" -ForegroundColor $script:c.Yellow
        Write-Host ""; $null = Read-Host "Pressione ENTER para sair"
        exit
    }
}

# === WELCOME (modo portatil via iex) ===
if (-not $PSCommandPath) {
    do {
        Show-Welcome
        $modo = Read-Host "Digite P (Portatil) ou I (Instalar)"
        if ($modo -eq "P" -or $modo -eq "p") { break }
        if ($modo -eq "I" -or $modo -eq "i") { Install-Local; break }
    } while ($true)
}

# === AUTO-UPDATE (silencioso, somente versao instalada) ===
VerificarAtualizacao -Silencioso

# === MAIN LOOP ===
do {
    Show-Menu

    $opcao = Read-Host "Escolha uma opcao (ou 16 para ajuda)"

    switch ($opcao) {
        "1" { Show-Banner; Run-Limpeza; Wait-Key }
        "2" { Show-Banner; Run-LimpezaExtrema; Wait-Key }
        "3" { Show-Banner; Run-Servicos; Wait-Key }
        "4" { Show-Banner; Run-Rede; Wait-Key }
        "5" { Show-Banner; Run-Visual; Wait-Key }
        "6" { Run-Tudo }
        "7" { New-PontoRestauracao }
        "8" { Undo-Servicos }
        "9" { Undo-Rede }
        "10" { Undo-Visual }
        "11" { Show-Banner; Run-Browsers }
        "12" { Show-Banner; Run-UniversalUninstaller }
        "13" { Show-Banner; Run-DriverUpdater }
        "14" { Show-Banner; VerificarAtualizacao; Wait-Key }
        "15" { EscolherTema }
        "16" { Show-Help; Wait-Key }
        "0" { Write-Host "Saindo..." -ForegroundColor $script:c.Green; break }
        default { Write-Host "Opcao invalida! Tente novamente." -ForegroundColor $script:c.Red; Start-Sleep -Seconds 1 }
    }
} while ($opcao -ne "0")
