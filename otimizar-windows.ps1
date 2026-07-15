$ErrorActionPreference = "Continue"
$backupDir = "$env:LOCALAPPDATA\Otimizador"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$scriptUrl = "https://is.gd/tlotimizador"
$rawUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/otimizar-windows.ps1"
$script:versao = "1.4"
$DEV_NAME = "Thallas"
$DEV_DISCORD = "atdas"

$script:temaArquivo = "$backupDir\tema.json"
$script:temas = @{
    Padrao = @{ Cyan = "Cyan"; DarkCyan = "DarkCyan"; DarkGray = "DarkGray"; Gray = "Gray"; Green = "Green"; Magenta = "Magenta"; Red = "Red"; White = "White"; Yellow = "Yellow"; Blue = "Blue"; DarkBlue = "DarkBlue" }
    Matrix = @{ Cyan = "Green"; DarkCyan = "DarkGreen"; DarkGray = "DarkGreen"; Gray = "Green"; Green = "Green"; Magenta = "Green"; Red = "Red"; White = "Green"; Yellow = "Yellow"; Blue = "Green"; DarkBlue = "DarkGreen" }
    Roxo   = @{ Cyan = "Magenta"; DarkCyan = "DarkMagenta"; DarkGray = "DarkMagenta"; Gray = "Magenta"; Green = "Magenta"; Magenta = "Magenta"; Red = "Red"; White = "White"; Yellow = "Yellow"; Blue = "Magenta"; DarkBlue = "DarkMagenta" }
    Amarelo = @{ Cyan = "DarkYellow"; DarkCyan = "Yellow"; DarkGray = "DarkYellow"; Gray = "Yellow"; Green = "DarkGreen"; Magenta = "Yellow"; Red = "Red"; White = "White"; Yellow = "Yellow"; Blue = "Yellow"; DarkBlue = "DarkYellow" }
    Branco  = @{ Cyan = "DarkCyan"; DarkCyan = "DarkGray"; DarkGray = "DarkGray"; Gray = "Gray"; Green = "DarkGreen"; Magenta = "DarkMagenta"; Red = "Red"; White = "White"; Yellow = "DarkYellow"; Blue = "DarkCyan"; DarkBlue = "DarkGray" }
    Azul    = @{ Cyan = "Cyan"; DarkCyan = "DarkBlue"; DarkGray = "DarkBlue"; Gray = "Blue"; Green = "Cyan"; Magenta = "Blue"; Red = "Red"; White = "White"; Yellow = "Yellow"; Blue = "Blue"; DarkBlue = "DarkBlue" }
    Vermelho = @{ Cyan = "Red"; DarkCyan = "DarkRed"; DarkGray = "DarkRed"; Gray = "Red"; Green = "Red"; Magenta = "Red"; Red = "Red"; White = "White"; Yellow = "Yellow"; Blue = "Red"; DarkBlue = "DarkRed" }
}
$script:temaAtual = "Padrao"
$script:c = $script:temas.Padrao.Clone()
$Host.UI.RawUI.BackgroundColor = "Black"

# === MAXIMIZAR JANELA DO CONSOLE (ANTES DE QUALQUER OUTPUT) ===
try {
    Add-Type -Name "Win32" -Namespace "ConsoleUtil" -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
    $hWnd = [ConsoleUtil.Win32]::GetConsoleWindow()
    if ($hWnd -ne [IntPtr]::Zero) {
        [ConsoleUtil.Win32]::ShowWindow($hWnd, 3)  # SW_MAXIMIZE = 3
    }
    # Buffer width fixo para evitar quebra de linha em tela cheia
    $buf = $Host.UI.RawUI.BufferSize
    if ($buf.Width -lt 120) {
        $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size 120, $buf.Height
    }
    Clear-Host
} catch {}

function Pad-W {
    param([int]$Width)
    $tw = $Host.UI.RawUI.WindowSize.Width
    return " " * [Math]::Max(0, [Math]::Floor(($tw - $Width) / 2))
}

function Set-TermSize {
    param([int]$Width, [int]$Height)
    try {
        $max = $Host.UI.RawUI.MaxWindowSize
        $buf = $Host.UI.RawUI.BufferSize
        $w = [Math]::Min($Width, $max.Width)
        $h = [Math]::Min($Height, $max.Height)
        if ($buf.Width -lt $w -or $buf.Height -lt $h) {
            $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size ([Math]::Max($buf.Width, $w), [Math]::Max($buf.Height, $h))
        }
        $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size ($w, $h)
    } catch {}
}

# === FUNCOES DE RENDERIZACAO (tema unificado) ===
function Show-TopBorder {
    param([int]$Width, [string]$Color = $script:c.Cyan)
    $p = Pad-W $Width; $h = [char]0x2550
    Write-Host "$p$([char]0x2554)$("$h"*($Width-2))$([char]0x2557)" -ForegroundColor $Color
}
function Show-MidBorder {
    param([int]$Width, [string]$Color = $script:c.Cyan)
    $p = Pad-W $Width; $h = [char]0x2550
    Write-Host "$p$([char]0x2560)$("$h"*($Width-2))$([char]0x2563)" -ForegroundColor $Color
}
function Show-BotBorder {
    param([int]$Width, [string]$Color = $script:c.Cyan)
    $p = Pad-W $Width; $h = [char]0x2550
    Write-Host "$p$([char]0x255A)$("$h"*($Width-2))$([char]0x255D)" -ForegroundColor $Color
}
function Show-SubBorder {
    param([int]$Width, [string]$Color = $script:c.Cyan)
    $p = Pad-W $Width; $h = [char]0x2550
    Write-Host "$p$([char]0x255F)$("$h"*($Width-2))$([char]0x2562)" -ForegroundColor $Color
}
function Show-BoxLine {
    param([int]$Width, [string]$Text = "", [string]$Color = $script:c.White)
    $p = Pad-W $Width; $v = [char]0x2551
    $inner = $Width - 3
    $display = if ($Text.Length -gt $inner) { $Text.Substring(0, $inner - 2) + ".." } else { $Text.PadRight($inner) }
    Write-Host "$p$v $display$v" -ForegroundColor $Color
}
function Show-BoxTitle {
    param([int]$Width, [string]$Title, [string]$Color = $script:c.Cyan)
    $p = Pad-W $Width; $v = [char]0x2551; $inner = $Width - 4
    $padL = [Math]::Max(0, [Math]::Floor(($inner - $Title.Length) / 2))
    $padR = $inner - $Title.Length - $padL
    Write-Host "$p$v $(" "*$padL)$Title$(" "*$padR) $v" -ForegroundColor $Color
}

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
    $wid = 50; do {
        Clear-Host; Show-Banner
        Show-TopBorder $wid
        Show-BoxLine $wid "  Digite NUMERO para escolher o tema" $script:c.DarkCyan
        Show-MidBorder $wid
        $temp = 1
        foreach ($t in $script:temas.Keys | Sort-Object) {
            $marcador = if ($t -eq $script:temaAtual) { "[X]" } else { "[ ]" }
            $corItem = if ($t -eq $script:temaAtual) { $script:c.Green } else { $script:c.DarkGray }
            Show-BoxLine $wid ("  {0,2}. {1} {2,-20}" -f $temp, $marcador, $t) $corItem
            $temp++
        }
        Show-BotBorder $wid
        ""
        $choice = Read-Host "Numero (ou 0 para voltar)"
        if ($choice -eq "0") { SalvarTema; return }
        $num = [int]::TryParse($choice, [ref]$null)
        if ($num -and [int]$choice -ge 1 -and [int]$choice -le $script:temas.Count) {
            $chaves = @($script:temas.Keys | Sort-Object)
            $script:temaAtual = $chaves[[int]$choice - 1]
            $script:c = $script:temas[$script:temaAtual].Clone()
            SalvarTema
            Write-Host "Tema alterado para: $($script:temaAtual)" -ForegroundColor $script:c.Green
        }
    } while ($true)
}

function Get-ScriptPath {
    if ($PSCommandPath) { return $PSCommandPath }
    if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
    return "$env:USERPROFILE\TL-Optimizer\otimizar-windows.ps1"
}

function VerificarAtualizacao {
    param([switch]$Silencioso)
    try {
        $resp = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -ErrorAction Stop
        $scriptPath = Get-ScriptPath
        if (-not (Test-Path $scriptPath)) { if (-not $Silencioso) { Write-Host "Instalacao nao encontrada." -ForegroundColor $script:c.Yellow }; return }
        $tmp = "$env:TEMP\tl_update.ps1"
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($tmp, $resp.Content, $utf8Bom)
        if ((Get-FileHash $scriptPath).Hash -eq (Get-FileHash $tmp).Hash) {
            Remove-Item $tmp -Force
            if (-not $Silencioso) { Write-Host "Ja esta no ultimo commit." -ForegroundColor $script:c.Green }
            return
        }
        if ($Silencioso) {
            Remove-Item $tmp -Force
            return
        }
        if ((Get-Item $tmp).Length -lt 100) {
            Remove-Item $tmp -Force
            Write-Host "ERRO: Arquivo baixado parece corrompido (tamanho: $((Get-Item $tmp).Length) bytes)." -ForegroundColor $script:c.Red
            return
        }
        Write-Host "Atualizando..." -NoNewline -ForegroundColor $script:c.Yellow
        $backupFile = $null
        try {
            $ts = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupFile = "$($env:LOCALAPPDATA)\Otimizador\tl_backup_$ts.ps1"
            Copy-Item $scriptPath $backupFile -Force
            Copy-Item $tmp $scriptPath -Force
            Remove-Item $tmp -Force
            Write-Host " OK" -ForegroundColor $script:c.Green
            Write-Host "Backup salvo em: $backupFile" -ForegroundColor $script:c.DarkGray
            Write-Host "Reiniciando com a nova versao..." -ForegroundColor $script:c.Green
            Start-Sleep -Seconds 1
            & $scriptPath
            exit
        } catch {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Write-Host " ERRO: $($_.Exception.Message)" -ForegroundColor $script:c.Red
            if (Test-Path $backupFile) {
                Copy-Item $backupFile $scriptPath -Force
                Write-Host "Script original restaurado do backup." -ForegroundColor $script:c.Green
            }
            Write-Host "Reexecute o comando abaixo para obter a nova versao:" -ForegroundColor $script:c.Yellow
            Write-Host "  iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.Cyan
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
    param([int]$Width = 63, [string]$Cor = "")
    if (-not $Cor) { $Cor = $script:c.White }
    Clear-Host
    $p = Pad-W $Width
    $tl=[char]0x2554;$tr=[char]0x2557;$bl=[char]0x255A;$br=[char]0x255D;$h=[char]0x2550;$v=[char]0x2551
    $inner = $Width - 2
    $top = "$p$tl$("$h"*$inner)$tr"
    $bot = "$p$bl$("$h"*$inner)$br"
    $padL = [Math]::Max(0, [Math]::Floor(($inner - 12) / 2))
    $padR = $inner - 12 - $padL
    Write-Host $top -ForegroundColor $Cor
    Write-Host "$p$v$(" "*$padL)TL OPTIMIZER$(" "*$padR)$v" -ForegroundColor $Cor
    $padL = [Math]::Max(0, [Math]::Floor(($inner - 4) / 2))
    $padR = $inner - 4 - $padL
    Write-Host "$p$v$(" "*$padL)v$($script:versao)$(" "*$padR)$v" -ForegroundColor $Cor
    Write-Host $bot -ForegroundColor $Cor
    Write-Host ""
}
function Show-Help {
    Clear-Host
    $p = Pad-W 63
    $h=[char]0x2550;$v=[char]0x2551
    $tl=[char]0x2554;$tr=[char]0x2557;$bl=[char]0x255A;$br=[char]0x255D
    $top = "$p$tl$("$h"*61)$tr"
    $sep = "$p$([char]0x2560)$("$h"*61)$([char]0x2563)"
    $bot = "$p$bl$("$h"*61)$br"
    $sf = "$p$v{0,-61}$v"

    Write-Host $top -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  ### GUIA RAPIDO ###") -ForegroundColor $script:c.White
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  TWEAK (1-8)  - Melhorias de sistema") -ForegroundColor $script:c.Yellow
    Write-Host ($sf -f "   1. Central de Acao - Notificacoes") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   2. Cache Updates - Limpa downloads") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   3. Hibernacao - Libera RAM") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   4. Pagefile - Otimiza memoria virtual") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   5. Take Ownership - Menu de contexto") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   6. Updates 2077 - Pausar atualizacoes") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   7. Compact/LZX - Comprime o Windows") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   8. Remover UWP - Apps desnecessarios") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  LIMPEZA (10-16) - Liberar espaco") -ForegroundColor $script:c.Red
    Write-Host ($sf -f "   10. Logs de Eventos - Limpa logs antigos") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   11. Cache Windows - Libera espaco") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   12. DNS Cache - Reseta cache DNS") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   13. Temporarios - Limpa arquivos temp") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   14. Limpeza Extrema - Libera GBs") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   15. CleanMgr - Ferramenta nativa") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   16. DISM - Repara o Windows") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  INSTALADOR (20-23) - Apps via Winget") -ForegroundColor $script:c.Green
    Write-Host ($sf -f "   20. Winget Apps - Instalar/Desinstalar programas") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   22. Drivers - Atualizar drivers") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   23. Desinstalar - Universal") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  REDE (30-36) - Otimizacao de rede") -ForegroundColor $script:c.Green
    Write-Host ($sf -f "   30-35. DNS Google/Cloudflare/OpenDNS/Quad9/AdGuard/DHCP") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   36. Rede Completa - Winsock, IP, DNS, Auto-tuning") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  SISTEMA (40-46) - Recursos Avancados") -ForegroundColor $script:c.Blue
    Write-Host ($sf -f "   40. Windows Features / 41. Power Plan") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   42. Edicoes Windows / 43. Windows Update") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   44. Gaming / 45. Tema / 46. Sobre") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  FERRAMENTAS (60-66) - Manutencao") -ForegroundColor $script:c.Blue
    Write-Host ($sf -f "   60. Backup / 61. Restaurar / 62. Usuarios") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   63. CMD Cores / 64. Som Mod") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   65. Presets / 66. Undo Log") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   67. Rotina Completa - Executa TUDO") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  PRIVACIDADE (50-54) - Privacidade & Desfazer") -ForegroundColor $script:c.Magenta
    Write-Host ($sf -f "   50. O&O ShutUp10++ / 51. Privacidade (cores)") -ForegroundColor $script:c.DarkGray
    Write-Host ($sf -f "   52. Undo Servicos / 53. Undo Rede / 54. Undo Visual") -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host ($sf -f "  [0] Sair  [H] ou [?] para este help") -ForegroundColor $script:c.Red
    Write-Host $bot -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "$p Como usar: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.Cyan
    Write-Host "$p Depois de instalado (tl), e so digitar 'tl'" -ForegroundColor $script:c.DarkGray
    Write-Host "$p Backups ficam em: %LOCALAPPDATA%\Otimizador" -ForegroundColor $script:c.DarkGray
}

function Show-Menu {
    $sp = Get-SystemSpecs
    $specLines = @(
        "SO:     $($sp.OS)",
        "CPU:    $($sp.CPU)",
        "RAM:    $($sp.RAM)",
        "GPU:    $($sp.GPU)",
        "Uptime: $($sp.Uptime)",
        "Usuario: $($sp.Usuario)",
        "PC: $($sp.PC)",
        "TPM: $($sp.TPM)   NET 4: $($sp.Net4)",
        "Fuso: $($sp.Fuso)"
    )
    foreach ($d in $sp.Discos) {
        $specLines += "Disco $($d.Letra):  $($d.Livre)/$($d.Total) GB  $($d.Bar)  $($d.Pct)%"
    }
    $maxLen = ($specLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    $h=[char]0x2500;$v=[char]0x2502

    function Show-GridRow {
        param($c1, $c2, $c3, $hdr1, $hdr2, $hdr3, $color, $cw3)
        function T { param($s, $n) if (-not $s) { " " * $n } else { $s.PadRight($n) } }
        $rows = [Math]::Max([Math]::Max($c1.Count, $c2.Count), $c3.Count)
        $nw3 = $cw3 - 9
        $tl=[char]0x2554;$tr=[char]0x2557;$bl=[char]0x255A;$br=[char]0x255D
        $tc=[char]0x2566;$bc=[char]0x2569;$ml=[char]0x2560;$mr=[char]0x2563;$mc=[char]0x256C
        $grid_top = "$p$tl$("$h"*$cw3)$tc$("$h"*$cw3)$tc$("$h"*$cw3)$tr"
        $grid_sep = "$p$ml$("$h"*$cw3)$mc$("$h"*$cw3)$mc$("$h"*$cw3)$mr"
        $grid_bot = "$p$bl$("$h"*$cw3)$bc$("$h"*$cw3)$bc$("$h"*$cw3)$br"
        Write-Host $grid_top -ForegroundColor $color
        Write-Host ("$p$v  {0,-$($cw3-3)} $v  {1,-$($cw3-3)} $v  {2,-$($cw3-3)} $v" -f $hdr1, $hdr2, $hdr3) -ForegroundColor $script:c.White
        Write-Host $grid_sep -ForegroundColor $color
        for ($i = 0; $i -lt $rows; $i++) {
            $v1 = if ($i -lt $c1.Count) { $c1[$i] } else { $null }
            $v2 = if ($i -lt $c2.Count) { $c2[$i] } else { $null }
            $v3 = if ($i -lt $c3.Count) { $c3[$i] } else { $null }
            $s1 = if ($v1 -and $v1[0] -is [string] -and $v1[0] -ne "") { " [$($v1[0].PadLeft(2))] | $(T $v1[1] $nw3) " } else { " "*$cw3 }
            $s2 = if ($v2 -and $v2[0] -is [string] -and $v2[0] -ne "") { " [$($v2[0].PadLeft(2))] | $(T $v2[1] $nw3) " } else { " "*$cw3 }
            $s3 = if ($v3 -and $v3[0] -is [string] -and $v3[0] -ne "") { " [$($v3[0].PadLeft(2))] | $(T $v3[1] $nw3) " } else { " "*$cw3 }
            Write-Host "$p$v$s1$v$s2$v$s3$v" -ForegroundColor $color
        }
        Write-Host $grid_bot -ForegroundColor $color
        Write-Host ""
    }

    $t1 = @( @("1","Central de Acao"), @("2","Cache Updates"), @("3","Hibernacao"), @("4","Pagefile"), @("5","Take Ownership"), @("6","Updates 2077"), @("7","Compact/LZX"), @("8","Remover UWP"), @("18","End Task"), @("19","Menu Classico"), @("24","Home/Gallery"), @("25","WPBT"), @("26","Device Companio"), @("27","Notificacoes"), @("28","Storage Sense"), @("29","Core Isolation") )
    $t2 = @( @("10","Logs Eventos"), @("11","Cache Windows"), @("12","DNS Cache"), @("13","Temporarios"), @("14","Limpeza Extrema"), @("15","CleanMgr"), @("16","DISM"), @("",""), @("",""), @("","") )
    $t3 = @( @("20","Winget Apps"), @("22","Drivers"), @("23","Desinstalar"), @("",""), @("30","DNS Google"), @("31","DNS Cloudflare"), @("32","DNS OpenDNS"), @("33","DNS Quad9"), @("34","DNS AdGuard"), @("35","DNS DHCP"), @("36","Rede Completa"), @("37","Rede Avancada") )

    $t4 = @( @("40","Windows Features"), @("41","Power Plan"), @("42","Edicoes Win"), @("43","Win Update"), @("45","Tema"), @("46","Sobre"), @("48","Game Mode"), @("49","Game Bar"), @("56","GPU Scheduling"), @("57","Prioridade"), @("58","HiPerf Plan"), @("59","Nagle"), @("70","Dark Mode"), @("71","Extensoes"), @("72","Ocultos"), @("73","BSoD Verbose"), @("74","Bateria %"), @("75","Scrollbars"), @("76","Logon Verbose"), @("77","MPO") )
    $t5 = @( @("60","Backup"), @("61","Restaurar"), @("62","Usuarios"), @("63","CMD Cores"), @("64","Som Mod"), @("66","Undo Log"), @("67","Rotina Completa"), @("80","Exportar Preset"), @("81","Importar Preset"), @("","") )
    $t6 = @( @("52","Undo Servicos"), @("53","Undo Rede"), @("54","Undo Visual"), @("55","Undo Privacidade"), @("84","ShutUp10 Abrir"), @("85","ShutUp10 Redown"), @("86","Telemetria"), @("87","Cortana"), @("88","Localizacao"), @("89","Anuncios"), @("90","Wi-Fi Sense"), @("91","Ativ. Voz"), @("92","Hosts"), @("93","Win Update"), @("94","MS Account"), @("95","Defender") )

    $t7 = @( @("17","Limpar Cache Fivem") )

    $hdrG1="TWEAK";$hdrG2="LIMPEZA";$hdrG3="INSTALAR + REDE"
    $hdrB1="SISTEMA";$hdrB2="FERRAMENTAS";$hdrB3="PRIVACIDADE"
    $hdrC1="FIVEM"

    $todosItens = @($t1)+@($t2)+@($t3)+@($t4)+@($t5)+@($t6)+@($t7)
    $todosHdrs = @($hdrG1,$hdrG2,$hdrG3,$hdrB1,$hdrB2,$hdrB3,$hdrC1)
    $maxTexto = 0
    foreach ($item in $todosItens) {
        if ($item[1] -ne "") { $maxTexto = [Math]::Max($maxTexto, $item[1].Length) }
    }
    foreach ($hd in $todosHdrs) { $maxTexto = [Math]::Max($maxTexto, $hd.Length) }

    $cw3 = $maxTexto + 11
    $gridW = $cw3 * 3 + 4
    $boxW = [Math]::Max([Math]::Max(63, $maxLen + 5), $gridW)
    if ($boxW % 2 -eq 0) { $boxW++ }
    if ($cw3 % 2 -ne 0) { $cw3++ }
    $gridW = $cw3 * 3 + 4
    if ($gridW -gt $boxW) { $boxW = $gridW; if ($boxW % 2 -eq 0) { $boxW++ } }

    $contentW = $boxW - 5
    Set-TermSize -Width ($boxW + 4) -Height $Host.UI.RawUI.WindowSize.Height
    Show-Banner -Width $boxW
    $p = Pad-W $boxW
    $tt=[char]0x2554;$tr=[char]0x2557;$tb=[char]0x255A;$te=[char]0x255D;$th=[char]0x2550;$tv=[char]0x2551
    $st = "$p$tt$("$th"*($boxW-2))$tr"
    $sb = "$p$tb$("$th"*($boxW-2))$te"
    $sf = "$p$tv  {0,-$contentW} $tv"
    Write-Host $st -ForegroundColor $script:c.White
    foreach ($s in $specLines) { Write-Host ($sf -f $s) -ForegroundColor $script:c.White }
    Write-Host $sb -ForegroundColor $script:c.White
    Write-Host ""

    Show-GridRow -c1 $t1 -c2 $t2 -c3 $t3 -hdr1 $hdrG1 -hdr2 $hdrG2 -hdr3 $hdrG3 -color $script:c.Green -cw3 $cw3
    Show-GridRow -c1 $t4 -c2 $t5 -c3 $t6 -hdr1 $hdrB1 -hdr2 $hdrB2 -hdr3 $hdrB3 -color $script:c.Blue -cw3 $cw3
    $hv = [char]0x2550; $vv = [char]0x2551
    Write-Host "$p$([char]0x2554)$("$hv"*($boxW-2))$([char]0x2557)" -ForegroundColor $script:c.Magenta
    Write-Host "$p$vv  FIVEM$(" " * ($boxW-8))$vv" -ForegroundColor $script:c.Magenta
    Write-Host "$p$([char]0x2560)$("$hv"*($boxW-2))$([char]0x2563)" -ForegroundColor $script:c.Magenta
    Write-Host "$p$vv  [17] Limpar Cache Fivem$(" " * ($boxW-26))$vv" -ForegroundColor $script:c.White
    Write-Host "$p$([char]0x255A)$("$hv"*($boxW-2))$([char]0x255D)" -ForegroundColor $script:c.Magenta
    Write-Host ""

    $rows1 = [Math]::Max([Math]::Max($t1.Count, $t2.Count), $t3.Count)
    $rows2 = [Math]::Max([Math]::Max($t4.Count, $t5.Count), $t6.Count)
    $rows3 = 6
    $totalH = 16 + $specLines.Count + $rows1 + $rows2 + $rows3
    Set-TermSize -Width ($boxW + 4) -Height ($totalH + 2)

    Write-Host "$p[0] Sair  [U] Verificar Atualizacao  [H] Ajuda  [D] Desinstalar" -ForegroundColor $script:c.Red
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
    $wid = 58
    do {
        Clear-Host; Show-Banner
        $i = 1
        foreach ($s in $Servicos) {
            $check = if ($s.Selected) { "[X]" } else { "[ ]" }
            $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
            $status = if ($svc) { "$($svc.Status)" } else { "AUSENTE" }
            $corItem = if ($s.Selected) { $script:c.Green } else { $script:c.DarkGray }
            if ($i -eq 1) {
                Show-TopBorder $wid
                Show-BoxLine $wid "  Digite NUMERO para marcar/desmarcar" $script:c.DarkCyan
                Show-MidBorder $wid
            }
            Show-BoxLine $wid ("  {0,2}. {1} {2,-28} {3,-9}" -f $i, $check, $s.Desc, $status) $corItem
            foreach ($linha in (Wrap-Texto -Texto $s.Detalhe -Largura 48)) {
                Show-BoxLine $wid ("    {0,-48}" -f $linha) $script:c.DarkGray
            }
            $i++
        }
        Show-SubBorder $wid
        Show-BoxLine $wid "  [A] Aplicar  [T] Marcar todos  [0] Voltar" $script:c.Yellow
        Show-BotBorder $wid
        ""
        $choice = Read-Host "Escolha"
        if ($choice -eq "0") { return $null }
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

    foreach ($s in $paraDesativar) { Log-Tweak "Servico" "Desativou" $s.Nome -ValorAntigo "" -ValorNovo "Disabled" }
    foreach ($s in $paraAtivar) { Log-Tweak "Servico" "Ativou" $s.Nome -ValorAntigo "Disabled" -ValorNovo "Automatic" }

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

    Write-Host ""; Write-Host "Servicos ajustados! Use [52] no menu para desfazer." -ForegroundColor $script:c.Green
}

function Reverter-DNS {
    param($backupRede)
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

function Set-DirectDNS {
    param([string]$Provider)
    $dnsMap = @{
        "Google"    = @("8.8.8.8", "8.8.4.4")
        "Cloudflare" = @("1.1.1.1", "1.0.0.1")
        "OpenDNS"   = @("208.67.222.222", "208.67.220.220")
        "Quad9"     = @("9.9.9.9", "149.112.112.112")
        "AdGuard"   = @("94.140.14.14", "94.140.15.15")
        "Default"   = @()
    }
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" }
    if ($Provider -eq "Default") {
        foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue }
        Write-Host "[DNS] Restaurado para DHCP" -ForegroundColor $script:c.Green
    } else {
        $servers = $dnsMap[$Provider]
        foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $servers -ErrorAction SilentlyContinue }
        Write-Host "[DNS] Alterado para $Provider ($($servers[0]))" -ForegroundColor $script:c.Green
    }
    Log-Tweak "Rede" "DNS: $Provider" "DNS"
}

function Run-Rede {
    param([switch]$SkipMenu)
    $itens = @(
        @{Nome = "LiberarRenovarIP"; Desc = "Liberar e renovar IP"; Selected = $true; Detalhe = "Libera o endereco IP atual e pega um novo do roteador. Resolve problemas de conexao quando a internet para de funcionar do nada."}
        @{Nome = "ResetWinsock"; Desc = "Resetar Winsock e TCP/IP"; Selected = $true; Detalhe = "Reseta a pilha de rede do Windows. Corrige erros de conexao, DNS e rede que outros metodos nao resolvem."}
        @{Nome = "DNSGoogle"; Desc = "DNS Google (8.8.8.8)"; Selected = $false; Detalhe = "DNS publico do Google. Rapido e confiavel, funciona bem em qualquer regiao."}
        @{Nome = "DNSCloudflare"; Desc = "DNS Cloudflare (1.1.1.1)"; Selected = $true; Detalhe = "DNS do Cloudflare. Prioriza privacidade (nao registra IPs) e e muito rapido."}
        @{Nome = "DNSOpenDNS"; Desc = "DNS OpenDNS (208.67.222.222)"; Selected = $false; Detalhe = "DNS da Cisco com filtro de phishing integrado. Bloqueia sites maliciosos automaticamente."}
        @{Nome = "DNSQuad9"; Desc = "DNS Quad9 (9.9.9.9)"; Selected = $false; Detalhe = "DNS que bloqueia dominios maliciosos conhecidos usando threat intelligence de varios fornecedores."}
        @{Nome = "DNSAdGuard"; Desc = "DNS AdGuard (94.140.14.14)"; Selected = $false; Detalhe = "DNS com bloqueio de anuncios e rastreadores a nivel de DNS. Funciona em qualquer navegador."}
        @{Nome = "DNSDefault"; Desc = "DNS Padrao (DHCP)"; Selected = $false; Detalhe = "Volta ao DNS fornecido automaticamente pelo roteador (DHCP). Desfaz alteracoes de DNS."}
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
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" }

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
            "DNSGoogle" {
                Write-Host "[DNS Google (8.8.8.8)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4") -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSCloudflare" {
                Write-Host "[DNS Cloudflare (1.1.1.1)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSOpenDNS" {
                Write-Host "[DNS OpenDNS (208.67.222.222)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("208.67.222.222", "208.67.220.220") -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSQuad9" {
                Write-Host "[DNS Quad9 (9.9.9.9)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("9.9.9.9", "149.112.112.112") -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSAdGuard" {
                Write-Host "[DNS AdGuard (94.140.14.14)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("94.140.14.14", "94.140.15.15") -ErrorAction SilentlyContinue }
                Write-Host " OK" -ForegroundColor $script:c.Green
            }
            "DNSDefault" {
                Write-Host "[DNS Padrao (DHCP)]..." -NoNewline
                foreach ($adapter in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue }
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
            "DNSGoogle" { Reverter-DNS $backupRede }
            "DNSCloudflare" { Reverter-DNS $backupRede }
            "DNSOpenDNS" { Reverter-DNS $backupRede }
            "DNSQuad9" { Reverter-DNS $backupRede }
            "DNSAdGuard" { Reverter-DNS $backupRede }
            "DNSDefault" { Write-Host "[DNS DHCP - NAO REVERTIVEL]..." -ForegroundColor $script:c.DarkGray }
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

    Write-Host ""; Write-Host "Rede otimizada! Use [53] no menu para desfazer." -ForegroundColor $script:c.Green
}

function Show-GenericoSubmenu {
    param([array]$Itens, [string]$Titulo)
    $wid = 50
    do {
        Clear-Host; Show-Banner
        $i = 1
        foreach ($item in $Itens) {
            $check = if ($item.Selected) { "[X]" } else { "[ ]" }
            $corItem = if ($item.Selected) { $script:c.Green } else { $script:c.DarkGray }
            if ($i -eq 1) {
                Show-TopBorder $wid
                Show-BoxLine $wid "  Digite NUMERO para marcar/desmarcar" $script:c.DarkCyan
                Show-MidBorder $wid
            }
            Show-BoxLine $wid ("  {0,2}. {1} {2,-37}" -f $i, $check, $item.Desc) $corItem
            foreach ($linha in (Wrap-Texto -Texto $item.Detalhe -Largura 42)) {
                Show-BoxLine $wid ("    {0,-40}" -f $linha) $script:c.DarkGray
            }
            $i++
        }
        Show-SubBorder $wid
        Show-BoxLine $wid "  [A] Aplicar  [T] Marcar todos  [0] Voltar" $script:c.Yellow
        Show-BotBorder $wid
        ""
        $choice = Read-Host "Escolha"
        if ($choice -eq "0") { return $null }
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

    Write-Host ""; Write-Host "Ajustes visuais aplicados! Use [54] no menu para desfazer." -ForegroundColor $script:c.Green
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

function Undo-Privacidade {
    Show-Banner
    Write-Host ">>> DESFAZER - PRIVACIDADE <<<" -ForegroundColor $script:c.Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\privacidade_backup.json")) {
        Write-Host "Nenhum backup de privacidade encontrado." -ForegroundColor $script:c.Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\privacidade_backup.json" | ConvertFrom-Json
    foreach ($key in $backup.PSObject.Properties) {
        $pathName = $key.Name
        $value = $key.Value
        $path = $pathName.Substring(0, $pathName.LastIndexOf('\'))
        $name = $pathName.Substring($pathName.LastIndexOf('\') + 1)
        Write-Host "[$name @ $path]..." -NoNewline
        Set-ItemProperty -Path $path -Name $name -Value $value -Force -ErrorAction SilentlyContinue
        Write-Host " RESTAURADO" -ForegroundColor $script:c.Green
    }
    Write-Host ""; Write-Host "Privacidade restaurada!" -ForegroundColor $script:c.Green
    Remove-Item "$backupDir\privacidade_backup.json" -Force -ErrorAction SilentlyContinue
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
    $deletarSetup = $true
    if (Test-Path "C:\`$Windows.~BT" -or Test-Path "C:\`$Windows.~WS") {
        Write-Host "`n" -NoNewline
        Write-Host "  [!] AVISO: Isso vai impedir que voce volte para a versao" -ForegroundColor $script:c.Red
        Write-Host "  anterior do Windows (rollback de versao)." -ForegroundColor $script:c.Red
        $conf = Read-Host "  Deseja deletar mesmo assim? (S/N)"
        if ($conf -ne "S" -and $conf -ne "s") { $deletarSetup = $false }
    }
    if ($deletarSetup) {
        Remove-Item -Path "C:\`$Windows.~BT" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\`$Windows.~WS" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Setup\Scripts\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Panther\*.log" -Force -ErrorAction SilentlyContinue
        Write-Host " OK" -ForegroundColor $script:c.Green
    } else {
        Write-Host " PULADO" -ForegroundColor $script:c.Yellow
    }

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
function Confirm-Assinatura {
    param([string]$FilePath, [string]$Origem)
    $sig = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue
    if (-not $sig -or $sig.Status -ne "Valid") {
        $status = if ($sig) { $sig.StatusDescription } else { "Nao assinado" }
        Write-Host "`n[!] AVISO DE SEGURANCA:" -ForegroundColor $script:c.Red
        Write-Host "    O arquivo baixado NAO possui assinatura digital valida!" -ForegroundColor $script:c.Red
        Write-Host "    Status: $status" -ForegroundColor $script:c.Yellow
        Write-Host "    Origem: $Origem" -ForegroundColor $script:c.DarkGray
        Write-Host "    Executar um arquivo nao confiavel pode ser arriscado." -ForegroundColor $script:c.Yellow
        $conf = Read-Host "Deseja continuar mesmo assim? (S/N)"
        if ($conf -ne "S" -and $conf -ne "s") { return $false }
    }
    return $true
}

function Run-DriverUpdater {
    $itens = @(
        @{Nome = "Driver Easy";       Desc = "Driver Easy";        URL = "https://www.drivereasy.com/download-free/"; DownloadURL = "https://www.drivereasy.com/DriverEasy_Setup.exe"; Detalhe = "Escaneia o PC e encontra drivers desatualizados. Versao gratuita baixa um driver por vez. Interface simples e intuitiva."}
        @{Nome = "Driver Booster";    Desc = "Driver Booster";     URL = "https://www.iobit.com/pt/driver-booster.php"; DownloadURL = "https://download.iobit.com/driver_booster_setup.exe"; Detalhe = "Da IObit. Atualiza drivers com um clique, tem modo game e faz backup antes de atualizar. Versao gratuita tem limite de velocidade."}
        @{Nome = "Snappy Driver Installer"; Desc = "SDI"; URL = "https://www.snappy-driver-installer.org/download/"; DownloadURL = "https://DriverOff.net/sdi/SDI_R2601.7z"; Detalhe = "Ferramenta portatil que baixa e instala drivers. Codigo aberto, sem propagandas e sem limitacoes."}
    )
    do {
        Clear-Host; Show-Banner
        $p = Pad-W 48
        $h=[char]0x2550;$v=[char]0x2551;$w=46
        $top = "$p$([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $sep = "$p$([char]0x2560)$("$h"*$w)$([char]0x2563)"
        $bot = "$p$([char]0x255A)$("$h"*$w)$([char]0x255D)"
        $i = 1
        foreach ($item in $itens) {
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor $script:c.Cyan
                Write-Host "$p$v  Digite NUMERO para instalar ou desinstalar    $v" -ForegroundColor $script:c.DarkCyan
                Write-Host $sep -ForegroundColor $script:c.Cyan
            }
            Write-Host "$p$v  $("{0,2}" -f $i). $("{0,-38}" -f $item.Desc) $v" -ForegroundColor $script:c.White
            foreach ($linha in (Wrap-Texto -Texto $item.Detalhe -Largura 40)) {
                Write-Host "$p$v  $("{0,-42}" -f "  $linha")   $v" -ForegroundColor $script:c.DarkGray
            }
            $i++
        }
        Write-Host $bot -ForegroundColor $script:c.Cyan
        Write-Host ""
        $choice = Read-Host "Numero (ou 0 para voltar)"
        if ($choice -eq "0") { return }
        $num = [int]::TryParse($choice, [ref]$null)
        if (-not $num -or [int]$choice -lt 1 -or [int]$choice -gt $itens.Count) { continue }
        $item = $itens[[int]$choice - 1]
        Show-Banner
        Write-Host "$p$([char]0x2554)$("$h"*$w)$([char]0x2557)" -ForegroundColor $script:c.Cyan
        Write-Host "$p$v  $($item.Desc)  $v" -ForegroundColor $script:c.White
        Write-Host "$p$([char]0x2560)$("$h"*$w)$([char]0x2563)" -ForegroundColor $script:c.Cyan
        Write-Host "$p$v  [I] Instalar - baixar e instalar automaticamente $v" -ForegroundColor $script:c.Green
        Write-Host "$p$v  [D] Desinstalar - remover do PC               $v" -ForegroundColor $script:c.Red
        Write-Host "$p$v  [0] Voltar                                    $v" -ForegroundColor $script:c.Yellow
        Write-Host "$p$([char]0x255A)$("$h"*$w)$([char]0x255D)" -ForegroundColor $script:c.Cyan
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
                        if (Confirm-Assinatura -FilePath $filePath -Origem $item.DownloadURL) {
                            Write-Host "Iniciando instalador..." -ForegroundColor $script:c.Cyan
                            Start-Process $filePath
                        } else { throw "Execucao cancelada pelo usuario." }
                        return
                    }
                    $exe = Get-ChildItem $extractDir -Filter "*.exe" -Recurse | Where-Object { $_.Name -match '^SDI' } | Select-Object -First 1
                    if (-not $exe) { $exe = Get-ChildItem $extractDir -Filter "*.exe" -Recurse | Select-Object -First 1 }
                    if ($exe) {
                        if (Confirm-Assinatura -FilePath $exe.FullName -Origem $item.DownloadURL) {
                            Write-Host "Iniciando $($exe.Name)..." -ForegroundColor $script:c.Cyan
                            Start-Process $exe.FullName
                        } else { throw "Execucao cancelada pelo usuario." }
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
                $chaves = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
                $prog = $null
                foreach ($chave in $chaves) {
                    $prog = Get-ItemProperty $chave -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$nomeBusca*" } | Select-Object -First 1
                    if ($prog) { break }
                }
                if (-not $prog) {
                    foreach ($chave in $chaves) {
                        $prog = Get-ItemProperty $chave -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$($item.Desc)*" } | Select-Object -First 1
                        if ($prog) { break }
                    }
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
                Write-Host "[2/3] Limpando arquivos residuais..." -ForegroundColor $script:c.Yellow
                $pastas = @("$env:PROGRAMFILES\$nomeBase*", "${env:ProgramFiles(x86)}\$nomeBase*", "$env:LOCALAPPDATA\$nomeBase*", "$env:APPDATA\$nomeBase*", "$env:PROGRAMDATA\$nomeBase*", "$env:USERPROFILE\$nomeBase*")
                foreach ($pasta in $pastas) {
                    if (Test-Path $pasta) {
                        Remove-Item $pasta -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [OK] $pasta" -ForegroundColor $script:c.Green
                    } else {
                        Write-Host "  [--] $pasta" -ForegroundColor $script:c.DarkGray
                    }
                }
                Write-Host "[3/3] Limpando registros..." -ForegroundColor $script:c.Yellow
                $regs = @("HKCU:\Software\$nomeBase", "HKLM:\Software\$nomeBase", "HKLM:\Software\WOW6432Node\$nomeBase")
                foreach ($r in $regs) {
                    if (Test-Path $r) {
                        Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [OK] $r" -ForegroundColor $script:c.Green
                    } else {
                        Write-Host "  [--] $r" -ForegroundColor $script:c.DarkGray
                    }
                }
                $uninstReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($prog.DisplayName)"
                if (Test-Path $uninstReg) {
                    Remove-Item $uninstReg -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] $uninstReg" -ForegroundColor $script:c.Green
                }
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
        $p = Pad-W 60
        $lista = if ($filtro) { $todos | Where-Object { $_.Nome -match $filtro } } else { $todos }
        $h=[char]0x2550;$v=[char]0x2551
        $top = "$p$([char]0x2554)$("$h"*58)$([char]0x2557)"
        $bot = "$p$([char]0x255A)$("$h"*58)$([char]0x255D)"
        Write-Host $top -ForegroundColor $script:c.Magenta
        Write-Host "$p$v              DESINSTALADOR UNIVERSAL                  $v" -ForegroundColor $script:c.Magenta
        Write-Host "$p$v  /texto = buscar   NUMERO = desinstalar   [0] Voltar $v" -ForegroundColor $script:c.DarkCyan
        Write-Host "$p$v  Filtro: $(if ($filtro) { $filtro } else { '(todos)' })                          $v" -ForegroundColor $script:c.Yellow
        Write-Host $bot -ForegroundColor $script:c.Magenta
        if ($lista.Count -eq 0) {
            Write-Host "$p Nenhum programa encontrado com esse filtro." -ForegroundColor $script:c.DarkGray
        } else {
            $i = 1
            foreach ($item in $lista) {
                Write-Host "$p $("{0,3}" -f $i). $("{0,-55}" -f $(if ($item.Nome.Length -gt 55) { $item.Nome.Substring(0,52) + '...' } else { $item.Nome }))" -ForegroundColor $script:c.Gray
                $i++
            }
        }
        Write-Host "$p ---- $($lista.Count) programa(s) ----" -ForegroundColor $script:c.DarkGray
        Write-Host ""
        $cmd = Read-Host "Comando"
        if ($cmd -eq "0") { return }
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
            Write-Host "[2/3] Limpando arquivos residuais..." -ForegroundColor $script:c.Yellow
            $pastas = @("$env:PROGRAMFILES\$nomeBase*", "$env:ProgramFiles(x86)\$nomeBase*", "$env:LOCALAPPDATA\$nomeBase*", "$env:APPDATA\$nomeBase*", "$env:PROGRAMDATA\$nomeBase*", "$env:USERPROFILE\$nomeBase*")
            foreach ($pasta in $pastas) {
                if (Test-Path $pasta) {
                    Remove-Item $pasta -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] $pasta" -ForegroundColor $script:c.Green
                } else {
                    Write-Host "  [--] $pasta" -ForegroundColor $script:c.DarkGray
                }
            }
            if ($pubBase) {
                $pubPastas = @("$env:PROGRAMDATA\$pubBase*", "$env:LOCALAPPDATA\$pubBase*", "$env:APPDATA\$pubBase*")
                foreach ($pp in $pubPastas) {
                    if (Test-Path $pp) {
                        Remove-Item $pp -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [OK] $pp" -ForegroundColor $script:c.Green
                    } else {
                        Write-Host "  [--] $pp" -ForegroundColor $script:c.DarkGray
                    }
                }
            }
            Write-Host "[3/3] Limpando registros..." -ForegroundColor $script:c.Yellow
            $regs = @("HKCU:\Software\$nomeBase", "HKLM:\Software\$nomeBase", "HKLM:\Software\WOW6432Node\$nomeBase")
            foreach ($r in $regs) {
                if (Test-Path $r) {
                    Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] $r" -ForegroundColor $script:c.Green
                } else {
                    Write-Host "  [--] $r" -ForegroundColor $script:c.DarkGray
                }
            }
            if ($pubBase) {
                $pubRegs = @("HKCU:\Software\$pubBase", "HKLM:\Software\$pubBase")
                foreach ($pr in $pubRegs) {
                    if (Test-Path $pr) {
                        Remove-Item $pr -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [OK] $pr" -ForegroundColor $script:c.Green
                    } else {
                        Write-Host "  [--] $pr" -ForegroundColor $script:c.DarkGray
                    }
                }
            }
            $uninstReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($prog.Nome)"
            if (Test-Path $uninstReg) {
                Remove-Item $uninstReg -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  [OK] $uninstReg" -ForegroundColor $script:c.Green
            }
            Write-Host ""; Write-Host "Desinstalacao e limpeza concluidas!" -ForegroundColor $script:c.Green; Wait-Key; return
        }
        if ($cmd -eq "") { continue }
        Write-Host "Comando invalido!" -ForegroundColor $script:c.Red; Start-Sleep 1
    } while ($true)
}

function Wait-Key {
    Write-Host ""; Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor $script:c.Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Welcome {
    Clear-Host
    $p = Pad-W 42
    $b = [char]0x2554; $b2 = [char]0x2557; $b3 = [char]0x255A; $b4 = [char]0x255D; $h2 = [char]0x2550; $v2 = [char]0x2551
    Write-Host "$p$b$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b2" -ForegroundColor $script:c.Cyan
    Write-Host "$p$v2       T L   O P T I M I Z E R         $v2" -ForegroundColor $script:c.Cyan
    Write-Host "$p$b3$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b4" -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "$p TL Optimizer foi carregado via iwr | iex." -ForegroundColor $script:c.Yellow
    Write-Host "$p Escolha como deseja usa-lo:" -ForegroundColor $script:c.Yellow
    Write-Host ""
    Write-Host "$p [P] Portatil  - Roda agora, nada e salvo no PC." -ForegroundColor $script:c.Green
    Write-Host "$p                Use quando quiser testar ou usar" -ForegroundColor $script:c.DarkGray
    Write-Host "$p                uma unica vez. Comando sempre funciona." -ForegroundColor $script:c.DarkGray
    Write-Host ""
    Write-Host "$p [I] Instalar  - Salva em $env:USERPROFILE\TL-Optimizer" -ForegroundColor $script:c.Cyan
    Write-Host "$p                e registra no perfil do PowerShell." -ForegroundColor $script:c.Cyan
    Write-Host "$p                Depois e so digitar 'tl' de qualquer lugar." -ForegroundColor $script:c.DarkGray
    Write-Host ""
}

function Uninstall-TL {
    $p = Pad-W 44
    Write-Host "$p DESINSTALAR TL OPTIMIZER" -ForegroundColor $script:c.Red
    Write-Host "$p Isso vai remover TODOS os arquivos e rastros:" -ForegroundColor $script:c.Yellow
    Write-Host "$p  - Pasta %USERPROFILE%\TL-Optimizer" -ForegroundColor $script:c.DarkGray
    Write-Host "$p  - Atalho na Area de Trabalho" -ForegroundColor $script:c.DarkGray
    Write-Host "$p  - Alias 'tl' do perfil PowerShell" -ForegroundColor $script:c.DarkGray
    Write-Host "$p  - Backups em %LOCALAPPDATA%\Otimizador" -ForegroundColor $script:c.DarkGray
    Write-Host ""
    $conf = Read-Host "$p Confirmar desinstalacao? (S/N)"
    if ($conf -ne "S" -and $conf -ne "s") { Write-Host "$p Cancelado." -ForegroundColor $script:c.Yellow; return }
    Write-Host ""
    $installDir = "$env:USERPROFILE\TL-Optimizer"
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "$p [OK] Pasta TL-Optimizer removida" -ForegroundColor $script:c.Green
    } else { Write-Host "$p [--] Pasta TL-Optimizer nao encontrada" -ForegroundColor $script:c.DarkGray }
    $shortcutPath = "$env:USERPROFILE\Desktop\TL Optimizer.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue
        Write-Host "$p [OK] Atalho removido" -ForegroundColor $script:c.Green
    } else { Write-Host "$p [--] Atalho nao encontrado" -ForegroundColor $script:c.DarkGray }
    $backupDirPath = "$env:LOCALAPPDATA\Otimizador"
    if (Test-Path $backupDirPath) {
        Remove-Item $backupDirPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "$p [OK] Backups removidos" -ForegroundColor $script:c.Green
    } else { Write-Host "$p [--] Backups nao encontrados" -ForegroundColor $script:c.DarkGray }
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (Test-Path $profilePath) {
        $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if ($content -match '# TL Optimizer') {
            $newContent = $content -replace '[\r\n]*# TL Optimizer[\r\n]*function tl-optimizer.*[\r\n]*Set-Alias -Name tl -Value tl-optimizer -Force[\r\n]*', ''
            Set-Content -Path $profilePath -Value $newContent -Force -ErrorAction SilentlyContinue
            Write-Host "$p [OK] Alias 'tl' removido do perfil" -ForegroundColor $script:c.Green
        } else { Write-Host "$p [--] Alias 'tl' nao encontrado no perfil" -ForegroundColor $script:c.DarkGray }
    } else { Write-Host "$p [--] Perfil PowerShell nao encontrado" -ForegroundColor $script:c.DarkGray }
    Write-Host ""
    Write-Host "$p TL Optimizer foi completamente removido." -ForegroundColor $script:c.Green
    Start-Sleep -Seconds 2
    exit
}

function Install-Local {
    $p = Pad-W 44
    $targetDir = "$env:USERPROFILE\TL-Optimizer"
    $scriptPath = "$targetDir\otimizar-windows.ps1"
    Write-Host "$p Instalando em $targetDir..." -ForegroundColor $script:c.Cyan
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    try {
        iwr -useb "$scriptUrl" -OutFile $scriptPath -ErrorAction Stop
        Write-Host "$p Script salvo." -ForegroundColor $script:c.Green
    } catch {
        Write-Host "$p Erro ao baixar o script. Salvando da memoria..." -ForegroundColor $script:c.Yellow
        if ($global:MyInvocation.MyCommand.ScriptContents) {
            $global:MyInvocation.MyCommand.ScriptContents | Set-Content -Path $scriptPath -Force
        } else {
            Write-Host "$p Nao foi possivel salvar. Verifique a conexao." -ForegroundColor $script:c.Red
            Wait-Key; return
        }
    }
    $iconPath = Join-Path $targetDir "icon.ico"
    $iconUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/icon.ico"
    try {
        iwr -useb "$iconUrl" -OutFile $iconPath -ErrorAction Stop
        Write-Host "$p Icone baixado." -ForegroundColor $script:c.Green
    } catch {
        $srcIcon = Join-Path (Get-Location) "icon.ico"
        if (Test-Path $srcIcon) {
            Copy-Item $srcIcon $iconPath -Force
            Write-Host "$p Icone local copiado." -ForegroundColor $script:c.Green
        } else {
            Write-Host "$p Icone padrao sera usado (sem internet)." -ForegroundColor $script:c.DarkGray
        }
    }
    $profileLine = "`n# TL Optimizer`nfunction tl-optimizer { & `"$scriptPath`" }`nSet-Alias -Name tl -Value tl-optimizer -Force"
    $profilePath = $PROFILE.CurrentUserAllHosts
    $dir = Split-Path $profilePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not (Test-Path $profilePath) -or (Get-Content $profilePath -Raw) -notmatch '# TL Optimizer') {
        Add-Content -Path $profilePath -Value $profileLine -Force
        Write-Host "$p Alias 'tl' adicionado ao perfil PowerShell." -ForegroundColor $script:c.Green
    } else {
        Write-Host "$p Alias 'tl' ja existe no perfil." -ForegroundColor $script:c.Yellow
    }
    $shortcutPath = "$env:USERPROFILE\Desktop\TL Optimizer.lnk"
    try {
        $currentShell = (Get-Process -Id $PID).Path
        $wshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $currentShell
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $shortcut.WorkingDirectory = $targetDir
        $shortcut.Description = "TL Optimizer - Otimizador de Windows"
        $iconPath = Join-Path $targetDir "icon.ico"
        if (Test-Path $iconPath) {
            $shortcut.IconLocation = $iconPath
        } else {
            $shortcut.IconLocation = "%SystemRoot%\System32\imageres.dll,23"
        }
        $shortcut.Save()
        try {
            $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
            $bytes[0x15] = $bytes[0x15] -bor 0x20
            [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
        } catch {}
        Write-Host "$p Atalho criado na Area de Trabalho (admin automatico)." -ForegroundColor $script:c.Green
    } catch {
        Write-Host "$p Nao foi possivel criar atalho na Area de Trabalho." -ForegroundColor $script:c.DarkGray
    }
    Write-Host "$p `nInstalacao concluida! Reinicie o PowerShell e digite 'tl'." -ForegroundColor $script:c.Green
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
    Write-Host "Use [52], [53] e [54] no menu para desfazer cada categoria." -ForegroundColor $script:c.Yellow
    Write-Host "Recomendado reiniciar o PC." -ForegroundColor $script:c.Yellow
    Wait-Key
}

# === CARREGAR TEMA ===
CarregarTema

# === ADMIN CHECK ===
$isAdmin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $isAdmin.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $scriptToRun = if ($PSCommandPath) { $PSCommandPath } else { Get-ScriptPath }
    if (Test-Path $scriptToRun) {
        Write-Host "Reiniciando como ADMINISTRADOR..." -ForegroundColor $script:c.Yellow
        $currentShell = (Get-Process -Id $PID).Path
        Start-Process -FilePath $currentShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptToRun`"" -Verb RunAs
        Start-Sleep -Seconds 1
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

# === FUNCOES TWEAK ===

function Tweak-ActionCenter {
    Write-Host "`n[+] Central de Acao" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    $policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $policyPath -Force -ErrorAction SilentlyContinue | Out-Null
    if ($opt -eq "A" -or $opt -eq "a") {
        Remove-ItemProperty -Path $policyPath -Name "DisableNotificationCenter" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Central de Acao ativada" -ForegroundColor $script:c.Green
    } elseif ($opt -eq "D" -or $opt -eq "d") {
        Set-ItemProperty -Path $policyPath -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Central de Acao desativada" -ForegroundColor $script:c.Green
    }
}

function Tweak-CacheUpdates {
    Write-Host "`n[+] Cache Updates" -ForegroundColor $script:c.Yellow
    Write-Host "  [L] Limpar cache de updates" -ForegroundColor $script:c.Cyan
    $opt = Read-Host "Confirma? (S/N)"
    if ($opt -eq "S" -or $opt -eq "s") {
        try {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Write-Host "[OK] Cache de updates limpo" -ForegroundColor $script:c.Green
        } catch {
            Write-Host "[ERRO] Falha ao limpar cache de updates" -ForegroundColor $script:c.Red
        }
    } else {
        Write-Host "[--] Operacao cancelada" -ForegroundColor $script:c.DarkGray
    }
}

function Tweak-Hibernation {
    Write-Host "`n[+] Hibernacao" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    if ($opt -eq "A" -or $opt -eq "a") {
        powercfg /hibernate on 2>$null
        Write-Host "[OK] Hibernacao ativada" -ForegroundColor $script:c.Green
    } elseif ($opt -eq "D" -or $opt -eq "d") {
        powercfg /hibernate off 2>$null
        Write-Host "[OK] Hibernacao desativada" -ForegroundColor $script:c.Green
    }
}

function Tweak-Pagefile {
    Write-Host "`n[+] Pagefile" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar - configurar tamanho manual" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar - gerenciamento automatico" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    try {
        if ($opt -eq "A" -or $opt -eq "a") {
            $ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
            $init = [math]::Round($ram / 1MB * 0.5)
            $max = [math]::Round($ram / 1MB * 1.5)
            $cs = Get-CimInstance Win32_ComputerSystem
            Invoke-CimMethod -InputObject $cs -MethodName SetAutomaticManagedPagefile -Arguments @{AutomaticManagedPagefile=$false} -ErrorAction SilentlyContinue | Out-Null
            $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
            if (-not $pf) {
                Invoke-CimMethod -ClassName Win32_PageFileSetting -MethodName Create -Arguments @{Name="C:\pagefile.sys"; InitialSize=$init; MaximumSize=$max} -ErrorAction SilentlyContinue | Out-Null
                Write-Host "[OK] Pagefile criado: ${init}MB / ${max}MB" -ForegroundColor $script:c.Green
            } else {
                Write-Host "Pagefile ja existe." -NoNewline -ForegroundColor $script:c.Yellow
                $conf = Read-Host " Reconfigurar? (S/N)"
                if ($conf -eq "S" -or $conf -eq "s") {
                    Set-CimInstance -InputObject $pf -Property @{InitialSize=$init; MaximumSize=$max} -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "[OK] Pagefile reconfigurado: ${init}MB / ${max}MB" -ForegroundColor $script:c.Green
                } else {
                    Write-Host "[OK] Pagefile mantido como estava." -ForegroundColor $script:c.Gray
                }
            }
        } elseif ($opt -eq "D" -or $opt -eq "d") {
            $cs = Get-CimInstance Win32_ComputerSystem
            Invoke-CimMethod -InputObject $cs -MethodName SetAutomaticManagedPagefile -Arguments @{AutomaticManagedPagefile=$true} -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[OK] Pagefile em gerenciamento automatico" -ForegroundColor $script:c.Green
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar pagefile: $_" -ForegroundColor $script:c.Red
    }
}

function Tweak-TakeOwnership {
    Write-Host "`n[+] Take Ownership" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar - adicionar ao menu de contexto" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar - remover do menu de contexto" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    try {
        if ($opt -eq "A" -or $opt -eq "a") {
            $regPath = "HKLM:\SOFTWARE\Classes\*\shell\TakeOwnership"
            New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Take Ownership" -Force -ErrorAction SilentlyContinue
            New-Item -Path "$regPath\command" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "$regPath\command" -Name "(Default)" -Value 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F' -Force -ErrorAction SilentlyContinue
            $regPathDir = "HKLM:\SOFTWARE\Classes\Directory\shell\TakeOwnership"
            New-Item -Path $regPathDir -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $regPathDir -Name "(Default)" -Value "Take Ownership" -Force -ErrorAction SilentlyContinue
            New-Item -Path "$regPathDir\command" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path "$regPathDir\command" -Name "(Default)" -Value 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t' -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Take Ownership adicionado ao menu de contexto" -ForegroundColor $script:c.Green
        } elseif ($opt -eq "D" -or $opt -eq "d") {
            Remove-Item -Path "HKLM:\SOFTWARE\Classes\*\shell\TakeOwnership" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKLM:\SOFTWARE\Classes\Directory\shell\TakeOwnership" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Take Ownership removido do menu de contexto" -ForegroundColor $script:c.Green
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar Take Ownership" -ForegroundColor $script:c.Red
    }
}

function Tweak-Updates2077 {
    Write-Host "`n[+] Updates 2077" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar - baixar e notificar" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar - pausar ate 2077" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    try {
        if ($opt -eq "A" -or $opt -eq "a") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdates" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Updates ativados (padrao do Windows)" -ForegroundColor $script:c.Green
        } elseif ($opt -eq "D" -or $opt -eq "d") {
            Write-Host "`n[!] AVISO DE SEGURANCA:" -ForegroundColor $script:c.Red
            Write-Host "    Manter o Windows sem atualizacoes por muito tempo" -ForegroundColor $script:c.Yellow
            Write-Host "    deixa o sistema vulneravel a ameacas de seguranca." -ForegroundColor $script:c.Yellow
            Write-Host "    Vulnerabilidades conhecidas nao serao corrigidas." -ForegroundColor $script:c.Yellow
            Write-Host ""
            Write-Host "  Escolha uma opcao:" -ForegroundColor $script:c.White
            Write-Host "    1. Pausar por 30 dias (recomendado)" -ForegroundColor $script:c.Green
            Write-Host "    2. Pausar por 60 dias" -ForegroundColor $script:c.Yellow
            Write-Host "    3. Pausar por 90 dias" -ForegroundColor $script:c.Yellow
            Write-Host "    4. Pausar ate 2077 (risco maximo)" -ForegroundColor $script:c.Red
            Write-Host "    0. Cancelar" -ForegroundColor $script:c.Gray
            $pauseOpt = Read-Host "Escolha"
            switch ($pauseOpt) {
                "1" { $pauseDays = 30; $pauseDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd") }
                "2" { $pauseDays = 60; $pauseDate = (Get-Date).AddDays(60).ToString("yyyy-MM-dd") }
                "3" { $pauseDays = 90; $pauseDate = (Get-Date).AddDays(90).ToString("yyyy-MM-dd") }
                "4" { $pauseDays = 365; $pauseDate = "2077-12-31" }
                default { Write-Host "Cancelado." -ForegroundColor $script:c.Yellow; return }
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdates" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Value $pauseDays -Type DWord -Force -ErrorAction SilentlyContinue
            $regPath2 = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
            New-Item -Path $regPath2 -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $regPath2 -Name "PausedQualityDate" -Value $pauseDate -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath2 -Name "PausedFeatureDate" -Value $pauseDate -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Updates pausados ate $pauseDate" -ForegroundColor $script:c.Green
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar updates" -ForegroundColor $script:c.Red
    }
}

function Tweak-CompactLZX {
    Write-Host "`n[+] Compact/LZX" -ForegroundColor $script:c.Yellow
    $os = Get-CimInstance Win32_OperatingSystem
    if ([version]$os.Version -lt [version]"10.0.17763") {
        Write-Host "[--] Requer Windows 10 1809 ou superior" -ForegroundColor $script:c.DarkGray
        return
    }
    Write-Host "  [A] Ativar - comprimir sistema (~30% economia)" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar - descomprimir" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    try {
        if ($opt -eq "A" -or $opt -eq "a") {
            compact /compactOS:LZX 2>$null
            Write-Host "[OK] Compact/LZX ativado" -ForegroundColor $script:c.Green
        } elseif ($opt -eq "D" -or $opt -eq "d") {
            compact /compactOS:never 2>$null
            Write-Host "[OK] Compact/LZX desativado" -ForegroundColor $script:c.Green
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar Compact/LZX" -ForegroundColor $script:c.Red
    }
}

function Tweak-RemoverUWP {
    Write-Host "`n[+] Remover UWP - Listando apps..." -ForegroundColor $script:c.Yellow
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[ERRO] Precisa ser ADMINISTRADOR para remover apps do sistema." -ForegroundColor $script:c.Red
        return
    }
    $apps = @(
        "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.GetHelp",
        "Microsoft.Getstarted", "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.People", "Microsoft.PowerAutomateDesktop", "Microsoft.Todos",
        "Microsoft.WindowsMaps", "Microsoft.WindowsFeedbackHub",
        "Microsoft.ZuneMusic", "Microsoft.ZuneVideo", "Microsoft.549981C3F5F10",
        "Microsoft.WindowsAlarms", "Microsoft.MicrosoftOfficeHub"
    )
    $i = 0
    foreach ($app in $apps) {
        $found = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($found) { $i++ }
    }
    if ($i -eq 0) {
        Write-Host "[--] Nenhum app UWP removivel encontrado" -ForegroundColor $script:c.DarkGray
        return
    }
    Write-Host "  [R] Remover apps listados" -ForegroundColor $script:c.Red
    Write-Host "  [I] Reinstalar apps padrao (via Store)" -ForegroundColor $script:c.Green
    $opt = Read-Host "Escolha (R/I/0)"
    if ($opt -eq "R" -or $opt -eq "r") {
        $opt2 = Read-Host "Confirma remocao? (S/N)"
        if ($opt2 -eq "S" -or $opt2 -eq "s") {
            try {
                foreach ($app in $apps) {
                    $found = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
                    if ($found) {
                        Remove-AppxPackage -Package $found.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                        Write-Host "[OK] Removido: $app" -ForegroundColor $script:c.Green
                    }
                }
            } catch {
                Write-Host "[!] Alguns apps nao puderam ser removidos: $($_.Exception.Message)" -ForegroundColor $script:c.Yellow
            }
        } else { Write-Host "[--] Cancelado" -ForegroundColor $script:c.DarkGray }
    } elseif ($opt -eq "I" -or $opt -eq "i") {
        Write-Host "[+] Reinstalando apps padrao do Windows..." -ForegroundColor $script:c.Yellow
        $defaultApps = @(
            "Microsoft.WindowsCamera", "Microsoft.Windows.Photos", "Microsoft.WindowsCalculator",
            "Microsoft.WindowsAlarms", "Microsoft.WindowsSoundRecorder", "Microsoft.WindowsMaps",
            "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.YourPhone",
            "Microsoft.MicrosoftSolitaireCollection", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
            "Microsoft.People", "Microsoft.Todos", "Microsoft.Office.OneNote"
        )
        foreach ($app in $defaultApps) {
            Write-Host "  Instalando $app..." -NoNewline
            $result = winget install --id $app --silent --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor $script:c.Green }
            else { Write-Host " (ja instalado ou indisponivel)" -ForegroundColor $script:c.DarkGray }
        }
        Write-Host "[OK] Reinstalacao concluida" -ForegroundColor $script:c.Green
    } else {
        Write-Host "[--] Operacao cancelada" -ForegroundColor $script:c.DarkGray
    }
}

# === FUNCOES LIMPEZA ===

function Clear-EventLogs {
    Write-Host "`n[+] Logs de Eventos" -ForegroundColor $script:c.Red
    Write-Host "  [!] Isso vai apagar todo o historico de logs do sistema," -ForegroundColor $script:c.Yellow
    Write-Host "  incluindo registros uteis para diagnostico de problemas." -ForegroundColor $script:c.Yellow
    $conf = Read-Host "  Deseja limpar todos os logs? (S/N)"
    if ($conf -ne "S" -and $conf -ne "s") { Write-Host "  CANCELADO" -ForegroundColor $script:c.Yellow; return }
    Write-Host "  Limpando..." -NoNewline
    $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { $_.RecordCount -gt 0 -and $_.IsEnabled }
    $count = 0
    foreach ($log in $logs) {
        try {
            wevtutil cl $log.LogName 2>$null
            $count++
        } catch {}
    }
    Write-Host "[OK] $count logs de eventos limpos" -ForegroundColor $script:c.Green
}

function Clear-CacheWindows {
    Write-Host "`n[+] Cache Windows - Limpando..." -ForegroundColor $script:c.Red
    try {
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Cache limpo" -ForegroundColor $script:c.Green
    } catch { Write-Host "[OK] Cache limpo" -ForegroundColor $script:c.Green }
}

function Clear-DNSCache {
    Write-Host "`n[+] DNS Cache - Limpando..." -ForegroundColor $script:c.Red
    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        ipconfig /flushdns 2>$null | Out-Null
        Write-Host "[OK] DNS Cache limpo" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "[ERRO] Falha ao limpar DNS Cache" -ForegroundColor $script:c.Red
    }
}

function Clear-Temporarios {
    Write-Host "`n[+] Temporarios - Limpando..." -ForegroundColor $script:c.Red
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Temporarios limpos" -ForegroundColor $script:c.Green
    } catch { Write-Host "[OK] Temporarios limpos" -ForegroundColor $script:c.Green }
}

# === FIVEM CACHE ===
function Clear-FiveMCache {
    Write-Host "`n[+] FIVEM - Limpando Cache..." -ForegroundColor $script:c.Yellow
    $dataPath = "$env:LOCALAPPDATA\FiveM\FiveM.app\data"
    if (-not (Test-Path $dataPath)) {
        Write-Host "[!] FIVEM nao encontrado em: $dataPath" -ForegroundColor $script:c.Red
        Write-Host "[!] Certifique-se de que o FIVEM esta instalado." -ForegroundColor $script:c.Yellow
        return
    }
    $alvos = @("cache", "nui-storage", "server-cache", "server-cache-priv")
    $total = 0
    foreach ($alvo in $alvos) {
        $itemPath = Join-Path $dataPath $alvo
        if (Test-Path $itemPath) {
            try {
                $size = (Get-ChildItem $itemPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item $itemPath -Recurse -Force -ErrorAction SilentlyContinue
                $mb = [math]::Round($size / 1MB, 2)
                Write-Host "  [OK] $alvo removido ($mb MB)" -ForegroundColor $script:c.Green
                $total += $size
            } catch { Write-Host "  [!] Erro ao remover $alvo" -ForegroundColor $script:c.Red }
        } else { Write-Host "  [--] $alvo nao encontrado" -ForegroundColor $script:c.DarkGray }
    }
    $totalMB = [math]::Round($total / 1MB, 2)
    Write-Host "[OK] Cache do FIVEM limpo: $totalMB MB liberados" -ForegroundColor $script:c.Cyan
    Log-Tweak "Limpeza" "Limpou" "FIVEM Cache"
}

function Run-CleanMgr {
    Write-Host "`n[+] CleanMgr - Executando..." -ForegroundColor $script:c.Red
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            Set-ItemProperty -Path $item.PSPath -Name "StateFlags0064" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:64" -Wait -ErrorAction SilentlyContinue
        Write-Host "[OK] CleanMgr executado" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "[ERRO] Falha ao executar CleanMgr" -ForegroundColor $script:c.Red
    }
}

function Run-DISM {
    Write-Host "`n[+] DISM - Verificando e reparando..." -ForegroundColor $script:c.Red
    Write-Host "[...] Isso pode levar varios minutos..." -ForegroundColor $script:c.DarkGray
    try {
        DISM /Online /Cleanup-Image /ScanHealth 2>$null
        DISM /Online /Cleanup-Image /RestoreHealth 2>$null
        Write-Host "[OK] DISM concluido" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "[ERRO] Falha ao executar DISM" -ForegroundColor $script:c.Red
    }
}

# === FUNCOES INSTALADOR (WINGET) ===

$script:wingetApps = @(
    @{Cat="Navegadores";     Name="Google Chrome";        ID="Google.Chrome"}
    @{Cat="Navegadores";     Name="Mozilla Firefox";      ID="Mozilla.Firefox"}
    @{Cat="Navegadores";     Name="Brave";                ID="Brave.Brave"}
    @{Cat="Navegadores";     Name="Vivaldi";              ID="Vivaldi.Vivaldi"}
    @{Cat="Navegadores";     Name="Opera";                ID="Opera.Opera"}
    @{Cat="Navegadores";     Name="Tor Browser";          ID="TorProject.TorBrowser"}
    @{Cat="Navegadores";     Name="Microsoft Edge";       ID="Microsoft.Edge"}
    @{Cat="Navegadores";     Name="Opera GX";             ID="Opera.OperaGX"}
    @{Cat="Utilidades";      Name="7-Zip";                ID="7zip.7zip"}
    @{Cat="Utilidades";      Name="VLC";                  ID="VideoLAN.VLC"}
    @{Cat="Utilidades";      Name="Notepad++";            ID="Notepad++.Notepad++"}
    @{Cat="Utilidades";      Name="Git";                  ID="Git.Git"}
    @{Cat="Utilidades";      Name="Python 3";             ID="Python.Python.3.13"}
    @{Cat="Utilidades";      Name="Node.js LTS";          ID="OpenJS.NodeJS.LTS"}
    @{Cat="Utilidades";      Name="VS Code";              ID="Microsoft.VisualStudioCode"}
    @{Cat="Utilidades";      Name="Discord";              ID="Discord.Discord"}
    @{Cat="Utilidades";      Name="WhatsApp";             ID="WhatsApp.WhatsApp"}
    @{Cat="Utilidades";      Name="Telegram";             ID="Telegram.TelegramDesktop"}
    @{Cat="Utilidades";      Name="Steam";                ID="Valve.Steam"}
    @{Cat="Utilidades";      Name="Epic Games Launcher";  ID="EpicGames.EpicGamesLauncher"}
    @{Cat="Utilidades";      Name="OBS Studio";           ID="OBSProject.OBSStudio"}
    @{Cat="Utilidades";      Name="ShareX";               ID="ShareX.ShareX"}
    @{Cat="Utilidades";      Name="Everything";           ID="Voidtools.Everything"}
    @{Cat="Utilidades";      Name="PowerToys";            ID="Microsoft.PowerToys"}
    @{Cat="Utilidades";      Name="Microsoft To Do";      ID="Microsoft.MicrosoftToDo"}
    @{Cat="Utilidades";      Name="OneNote";              ID="Microsoft.Office.OneNote"}
    @{Cat="Utilidades";      Name="EarTrumpet";           ID="FileNewProject.EarTrumpet"}
    @{Cat="Utilidades";      Name="Fluent Search";        ID="FluentSearch.FluentSearch"}
    @{Cat="Utilidades";      Name="Rufus";                ID="Rufus.Rufus"}
    @{Cat="Utilidades";      Name="BalenaEtcher";         ID="Balena.Etcher"}
    @{Cat="Utilidades";      Name="Ventoy";               ID="Ventoy.Ventoy"}
    @{Cat="Utilidades";      Name="HWiNFO";               ID="HWiNFO.HWiNFO"}
    @{Cat="Utilidades";      Name="CPU-Z";                ID="CPUID.CPU-Z"}
    @{Cat="Utilidades";      Name="GPU-Z";                ID="TechPowerUp.GPU-Z"}
    @{Cat="Utilidades";      Name="CrystalDiskInfo";      ID="CrystalDewWorld.CrystalDiskInfo"}
    @{Cat="Imagem";          Name="GIMP";                 ID="GIMP.GIMP"}
    @{Cat="Imagem";          Name="Paint.NET";            ID="dotPDN.PaintDotNet"}
    @{Cat="Imagem";          Name="IrfanView";            ID="IrfanSkiljan.IrfanView"}
    @{Cat="Imagem";          Name="XnView MP";            ID="XnView.XnViewMP"}
    @{Cat="Imagem";          Name="Krita";                ID="KDE.Krita"}
    @{Cat="Imagem";          Name="Inkscape";             ID="Inkscape.Inkscape"}
    @{Cat="Imagem";          Name="Blender";              ID="BlenderFoundation.Blender"}
    @{Cat="Imagem";          Name="Darktable";            ID="Darktable.Darktable"}
    @{Cat="Imagem";          Name="Photopea";             ID="Photopea.Photopea"}
    @{Cat="Video";           Name="OBS Studio";           ID="OBSProject.OBSStudio"}
    @{Cat="Video";           Name="HandBrake";            ID="HandBrake.HandBrake"}
    @{Cat="Video";           Name="OpenShot";             ID="OpenShot.OpenShot"}
    @{Cat="Video";           Name="Shotcut";              ID="Meltytech.Shotcut"}
    @{Cat="Video";           Name="Kdenlive";             ID="KDE.Kdenlive"}
    @{Cat="Video";           Name="DaVinci Resolve";      ID="BlackmagicDesign.DaVinciResolve"}
    @{Cat="Video";           Name="CapCut";               ID="Bytedance.CapCut"}
    @{Cat="Video";           Name="LosslessCut";          ID="Mifi.LosslessCut"}
    @{Cat="Video";           Name="MKVToolNix";           ID="MoritzBunkus.MKVToolNix"}
    @{Cat="Video";           Name="StaxRip";              ID="StaxRip.StaxRip"}
    @{Cat="Midia";           Name="Spotify";              ID="Spotify.Spotify"}
    @{Cat="Midia";           Name="Pot Player";           ID="Daum.PotPlayer"}
    @{Cat="Midia";           Name="MPV";                  ID="Shizuku.MPV"}
    @{Cat="Midia";           Name="AIMP";                 ID="AIMP.AIMP"}
    @{Cat="Midia";           Name="MusicBee";             ID="MusicBee.MusicBee"}
    @{Cat="Midia";           Name="foobar2000";           ID="PeterPawlowski.foobar2000"}
    @{Cat="Midia";           Name="Plex";                 ID="Plex.Plex"}
    @{Cat="Midia";           Name="Jellyfin Media Player"; ID="Jellyfin.JellyfinMediaPlayer"}
    @{Cat="Dev";             Name="Docker Desktop";       ID="Docker.DockerDesktop"}
    @{Cat="Dev";             Name="Postman";              ID="Postman.Postman"}
    @{Cat="Dev";             Name="PuTTY";                ID="PuTTY.PuTTY"}
    @{Cat="Dev";             Name="WinSCP";               ID="WinSCP.WinSCP"}
    @{Cat="Dev";             Name="Visual Studio 2022";   ID="Microsoft.VisualStudio.2022.Community"}
    @{Cat="Dev";             Name="Visual Studio Code";   ID="Microsoft.VisualStudioCode"}
    @{Cat="Dev";             Name="IntelliJ IDEA CE";     ID="JetBrains.IntelliJIDEA.Community"}
    @{Cat="Dev";             Name="PyCharm CE";           ID="JetBrains.PyCharm.Community"}
    @{Cat="Dev";             Name="WebStorm";             ID="JetBrains.WebStorm"}
    @{Cat="Dev";             Name="DataGrip";             ID="JetBrains.DataGrip"}
    @{Cat="Dev";             Name="Rider";                ID="JetBrains.Rider"}
    @{Cat="Dev";             Name="GoLand";               ID="JetBrains.GoLand"}
    @{Cat="Dev";             Name="RustRover";            ID="JetBrains.RustRover"}
    @{Cat="Dev";             Name="Android Studio";       ID="Google.AndroidStudio"}
    @{Cat="Dev";             Name="WSL";                  ID="Microsoft.WSL"}
    @{Cat="Dev";             Name="Windows Terminal";     ID="Microsoft.WindowsTerminal"}
    @{Cat="Dev";             Name="PowerShell 7";         ID="Microsoft.PowerShell"}
    @{Cat="Dev";             Name="Node.js LTS";          ID="OpenJS.NodeJS.LTS"}
    @{Cat="Dev";             Name="Python 3.13";          ID="Python.Python.3.13"}
    @{Cat="Dev";             Name="Java 21 (Temurin)";    ID="EclipseAdoptium.Temurin.21.JDK"}
    @{Cat="Dev";             Name="Rust";                 ID="Rustlang.Rustup"}
    @{Cat="Dev";             Name="Git for Windows";      ID="Git.Git"}
    @{Cat="Dev";             Name="GitHub Desktop";       ID="GitHub.GitHubDesktop"}
    @{Cat="Dev";             Name="GitKraken";            ID="Axosoft.GitKraken"}
    @{Cat="Dev";             Name="Sourcetree";           ID="Atlassian.Sourcetree"}
    @{Cat="Dev";             Name="Insomnia";             ID="Insomnia.Insomnia"}
    @{Cat="Dev";             Name="HTTPie";               ID="HTTPie.HTTPie"}
    @{Cat="Dev";             Name="Bruno";                ID="UsmanB.Extract"}
    @{Cat="Compactacao";     Name="WinRAR";               ID="RARLab.WinRAR"}
    @{Cat="Compactacao";     Name="PeaZip";               ID="PeaZip.PeaZip"}
    @{Cat="Compactacao";     Name="Bandizip";             ID="Bandisoft.Bandizip"}
    @{Cat="Compactacao";     Name="7-Zip";                ID="7zip.7zip"}
    @{Cat="Compactacao";     Name="WinZip";               ID="WinZip.WinZip"}
    @{Cat="Seguranca";       Name="Bitwarden";            ID="Bitwarden.Bitwarden"}
    @{Cat="Seguranca";       Name="KeePassXC";            ID="KeePassXC.KeePassXC"}
    @{Cat="Seguranca";       Name="VeraCrypt";            ID="IDRIX.VeraCrypt"}
    @{Cat="Seguranca";       Name="OpenVPN Connect";      ID="OpenVPN.OpenVPNConnect"}
    @{Cat="Seguranca";       Name="WireGuard";            ID="WireGuard.WireGuard"}
    @{Cat="Seguranca";       Name="Malwarebytes";         ID="Malwarebytes.Malwarebytes"}
    @{Cat="Escritorio";      Name="LibreOffice";          ID="TheDocumentFoundation.LibreOffice"}
    @{Cat="Escritorio";      Name="OnlyOffice";           ID="AscensioSystem.OnlyOffice"}
    @{Cat="Escritorio";      Name="WPS Office";           ID="Kingsoft.WPSOffice"}
    @{Cat="Escritorio";      Name="Notion";               ID="Notion.Notion"}
    @{Cat="Escritorio";      Name="Obsidian";             ID="Obsidian.Obsidian"}
    @{Cat="Escritorio";      Name="Joplin";               ID="Joplin.Joplin"}
    @{Cat="Escritorio";      Name="Typora";               ID="Typora.Typora"}
    @{Cat="Escritorio";      Name="SumatraPDF";           ID="SumatraPDF.SumatraPDF"}
    @{Cat="Escritorio";      Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader"}
    @{Cat="Escritorio";      Name="Foxit Reader";         ID="Foxit.FoxitReader"}
    @{Cat="Streaming";       Name="Streamlabs Desktop";   ID="Streamlabs.Streamlabs"}
    @{Cat="Streaming";       Name="Streamer.bot";         ID="StreamerBot.StreamerBot"}
    @{Cat="Streaming";       Name="VTube Studio";         ID="VTubeStudio.VTubeStudio"}
    @{Cat="Streaming";       Name="OBS WebSocket";        ID="OBSProject.OBSWebSocket"}
    @{Cat="Social";          Name="Discord";              ID="Discord.Discord"}
    @{Cat="Social";          Name="Telegram";             ID="Telegram.TelegramDesktop"}
    @{Cat="Social";          Name="WhatsApp";             ID="WhatsApp.WhatsApp"}
    @{Cat="Social";          Name="Signal";               ID="Signal.Signal"}
    @{Cat="Social";          Name="Threema";              ID="Threema.Threema"}
    @{Cat="Social";          Name="Element";              ID="Element.Element"}
    @{Cat="Social";          Name="Slack";                ID="Slack.Slack"}
    @{Cat="Social";          Name="Zoom";                 ID="Zoom.Zoom"}
    @{Cat="Social";          Name="Microsoft Teams";      ID="Microsoft.Teams"}
    @{Cat="Social";          Name="Skype";                ID="Skype.Skype"}
    @{Cat="Jogos";           Name="Steam";                ID="Valve.Steam"}
    @{Cat="Jogos";           Name="Epic Games Launcher";  ID="EpicGames.EpicGamesLauncher"}
    @{Cat="Jogos";           Name="GOG Galaxy";           ID="GOG.Galaxy"}
    @{Cat="Jogos";           Name="Battle.net";           ID="Blizzard.BattleNet"}
    @{Cat="Jogos";           Name="Ubisoft Connect";      ID="Ubisoft.UbisoftConnect"}
    @{Cat="Jogos";           Name="EA App";               ID="ElectronicArts.EADesktop"}
    @{Cat="Jogos";           Name="Xbox Game Bar";        ID="Microsoft.XboxGameBar"}
    @{Cat="Jogos";           Name="Razer Synapse";        ID="Razer.Synapse"}
    @{Cat="Jogos";           Name="Logitech G Hub";       ID="Logitech.GHub"}
    @{Cat="Sistema";         Name="PowerToys";            ID="Microsoft.PowerToys"}
    @{Cat="Sistema";         Name="Windows Terminal";     ID="Microsoft.WindowsTerminal"}
    @{Cat="Sistema";         Name="PowerShell 7";         ID="Microsoft.PowerShell"}
    @{Cat="Sistema";         Name="WSL";                  ID="Microsoft.WSL"}
    @{Cat="Sistema";         Name="DriverStore Explorer"; ID="DriverStoreExplorer.RAPR"}
    @{Cat="Sistema";         Name="Autoruns";             ID="Sysinternals.Autoruns"}
    @{Cat="Sistema";         Name="Process Explorer";     ID="Sysinternals.ProcessExplorer"}
    @{Cat="Sistema";         Name="Process Monitor";      ID="Sysinternals.ProcessMonitor"}
    @{Cat="Sistema";         Name="TCPView";              ID="Sysinternals.TCPView"}
    @{Cat="Sistema";         Name="Disk2vhd";             ID="Sysinternals.Disk2vhd"}
    @{Cat="Sistema";         Name="ZoomIt";               ID="Sysinternals.ZoomIt"}
    @{Cat="Sistema";         Name="BGInfo";               ID="Sysinternals.BGInfo"}
    @{Cat="Sistema";         Name="Notepad++";            ID="Notepad++.Notepad++"}
    @{Cat="Sistema";         Name="Notepad--";            ID="Milek7.Notepad--"}
    @{Cat="Sistema";         Name="CLaunch";              ID="CLaunch.CLaunch"}
    @{Cat="Sistema";         Name="Winaero Tweaker";      ID="Winaero.WinaeroTweaker"}
)

function Install-WingetApp {
    param($AppID, $AppName)
    Write-Host "[+] $AppName..." -NoNewline
    $result = winget install --id $AppID --silent --accept-package-agreements --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor $script:c.Green
    } else {
        Write-Host " ERRO" -ForegroundColor $script:c.Red
        Write-Host "    $($result | Select-Object -Last 1)" -ForegroundColor $script:c.DarkGray
    }
}

function Uninstall-WingetApp {
    param($AppID, $AppName)
    Write-Host "[-] $AppName..." -NoNewline
    $result = winget uninstall --id $AppID --silent 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor $script:c.Cyan
    } else {
        Write-Host " ERRO (talvez nao esteja instalado)" -ForegroundColor $script:c.DarkGray
    }
}

function Show-WingetInstaller {
    $busca = ""
    $modo = "I"
    $selecionados = @{}

    do {
        Clear-Host; Show-Banner
        $c = $script:c
        $p = Pad-W 46
        $titulo = if ($modo -eq "I") { "INSTALAR APPS (WINGET)" } else { "DESINSTALAR APPS (WINGET)" }

        $h=[char]0x2550;$v=[char]0x2551;$w=44
        $top = "$p$([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $bot = "$p$([char]0x255A)$("$h"*$w)$([char]0x255D)"
        Write-Host $top -ForegroundColor $c.Cyan
        Write-Host "$p$v  $titulo$(" " * ($w - $titulo.Length - 2))$v" -ForegroundColor $c.Cyan
        Write-Host "$p$v  Busca: $("$busca" + " " * ($w - 10 - $busca.Length))$v" -ForegroundColor $c.DarkGray
        Write-Host $bot -ForegroundColor $c.Cyan
        Write-Host ""

        $lista = if ($busca) { $script:wingetApps | Where-Object { $_.Name -like "*$busca*" -or $_.Cat -like "*$busca*" } } else { $script:wingetApps }
        $grupos = $lista | Group-Object Cat
        $idx = 0

        foreach ($g in $grupos) {
            Write-Host "$p  [$($g.Name)]" -ForegroundColor $c.Magenta
            foreach ($app in $g.Group) {
                $idx++
                $isSelected = $selecionados.ContainsKey($app.ID)
                $check = if ($isSelected) { "[X]" } else { "[ ]" }
                Write-Host "$p  $("{0,2}" -f $idx). $check $($app.Name)" -ForegroundColor $c.White
            }
        }

        if ($idx -eq 0) { Write-Host "$p  (nenhum app encontrado)" -ForegroundColor $c.DarkGray }

        Write-Host ""
        Write-Host "$p  [F] Buscar  [C] Limpar busca  [M] Modo: $(if ($modo -eq 'I') { 'Instalar' } else { 'Desinstalar' })"
        Write-Host "$p  [T] Todos/Nenhum  [A] Aplicar  [0] Voltar"
        Write-Host "$p  Digite o numero do app para marcar/desmarcar"
        $cmd = Read-Host "$p> "

        switch -Wildcard ($cmd) {
            "F" { $busca = Read-Host "Digite o nome do app" }
            "C" { $busca = "" }
            "M" { $modo = if ($modo -eq "I") { "U" } else { "I" }; $selecionados = @{} }
            "T" {
                $uniqueIDs = @{}
                foreach ($app in $lista) { $uniqueIDs[$app.ID] = $true }
                $allSelected = $true
                foreach ($id in $uniqueIDs.Keys) {
                    if (-not $selecionados.ContainsKey($id)) { $allSelected = $false; break }
                }
                if ($allSelected) { $selecionados = @{} }
                else { foreach ($app in $lista) { $selecionados[$app.ID] = $true } }
            }
            "A" {
                if ($selecionados.Count -eq 0) { Write-Host "Nenhum app selecionado." -ForegroundColor $c.Yellow; Start-Sleep 1; continue }
                Write-Host ""; Show-Banner
                Write-Host ">>> $(if ($modo -eq 'I') { 'INSTALANDO' } else { 'DESINSTALANDO' }) <<<" -ForegroundColor $c.Magenta
                Write-Host ""
                foreach ($app in $script:wingetApps) {
                    if ($selecionados.ContainsKey($app.ID)) {
                        if ($modo -eq "I") { Install-WingetApp -AppID $app.ID -AppName $app.Name }
                        else { Uninstall-WingetApp -AppID $app.ID -AppName $app.Name }
                    }
                }
                Write-Host ""; Write-Host "Concluido!" -ForegroundColor $c.Green
                Wait-Key; break
            }
            "0" { return }
            default {
                $parsed = 0
                $num = [int]::TryParse($cmd, [ref]$parsed)
                if ($num -and $parsed -ge 1 -and $parsed -le $lista.Count) {
                    $appAlvo = $lista[$parsed - 1]
                    if ($selecionados.ContainsKey($appAlvo.ID)) { $selecionados.Remove($appAlvo.ID) }
                    else { $selecionados[$appAlvo.ID] = $true }
                } else {
                    Write-Host "Opcao invalida!" -ForegroundColor $c.Red; Start-Sleep 1
                }
            }
        }
    } while ($true)
}

# === FUNCOES OUTROS ===

function Run-BackupSistema {
    Write-Host "`n[+] Backup do Sistema" -ForegroundColor $script:c.Yellow
    Write-Host "  Isso vai ativar a Protecao do Sistema no disco C:" -ForegroundColor $script:c.White
    Write-Host "  e criar um ponto de restauracao." -ForegroundColor $script:c.White
    $conf = Read-Host "  Deseja continuar? (S/N)"
    if ($conf -ne "S" -and $conf -ne "s") { Write-Host "  CANCELADO" -ForegroundColor $script:c.Yellow; return }
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "TL Optimizer Backup" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        Write-Host "[OK] Ponto de restauracao criado" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "[ERRO] Falha ao criar backup" -ForegroundColor $script:c.Red
    }
}

function Run-RestaurarSistema {
    Write-Host "`n[+] Restaurar Sistema - Abrindo..." -ForegroundColor $script:c.Yellow
    try {
        Start-Process rstrui.exe -ErrorAction SilentlyContinue
        Write-Host "[OK] Assistente de Restauracao aberto" -ForegroundColor $script:c.Green
    } catch {
        Write-Host "[ERRO] Falha ao abrir Restaurar Sistema" -ForegroundColor $script:c.Red
    }
}

function Run-EdicoesWindows {
    Write-Host "`n[+] Edicoes do Windows - Informacoes..." -ForegroundColor $script:c.Yellow
    $edition = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "EditionID" -ErrorAction SilentlyContinue).EditionID
    $display = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName" -ErrorAction SilentlyContinue).ProductName
    Write-Host "[OK] Edicao atual: $display ($edition)" -ForegroundColor $script:c.Green
    Write-Host ""
    Write-Host "  Edicoes disponiveis para upgrade:" -ForegroundColor $script:c.White
    Write-Host "  - Home -> Pro: slmgr /ipk VK7JG-NPHTM-C97JM-9MPGT-3V66T" -ForegroundColor $script:c.DarkGray
    Write-Host "  - Pro -> Enterprise: slmgr /ipk NPPR9-FWDCX-D2C8J-H872K-2YT43" -ForegroundColor $script:c.DarkGray
    Write-Host ""
}

function Run-Usuarios {
    Write-Host "`n[+] Gerenciar Usuarios..." -ForegroundColor $script:c.Yellow
    Write-Host ""
    Write-Host "  1. Criar novo usuario" -ForegroundColor $script:c.White
    Write-Host "  2. Listar usuarios" -ForegroundColor $script:c.White
    Write-Host "  3. Adicionar ao grupo Administradores" -ForegroundColor $script:c.White
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha"
    switch ($escolha) {
        "1" {
            $nome = Read-Host "Nome do novo usuario"
            if ($nome) {
                $senha = Read-Host "Senha" -AsSecureString
                New-LocalUser -Name $nome -Password $senha -FullName $nome -ErrorAction SilentlyContinue
                Write-Host "[OK] Usuario '$nome' criado" -ForegroundColor $script:c.Green
            }
        }
        "2" {
            Get-LocalUser | Format-Table Name, Enabled, LastLogon -AutoSize
        }
        "3" {
            $nome = Read-Host "Nome do usuario"
            if ($nome) {
                Add-LocalGroupMember -Group "Administradores" -Member $nome -ErrorAction SilentlyContinue
                Write-Host "[OK] '$nome' adicionado aos Administradores" -ForegroundColor $script:c.Green
            }
        }
    }
}

function Run-CmdCores {
    Write-Host "`n[+] CMD Cores - Configurando..." -ForegroundColor $script:c.Yellow
    try {
        $regPath = "HKCU:\Console"
        $cores = @(
            @{Name="Verde Matrix";       BG=0; FG=7; BG_RGB=0x00000000; FG_RGB=0x0000FF00},
            @{Name="Azul Neon";          BG=0; FG=7; BG_RGB=0x00000000; FG_RGB=0x0000FFFF},
            @{Name="Vermelho Synthwave"; BG=0; FG=7; BG_RGB=0x00000000; FG_RGB=0x00FF0000},
            @{Name="Amarelo Classico";   BG=0; FG=7; BG_RGB=0x00000000; FG_RGB=0x00FFFF00},
            @{Name="Branco Preto";       BG=0; FG=7; BG_RGB=0x00000000; FG_RGB=0x00FFFFFF}
        )
        Write-Host ""
        $i = 0
        foreach ($cor in $cores) { $i++; Write-Host "  $i. $($cor.Name)" -ForegroundColor $script:c.White }
        Write-Host "  0. Padrao" -ForegroundColor $script:c.Red
        Write-Host ""
        $escolha = Read-Host "Escolha a cor"
        if ([int]$escolha -ge 1 -and [int]$escolha -le 5) {
            $sel = $cores[$escolha - 1]
            Set-ItemProperty -Path $regPath -Name "ScreenColors" -Value ($sel.BG * 16 + $sel.FG) -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "ColorTable00" -Value $sel.BG_RGB -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "ColorTable07" -Value $sel.FG_RGB -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Cor do CMD alterada para: $($sel.Name)" -ForegroundColor $script:c.Green
        } elseif ($escolha -eq "0") {
            Remove-ItemProperty -Path $regPath -Name "ScreenColors" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "ColorTable00" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "ColorTable07" -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Cor do CMD restaurada para o padrao" -ForegroundColor $script:c.Green
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar cores do CMD" -ForegroundColor $script:c.Red
    }
}

function Run-WindowsUpdate {
    Write-Host "`n[+] Windows Update - Gerenciando..." -ForegroundColor $script:c.Yellow
    Write-Host ""
    Write-Host "  1. Verificar atualizacoes" -ForegroundColor $script:c.White
    Write-Host "  2. Parar servico" -ForegroundColor $script:c.White
    Write-Host "  3. Iniciar servico" -ForegroundColor $script:c.White
    Write-Host "  4. Configurar Horario Noturno" -ForegroundColor $script:c.White
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha"
    switch ($escolha) {
        "1" {
            Write-Host "[...] Verificando atualizacoes..." -ForegroundColor $script:c.DarkGray
            $session = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $result = $searcher.Search("IsInstalled=0")
            Write-Host "[OK] $($result.Updates.Count) atualizacoes disponiveis" -ForegroundColor $script:c.Green
            if ($result.Updates.Count -gt 0) {
                foreach ($update in $result.Updates) {
                    Write-Host "  - $($update.Title)" -ForegroundColor $script:c.DarkGray
                }
            }
        }
        "2" { Stop-Service -Name wuauserv -Force; Write-Host "[OK] Servico parado" -ForegroundColor $script:c.Green }
        "3" { Start-Service -Name wuauserv; Write-Host "[OK] Servico iniciado" -ForegroundColor $script:c.Green }
        "4" {
            $res = Read-Host "Horario de inicio (0-23)"
            if ($res -match '^\d+$' -and [int]$res -ge 0 -and [int]$res -le 23) {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value ([int]$res) -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Horario configurado: ${res}:00" -ForegroundColor $script:c.Green
            } else {
                Write-Host "Valor invalido! Digite um numero entre 0 e 23." -ForegroundColor $script:c.Red
            }
        }
    }
}

function Run-SomMod {
    Write-Host "`n[+] Som Mod - Configurando..." -ForegroundColor $script:c.Yellow
    try {
        $regPath = "HKCU:\AppEvents\Schemes"
        $sounds = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "  1. Desativar todos os sons" -ForegroundColor $script:c.White
        Write-Host "  2. Restaurar sons padrao" -ForegroundColor $script:c.White
        Write-Host "  3. Modo silencioso (sem Notificacoes)" -ForegroundColor $script:c.White
        Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
        Write-Host ""
        $escolha = Read-Host "Escolha"
        switch ($escolha) {
            "1" {
                foreach ($scheme in $sounds) {
                    $events = Get-ChildItem -Path $scheme.PSPath -ErrorAction SilentlyContinue
                    foreach ($event in $events) {
                        Set-ItemProperty -Path $event.PSPath -Name ".current" -Value "" -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-Host "[OK] Todos os sons desativados" -ForegroundColor $script:c.Green
            }
            "2" {
                try {
                    $apps = Get-ChildItem "HKCU:\AppEvents\Schemes\Apps" -ErrorAction Stop
                    foreach ($app in $apps) {
                        $events = Get-ChildItem $app.PSPath -ErrorAction SilentlyContinue
                        foreach ($event in $events) {
                            $def = Get-ItemProperty $event.PSPath -Name ".default" -ErrorAction SilentlyContinue
                            if ($def -and $def.'.default') {
                                Set-ItemProperty -Path $event.PSPath -Name ".current" -Value $def.'.default' -Force -ErrorAction SilentlyContinue
                            } else {
                                Set-ItemProperty -Path $event.PSPath -Name ".current" -Value "" -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    Set-ItemProperty -Path "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".Default" -Force -ErrorAction SilentlyContinue
                    Write-Host "[OK] Sons padrao restaurados" -ForegroundColor $script:c.Green
                } catch {
                    Write-Host "[ERRO] Nao foi possivel restaurar: $_" -ForegroundColor $script:c.Red
                    Write-Host "  Abrindo painel de som para configuracao manual..." -ForegroundColor $script:c.Yellow
                    Start-Process rundll32.exe -ArgumentList "shell32.dll,Control_RunDLL mmsys.cpl,,2" -ErrorAction SilentlyContinue
                }
            }
            "3" {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Notificacoes sonoras desativadas" -ForegroundColor $script:c.Green
            }
        }
    } catch {
        Write-Host "[ERRO] Falha ao configurar som" -ForegroundColor $script:c.Red
    }
}

# === WINDOWS FEATURES ===
function Show-WindowsFeatures {
    $wid = 50
    $features = @(
        @{Nome = "NetFx3";           Desc = ".NET Framework 3.5 (inclui 2.0)";        Selected = $false; Detalhe = "Necessario para programas antigos que usam .NET 2.0/3.5. VÃ¡rios jogos e softwares corporativos ainda dependem."}
        @{Nome = "Microsoft-Hyper-V"; Desc = "Hyper-V (Virtualizacao)";                Selected = $false; Detalhe = "Plataforma de maquinas virtuais da Microsoft. Permite rodar Linux, Windows Server, etc. dentro do Windows."}
        @{Nome = "Microsoft-Windows-Subsystem-Linux"; Desc = "WSL (Windows Subsystem for Linux)"; Selected = $false; Detalhe = "Roda Linux nativamente no Windows sem VM. Ideal para desenvolvedores que usam terminal Linux."}
        @{Nome = "Containers-DisposableClientVM"; Desc = "Windows Sandbox";             Selected = $false; Detalhe = "Ambiente seguro e descartavel para testar programas suspeitos. Isolado do sistema principal."}
        @{Nome = "ServicesForNFS-ClientOnly"; Desc = "NFS (Network File System)";       Selected = $false; Detalhe = "Permite acessar pastas compartilhadas em servidores Linux/UNIX usando protocolo NFS."}
        @{Nome = "MediaPlayback";     Desc = "Legacy Media (WMP, DirectPlay)";          Selected = $false; Detalhe = "Componentes de midia antigos como Windows Media Player e DirectPlay para compatibilidade com jogos classicos."}
        @{Nome = "NetFx4";           Desc = ".NET Framework 4.8";                       Selected = $false; Detalhe = "Versao mais recente do .NET Framework. Ja vem instalado no Windows 10/11, mas pode ser reparado se corrompido."}
    )
    do {
        Clear-Host; Show-Banner
        $i = 1
        foreach ($feat in $features) {
            $check = if ($feat.Selected) { "[X]" } else { "[ ]" }
            $corItem = if ($feat.Selected) { $script:c.Green } else { $script:c.DarkGray }
            if ($i -eq 1) {
                Show-TopBorder $wid
                Show-BoxLine $wid "  WINDOWS FEATURES - Digite NUMERO para marcar" $script:c.DarkCyan
                Show-MidBorder $wid
            }
            Show-BoxLine $wid ("  {0,2}. {1} {2,-42}" -f $i, $check, $feat.Desc) $corItem
            foreach ($linha in (Wrap-Texto -Texto $feat.Detalhe -Largura 44)) {
                Show-BoxLine $wid ("    {0,-44}" -f $linha) $script:c.DarkGray
            }
            $i++
        }
        Show-SubBorder $wid
        Show-BoxLine $wid "  [A] Aplicar  [T] Marcar todos  [0] Voltar" $script:c.Yellow
        Show-BotBorder $wid
        Write-Host ""
        $choice = Read-Host "Escolha"
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Show-Banner; Write-Host ">>> APLICANDO WINDOWS FEATURES <<<" -ForegroundColor $c.Magenta; Write-Host ""
            foreach ($feat in $features) {
                $nome = $feat.Nome; $selecionado = $feat.Selected
                if ($nome -eq "NetFx4") {
                    Write-Host "[$($feat.Desc)]..." -NoNewline
                    if ($selecionado) {
                        $st = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Install -ErrorAction SilentlyContinue
                        if ($st.Install -eq 1) { Write-Host " JA INSTALADO" -ForegroundColor $c.Yellow }
                        else { Write-Host " NAO DISPONIVEL" -ForegroundColor $c.DarkGray }
                    }
                } else {
                    Write-Host "[$($feat.Desc)]..." -NoNewline
                    $result = if ($selecionado) { Enable-WindowsOptionalFeature -Online -FeatureName $nome -NoRestart -ErrorAction SilentlyContinue }
                               else { Disable-WindowsOptionalFeature -Online -FeatureName $nome -NoRestart -ErrorAction SilentlyContinue }
                    if ($result.RestartNeeded -eq $true) { Write-Host " OK (reinicie)" -ForegroundColor $c.Yellow }
                    elseif ($? -or $result.ReturnCode -eq 0 -or $result.ReturnCode -eq 3010) { Write-Host " OK" -ForegroundColor $c.Green }
                    else { Write-Host " ERRO" -ForegroundColor $c.Red }
                }
            }
            Write-Host ""; Write-Host "Concluido!" -ForegroundColor $c.Green; Wait-Key; return
        }
        if ($choice -eq "T" -or $choice -eq "t") {
            $cnt = ($features | Where-Object { $_.Selected }).Count
            if ($cnt -eq $features.Count) { foreach ($f in $features) { $f.Selected = $false } }
            else { foreach ($f in $features) { $f.Selected = $true } }
            continue
        }
        $num = [int]::TryParse($choice, [ref]$null)
        if ($num -and [int]$choice -ge 1 -and [int]$choice -le $features.Count) {
            $features[[int]$choice - 1].Selected = -not $features[[int]$choice - 1].Selected
        }
    } while ($true)
}

# === POWER PLAN ===
function Set-UltimatePerformance {
    Show-Banner
    $c = $script:c; $p = Pad-W 40
    Write-Host "$p  PLANO DE ENERGIA" -ForegroundColor $c.Cyan; Write-Host ""
    Write-Host "$p  1. Ultimate Performance (maximo desempenho)" -ForegroundColor $c.White
    Write-Host "$p  2. High Performance" -ForegroundColor $c.White
    Write-Host "$p  3. Balanced (padrao)" -ForegroundColor $c.White
    Write-Host "$p  4. Power Saver (economia)" -ForegroundColor $c.White
    Write-Host "$p  0. Voltar" -ForegroundColor $c.Red; Write-Host ""
    $uid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $high = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    $bal = "381b4222-f694-41f0-9685-ff5bb260df2f"
    $save = "a1841308-3541-4fab-bc81-f71556f20b4a"
    switch (Read-Host "Escolha") {
        "1" { powercfg /duplicatescheme $uid 2>$null; powercfg /setactive $uid; Write-Host "[OK] Ultimate Performance ativado" -ForegroundColor $c.Green }
        "2" { powercfg /setactive $high; Write-Host "[OK] High Performance ativado" -ForegroundColor $c.Green }
        "3" { powercfg /setactive $bal; Write-Host "[OK] Balanced ativado" -ForegroundColor $c.Green }
        "4" { powercfg /setactive $save; Write-Host "[OK] Power Saver ativado" -ForegroundColor $c.Green }
    }
    Wait-Key
}

# === UNDO INDIVIDUAL ===
$script:tweakLog = @()
$script:tweakLogFile = "$backupDir\tweak_log.json"

function Log-Tweak {
    param([string]$Categoria, [string]$Acao, [string]$Alvo, [string]$ValorAntigo = "", [string]$ValorNovo = "")
    $entry = @{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Categoria = $Categoria
        Acao = $Acao
        Alvo = $Alvo
        ValorAntigo = $ValorAntigo
        ValorNovo = $ValorNovo
    }
    $script:tweakLog += $entry
}

function Flush-TweakLog {
    if ($script:tweakLog.Count -gt 0) {
        $script:tweakLog | ConvertTo-Json -Depth 3 | Set-Content $script:tweakLogFile -Force
    }
}

function Show-UndoLog {
    do {
        Clear-Host; Show-Banner
        $c = $script:c; $p = Pad-W 50
        $h=[char]0x2550;$v=[char]0x2551;$w=48
        $top = "$p$([char]0x2554)$("$h"*$w)$([char]0x2557)"
        $bot = "$p$([char]0x255A)$("$h"*$w)$([char]0x255D)"
        Write-Host $top -ForegroundColor $c.Cyan
        Write-Host "$p$v  DESFAZER INDIVIDUAL - Historico de tweaks$(" " * 3)$v" -ForegroundColor $c.DarkCyan
        if ($script:tweakLog.Count -eq 0) {
            Write-Host "$p$v  Nenhum tweak registrado nesta sessao.$(" " * 7)$v" -ForegroundColor $c.DarkGray
        } else {
            Write-Host "$p$v$(" " * $w)$v" -ForegroundColor $c.DarkGray
            for ($i = 0; $i -lt $script:tweakLog.Count; $i++) {
                $e = $script:tweakLog[$i]
                $line = "  $("{0,2}" -f ($i+1)). [$($e.Categoria)] $($e.Acao): $($e.Alvo)"
                $trunc = if ($line.Length -gt $w) { $line.Substring(0, $w-3) + "..." } else { $line.PadRight($w) }
                Write-Host "$p$v$trunc$v" -ForegroundColor $c.White
                if ($e.ValorAntigo) {
                    $det = "    Antes: $($e.ValorAntigo)  ->  Depois: $($e.ValorNovo)"
                    $dtrunc = if ($det.Length -gt $w) { $det.Substring(0, $w-3) + "..." } else { $det.PadRight($w) }
                    Write-Host "$p$v$dtrunc$v" -ForegroundColor $c.DarkGray
                }
            }
        }
        Write-Host $bot -ForegroundColor $c.Cyan; Write-Host ""
        Write-Host "$p  Digite NUMERO para reverter, [C] limpar log, [0] Voltar"
        $cmd = Read-Host "$p> "
        if ($cmd -eq "0") { return }
        if ($cmd -eq "C" -or $cmd -eq "c") { $script:tweakLog = @(); Remove-Item $script:tweakLogFile -Force -ErrorAction SilentlyContinue; continue }
        $num = [int]::TryParse($cmd, [ref]$null)
        if ($num -and [int]$cmd -ge 1 -and [int]$cmd -le $script:tweakLog.Count) {
            $entry = $script:tweakLog[[int]$cmd - 1]
            Write-Host "[Revertendo] $($entry.Categoria): $($entry.Acao) em $($entry.Alvo)..." -ForegroundColor $c.Yellow
            Write-Host "  Para reverter totalmente, use as opcoes de Undo no menu principal (Backup/Restore)." -ForegroundColor $c.DarkGray
            Write-Host "  O log serve como rastreamento do que foi alterado." -ForegroundColor $c.DarkGray
            Wait-Key
        }
    } while ($true)
}

# === PRESETS ===
$script:presetFile = "$backupDir\preset.json"

function Export-Preset {
    Show-Banner
    $c = $script:c; $p = Pad-W 40
    Write-Host "$p  EXPORTAR PRESET" -ForegroundColor $c.Cyan; Write-Host ""
    Write-Host "$p  Isso salvara a configuracao atual dos tweaks" -ForegroundColor $c.White
    Write-Host "$p  para aplicar em outra maquina depois." -ForegroundColor $c.White; Write-Host ""
    $preset = @{
        Nome = Read-Host "$p  Nome do preset"
        Data = (Get-Date -Format "yyyy-MM-dd")
        Tema = $script:temaAtual
        Servicos = @()
        Rede = @()
        Visual = @()
        Gaming = @()
    }
    if (Test-Path "$backupDir\servicos_backup.json") {
        $preset.Servicos = Get-Content "$backupDir\servicos_backup.json" | ConvertFrom-Json
    }
    if (Test-Path "$backupDir\rede_backup.json") {
        $preset.Rede = Get-Content "$backupDir\rede_backup.json" | ConvertFrom-Json
    }
    if (Test-Path "$backupDir\visual_backup.json") {
        $preset.Visual = Get-Content "$backupDir\visual_backup.json" | ConvertFrom-Json
    }
    $preset | ConvertTo-Json -Depth 5 | Set-Content $script:presetFile -Force
    Write-Host "[OK] Preset salvo em: $($script:presetFile)" -ForegroundColor $c.Green
    Wait-Key
}

function Import-Preset {
    Show-Banner
    $c = $script:c; $p = Pad-W 40
    if (-not (Test-Path $script:presetFile)) {
        Write-Host "$p  Nenhum preset encontrado em:" -ForegroundColor $c.Yellow
        Write-Host "$p  $($script:presetFile)" -ForegroundColor $c.DarkGray
        Wait-Key; return
    }
    Write-Host "$p  IMPORTAR PRESET" -ForegroundColor $c.Cyan; Write-Host ""
    $preset = Get-Content $script:presetFile -Raw | ConvertFrom-Json
    Write-Host "$p  Nome: $($preset.Nome)" -ForegroundColor $c.White
    Write-Host "$p  Data: $($preset.Data)" -ForegroundColor $c.White
    Write-Host "$p  Tema: $($preset.Tema)" -ForegroundColor $c.White; Write-Host ""
    if ($preset.Tema -and $script:temas.ContainsKey($preset.Tema)) {
        $script:temaAtual = $preset.Tema; $script:c = $script:temas[$preset.Tema].Clone(); SalvarTema
        Write-Host "[OK] Tema restaurado: $($preset.Tema)" -ForegroundColor $c.Green
    }
    if ($preset.Servicos -and $preset.Servicos.Count -gt 0) {
        $preset.Servicos | ConvertTo-Json | Set-Content "$backupDir\servicos_backup.json" -Force
        Write-Host "[OK] Backup de servicos restaurado ($($preset.Servicos.Count) itens)" -ForegroundColor $c.Green
    }
    if ($preset.Rede) {
        $preset.Rede | ConvertTo-Json -Depth 3 | Set-Content "$backupDir\rede_backup.json" -Force
        Write-Host "[OK] Backup de rede restaurado" -ForegroundColor $c.Green
    }
    if ($preset.Visual) {
        $preset.Visual | ConvertTo-Json | Set-Content "$backupDir\visual_backup.json" -Force
        Write-Host "[OK] Backup de visual restaurado" -ForegroundColor $c.Green
    }
    Write-Host ""; Write-Host "Preset aplicado! Execute os tweaks desejados no menu." -ForegroundColor $c.Green
    Wait-Key
}

# === O&O ShutUp10++ INTEGRATION ===
# === PRIVACIDADE (INTERATIVO COM SHOW-GENERICOSUBMENU) ===
function Show-BootSequence {
    Show-Banner -Cor $script:c.Green
    $c = $script:c
    $bw = 57
    $bp = Pad-W $bw
    $credito = "by $DEV_NAME  -  Discord: $DEV_DISCORD"
    Write-Host "$bp$(" " * [Math]::Max(0, [Math]::Floor(($bw - $credito.Length) / 2)))$credito" -ForegroundColor $c.DarkGray
    Write-Host ""
    $checks = @(
        "Inicializando nucleo do sistema",
        "Verificando permissoes de administrador",
        "Carregando modulos de limpeza e otimizacao",
        "Sincronizando parametros de hardware",
        "Compilando interface do otimizador"
    )
    $p = Pad-W 57
    $padItem = " " * 5
    foreach ($chk in $checks) {
        Write-Host "$p$padItem$chk..." -NoNewline -ForegroundColor $c.DarkGray
        Start-Sleep -Milliseconds 800
        Write-Host " [OK]" -ForegroundColor $c.Green
    }
    Write-Host ""
    $full = [char]0x2588; $empty = [char]0x2591
    try { $null = "$full$empty"[0] } catch { $full = '#'; $empty = '-' }
    $barW = 30
    $pBar = Pad-W ($barW + 8)
    $cr = [char]13
    $maxLen = $pBar.Length + 2 + $barW + 2 + 4
    for ($pct = 0; $pct -le 100; $pct += 3) {
        $fill = [Math]::Min(($pct * $barW / 100), $barW)
        $bar = "$full" * [Math]::Floor($fill) + "$empty" * ($barW - [Math]::Floor($fill))
        $line = "$pBar  $bar  $("{0,3}" -f $pct)%"
        Write-Host "$cr$line$(" " * ($maxLen - $line.Length))" -NoNewline -ForegroundColor $c.Green
        Start-Sleep -Milliseconds 15
    }
    Write-Host ""
    Start-Sleep -Milliseconds 300
    Write-Host "$p  Pronto." -ForegroundColor $c.Green
    Start-Sleep -Milliseconds 400
}

function Show-Sobre {
    $p = Pad-W 44
    Write-Host ""
    Write-Host "$p  TL Otimizador v1.4" -ForegroundColor $script:c.Yellow
    Write-Host "$p  Ferramenta de otimizacao do Windows" -ForegroundColor $script:c.White
    Write-Host ""
    Write-Host "$p  Autor: AtdasBR" -ForegroundColor $script:c.Cyan
    Write-Host "$p  GitHub: github.com/AtdasBR/TL-Otimizador" -ForegroundColor $script:c.Cyan
    Write-Host "$p  Distribuicao: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.DarkGray
    Write-Host ""
    Write-Host "$p  Funcionalidades:" -ForegroundColor $script:c.Green
    Write-Host "$p  - Limpeza rapida e profunda" -ForegroundColor $script:c.White
    Write-Host "$p  - Gerenciamento de servicos" -ForegroundColor $script:c.White
    Write-Host "$p  - Otimizacao de rede" -ForegroundColor $script:c.White
    Write-Host "$p  - Acelerar visual" -ForegroundColor $script:c.White
    Write-Host "$p  - Instalador de navegadores e softwares" -ForegroundColor $script:c.White
    Write-Host "$p  - Desinstalador universal" -ForegroundColor $script:c.White
    Write-Host "$p  - Driver Updater" -ForegroundColor $script:c.White
    Write-Host "$p  - Sistema de temas" -ForegroundColor $script:c.White
    Write-Host "$p  - Verificar atualizacao" -ForegroundColor $script:c.White
    Write-Host ""
}

# === SUBMENU: TWEAKS ESSENCIAIS (SLOT 9) ===
# === SUBMENU: REDE AVANCADA (SLOT 37) ===
function Run-RedeAvancada {
    do {
        Clear-Host; Show-Banner
        $p = Pad-W 44
        Write-Host "$p  REDE AVANCADA" -ForegroundColor $script:c.Cyan; Write-Host ""
        Write-Host "$p  1. IPv4 Preferred (priorizar IPv4)" -ForegroundColor $script:c.White
        Write-Host "$p  2. Teredo - Desativar (tunelamento IPv6)" -ForegroundColor $script:c.White
        Write-Host "$p  0. Voltar" -ForegroundColor $script:c.Red; Write-Host ""
        switch (Read-Host "$p> ") {
            "1" {
                Show-Banner; Write-Host "[+] Priorizando IPv4..." -NoNewline -ForegroundColor $script:c.Yellow
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green; Log-Tweak "Rede" "Priorizou" "IPv4"; Wait-Key
            }
            "2" {
                Show-Banner; Write-Host "[+] Desativando Teredo..." -NoNewline -ForegroundColor $script:c.Yellow
                netsh interface teredo set state disabled 2>$null
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor $script:c.Green; Log-Tweak "Rede" "Desativou" "Teredo"; Wait-Key
            }
            "0" { return }
        }
    } while ($true)
}

# === SUBMENU: TWEAKS VISUAIS (SLOT 47) ===
# === WELCOME (modo portatil via iex) ===
if (-not $PSCommandPath) {
    do {
        Show-Welcome
        $modo = Read-Host "Digite P (Portatil) ou I (Instalar)"
        if ($modo -eq "P" -or $modo -eq "p") { break }
        if ($modo -eq "I" -or $modo -eq "i") { Install-Local; break }
    } while ($true)
}

# === AUTO-UPDATE (silencioso) ===
VerificarAtualizacao -Silencioso

# === BOOT SEQUENCE (uma vez por sessao) ===
Show-BootSequence

# === MAIN LOOP ===
do {
    Show-Menu

    $opcao = Read-Host "Escolha uma opcao"

    switch ($opcao) {
        "1" { Show-Banner; Tweak-ActionCenter; Log-Tweak "Tweak" "Desativou" "Central de Acao"; Wait-Key }
        "2" { Show-Banner; Tweak-CacheUpdates; Log-Tweak "Tweak" "Limpou" "Cache Updates"; Wait-Key }
        "3" { Show-Banner; Tweak-Hibernation; Log-Tweak "Tweak" "Desativou" "Hibernacao"; Wait-Key }
        "4" { Show-Banner; Tweak-Pagefile; Log-Tweak "Tweak" "Otimizou" "Pagefile"; Wait-Key }
        "5" { Show-Banner; Tweak-TakeOwnership; Log-Tweak "Tweak" "Adicionou" "Take Ownership"; Wait-Key }
        "6" { Show-Banner; Tweak-Updates2077; Log-Tweak "Tweak" "Pausou" "Updates 2077"; Wait-Key }
        "7" { Show-Banner; Tweak-CompactLZX; Log-Tweak "Tweak" "Aplicou" "Compact/LZX"; Wait-Key }
        "8" { Show-Banner; Tweak-RemoverUWP; Log-Tweak "Tweak" "Removeu" "UWP Apps"; Wait-Key }
        "18" { Show-Banner; New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Ativou" "End Task"; Wait-Key }
        "19" { Show-Banner; New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force -ErrorAction SilentlyContinue | Out-Null; Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Ativou" "Classic Menu"; Wait-Key }
        "24" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Removeu" "Home/Gallery"; Wait-Key }
        "25" { Show-Banner; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWpbtExecution" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Desativou" "WPBT"; Wait-Key }
        "26" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Bloqueou" "Device Companion"; Wait-Key }
        "27" { Show-Banner; New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Desativou" "Notificacoes"; Wait-Key }
        "28" { Show-Banner; New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output ""; Log-Tweak "Tweak" "Desativou" "Storage Sense"; Wait-Key }
        "29" { Show-Banner; Write-Output ""; Write-Output "[!] Isso desliga a virtualizacao de seguranca do Windows."; Write-Output "[!] Pode melhorar performance em jogos, mas REDUZ a seguranca."; $conf = Read-Host "Confirmar desativacao? (S/N)"; if ($conf -eq "S" -or $conf -eq "s") { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "VirtualizationBasedSecurity" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Write-Output "[OK] Isolamento de Nucleo desativado (reinicie o PC)"; Log-Tweak "Tweak" "Desativou" "Core Isolation" } else { Write-Output "[--] Cancelado" }; Wait-Key }
        "10" { Show-Banner; Clear-EventLogs; Log-Tweak "Limpeza" "Limpou" "Event Logs"; Wait-Key }
        "11" { Show-Banner; Clear-CacheWindows; Log-Tweak "Limpeza" "Limpou" "Cache Windows"; Wait-Key }
        "12" { Show-Banner; Clear-DNSCache; Log-Tweak "Limpeza" "Limpou" "DNS Cache"; Wait-Key }
        "13" { Show-Banner; Clear-Temporarios; Log-Tweak "Limpeza" "Limpou" "Temporarios"; Wait-Key }
        "14" { Show-Banner; Run-LimpezaExtrema; Log-Tweak "Limpeza" "Extrema" "Limpeza profunda"; Wait-Key }
        "15" { Show-Banner; Run-CleanMgr; Log-Tweak "Limpeza" "Executou" "CleanMgr"; Wait-Key }
        "16" { Show-Banner; Run-DISM; Log-Tweak "Limpeza" "Executou" "DISM"; Wait-Key }
        "17" { Show-Banner; Clear-FiveMCache; Wait-Key }
        "20" { Show-WingetInstaller }
        "22" { Show-Banner; Run-DriverUpdater }
        "23" { Show-Banner; Run-UniversalUninstaller }
        "30" { Show-Banner; Set-DirectDNS "Google"; Wait-Key }
        "31" { Show-Banner; Set-DirectDNS "Cloudflare"; Wait-Key }
        "32" { Show-Banner; Set-DirectDNS "OpenDNS"; Wait-Key }
        "33" { Show-Banner; Set-DirectDNS "Quad9"; Wait-Key }
        "34" { Show-Banner; Set-DirectDNS "AdGuard"; Wait-Key }
        "35" { Show-Banner; Set-DirectDNS "Default"; Wait-Key }
        "36" { Show-Banner; Run-Rede; Wait-Key }
        "37" { Run-RedeAvancada }
        "40" { Show-WindowsFeatures }
        "41" { Set-UltimatePerformance }
        "42" { Show-Banner; Run-EdicoesWindows; Wait-Key }
        "43" { Show-Banner; Run-WindowsUpdate; Wait-Key }

        "45" { EscolherTema }
        "46" { Show-Banner; Show-Sobre; Wait-Key }
        "48" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Tweak" "Ativou" "Game Mode"; Wait-Key }
        "49" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Tweak" "Desativou" "Game Bar"; Wait-Key }
        "56" { Show-Banner; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Tweak" "Ativou" "GPU Scheduling"; Wait-Key }
        "57" { Show-Banner; $proc = Read-Host "Nome do processo (ex: chrome.exe)"; if ($proc) { $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$proc"; New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty -Path $regPath -Name "Priority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue }; Log-Tweak "Tweak" "Definiu" "Prioridade $proc"; Wait-Key }
        "58" { Show-Banner; powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null; Log-Tweak "Tweak" "Ativou" "High Perf Power"; Wait-Key }
        "59" { Show-Banner; $adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue; foreach ($adapter in $adapters) { Set-ItemProperty -Path $adapter.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $adapter.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }; Log-Tweak "Tweak" "Desativou" "Nagle"; Wait-Key }
        "52" { Undo-Servicos }
        "53" { Undo-Rede }
        "54" { Undo-Visual }
        "55" { Undo-Privacidade }
        "70" { Show-Banner; Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Ativou" "Dark Mode"; Wait-Key }
        "71" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Mostra" "Extensoes"; Wait-Key }
        "72" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Mostra" "Ocultos"; Wait-Key }
        "73" { Show-Banner; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisableEmoticon" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Ativou" "BSoD Verbose"; Wait-Key }
        "74" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IsBatteryPercentageEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Ativou" "Battery %"; Wait-Key }
        "75" { Show-Banner; Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Ativou" "Scrollbars"; Wait-Key }
        "76" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Ativou" "Logon Verbose"; Wait-Key }
        "77" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "PlatformSupportMiracast" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Visual" "Desativou" "MPO"; Wait-Key }
        "80" { Show-Banner; Export-Preset; Wait-Key }
        "81" { Show-Banner; Import-Preset; Wait-Key }
        "84" { Show-Banner; $shutupPath = "$backupDir\OOSU10.exe"; if (-not (Test-Path $shutupPath)) { try { Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $shutupPath -UseBasicParsing -ErrorAction Stop } catch { } }; if (Confirm-Assinatura -FilePath $shutupPath -Origem "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe") { Start-Process $shutupPath -ErrorAction SilentlyContinue }; Wait-Key }
        "85" { Show-Banner; $shutupPath = "$backupDir\OOSU10.exe"; Remove-Item $shutupPath -Force -ErrorAction SilentlyContinue; try { Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $shutupPath -UseBasicParsing -ErrorAction Stop; if (Confirm-Assinatura -FilePath $shutupPath -Origem "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe") { Start-Process $shutupPath -ErrorAction SilentlyContinue } } catch { }; Wait-Key }
        "86" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue; Set-Service -Name dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name dmwappushservice -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Telemetria"; Wait-Key }
        "87" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Cortana"; Wait-Key }
        "88" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Localizacao"; Wait-Key }
        "89" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Bloqueou" "Anuncios"; Wait-Key }
        "90" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "value" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiSense" -Name "value" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Wi-Fi Sense"; Wait-Key }
        "91" { Show-Banner; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Speech\Preferences" -Name "VoiceActivationEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic" -Name "VoiceActivationEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Ativ. Voz"; Wait-Key }
        "92" { Show-Banner; $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"; $telemetryHosts = @("0.0.0.0 vortex-win.data.microsoft.com","0.0.0.0 settings-win.data.microsoft.com","0.0.0.0 telemetry.microsoft.com","0.0.0.0 telemetry.appex.bing.net","0.0.0.0 telemetry.urs.microsoft.com","0.0.0.0 df.telemetry.microsoft.com","0.0.0.0 oca.telemetry.microsoft.com","0.0.0.0 sqm.telemetry.microsoft.com","0.0.0.0 watson.telemetry.microsoft.com","0.0.0.0 vortex-sandbox.data.microsoft.com","0.0.0.0 v10.vortex-win.data.microsoft.com","0.0.0.0 watson.microsoft.com","0.0.0.0 watson.live.com","0.0.0.0 watson.ppe.telemetry.microsoft.com","0.0.0.0 vortex.data.microsoft.com","0.0.0.0 preview.msn.com","0.0.0.0 reports.wes.df.telemetry.microsoft.com","0.0.0.0 services.wes.df.telemetry.microsoft.com"); $content = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue; foreach ($entry in $telemetryHosts) { if ($content -notmatch [regex]::Escape($entry)) { Add-Content -Path $hostsPath -Value $entry -Force -ErrorAction SilentlyContinue } }; Log-Tweak "Privacidade" "Bloqueou" "Hosts Telemetria"; Wait-Key }
        "93" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Windows Update"; Wait-Key }
        "94" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "BlockDomainPicture" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DontDisplayLastUsername" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Removeu" "MS Account"; Wait-Key }
        "95" { Show-Banner; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue; Log-Tweak "Privacidade" "Desativou" "Defender"; Wait-Key }
        "60" { Show-Banner; Run-BackupSistema; Wait-Key }
        "61" { Show-Banner; Run-RestaurarSistema; Wait-Key }
        "62" { Show-Banner; Run-Usuarios; Wait-Key }
        "63" { Show-Banner; Run-CmdCores; Wait-Key }
        "64" { Show-Banner; Run-SomMod; Wait-Key }
        "66" { Show-UndoLog }
        "67" { Show-Banner; Run-Tudo; Wait-Key }
        "?" { Show-Help; Wait-Key }
        "H" { Show-Help; Wait-Key }
        "h" { Show-Help; Wait-Key }
        "U" { Show-Banner; VerificarAtualizacao; Wait-Key }
        "u" { Show-Banner; VerificarAtualizacao; Wait-Key }
        "D" { Show-Banner; Uninstall-TL }
        "d" { Show-Banner; Uninstall-TL }
        "0" { Write-Host "Saindo..." -ForegroundColor $script:c.Green; break }
        default { Write-Host "Opcao invalida! Tente novamente." -ForegroundColor $script:c.Red; Start-Sleep -Seconds 1 }
    }
} while ($opcao -ne "0")

Flush-TweakLog
