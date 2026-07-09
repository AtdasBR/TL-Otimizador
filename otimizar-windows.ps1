$ErrorActionPreference = "Continue"
$backupDir = "$env:LOCALAPPDATA\Otimizador"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$scriptUrl = "https://is.gd/tlotimizador"
$rawUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master/otimizar-windows.ps1"
$script:versao = "1.4"

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
    Write-Host "  $v  ### GUIA RAPIDO ###                             $v" -ForegroundColor $script:c.White
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v  TWEAK (1-8)  - Melhorias de sistema             $v" -ForegroundColor $script:c.Yellow
    Write-Host "  $v   1. Central de Acao - Notificacoes              $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   2. Cache Updates - Limpa downloads            $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   3. Hibernacao - Libera RAM                    $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   4. Pagefile - Otimiza memoria virtual         $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   5. Take Ownership - Menu de contexto          $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   6. Updates 2077 - Pausar atualizacoes         $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   7. Compact/LZX - Comprime o Windows           $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   8. Remover UWP - Apps desnecessarios          $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v  LIMPEZA (10-16) - Liberar espaco              $v" -ForegroundColor $script:c.Red
    Write-Host "  $v   10. Logs de Eventos - Limpa logs antigos     $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   11. Cache Windows - Libera espaco            $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   12. DNS Cache - Reseta cache DNS             $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   13. Temporarios - Limpa arquivos temp        $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   14. Limpeza Extrema - Libera GBs             $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   15. CleanMgr - Ferramenta nativa             $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   16. DISM - Repara o Windows                  $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v  INSTALADOR (20-23) - Instalar/remover        $v" -ForegroundColor $script:c.Green
    Write-Host "  $v   20. Navegadores - Chrome, Firefox, etc       $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   21. Softwares - 7-Zip, VLC, VS Code, etc    $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   22. Drivers - Atualizar drivers              $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   23. Desinstalar - Programas                  $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v  OUTROS (30-40) - Utilidades                  $v" -ForegroundColor $script:c.White
    Write-Host "  $v   30. Backup / 31. Restaurar / 32. WinRE       $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   33. Edicoes / 34. Usuarios / 35. CMD Cores   $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   36. Windows Update / 37. Som / 38. Gaming    $v" -ForegroundColor $script:c.DarkGray
    Write-Host "  $v   39. Tema / 40. Sobre                         $v" -ForegroundColor $script:c.DarkGray
    Write-Host $sep -ForegroundColor $script:c.Cyan
    Write-Host "  $v  [0] Sair                                      $v" -ForegroundColor $script:c.Red
    Write-Host $bot -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "  Como usar: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.Cyan
    Write-Host "  Depois de instalado (tl), e so digitar 'tl'" -ForegroundColor $script:c.DarkGray
    Write-Host "  Backups ficam em: %LOCALAPPDATA%\Otimizador" -ForegroundColor $script:c.DarkGray
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

    $h=[char]0x2500;$v=[char]0x2502;$d=[char]0x25CF
    $a=[char]0x2510;$l=[char]0x2514;$k=[char]0x2518

    $top = "  $([char]0x250C)$("$h"*40)$a"
    $bot = "  $l$("$h"*40)$k"
    $fmt = "     {0,-2}. {1}  {2,-27} "

    Write-Host "  TWEAK" -ForegroundColor $script:c.Yellow
    Write-Host $top -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "1", $d, "Central de Acao") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "2", $d, "Cache Updates") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "3", $d, "Hibernacao") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "4", $d, "Pagefile") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "5", $d, "Take Ownership") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "6", $d, "Updates 2077") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "7", $d, "Compact/LZX") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host ("  $v" + ($fmt -f "8", $d, "Remover UWP") + "$v") -ForegroundColor $script:c.Yellow
    Write-Host $bot -ForegroundColor $script:c.Yellow
    Write-Host ""

    Write-Host "  LIMPEZA" -ForegroundColor $script:c.Red
    Write-Host $top -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "10", $d, "Logs Eventos") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "11", $d, "Cache Windows") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "12", $d, "DNS Cache") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "13", $d, "Temporarios") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "14", $d, "Limpeza Extrema") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "15", $d, "CleanMgr") + "$v") -ForegroundColor $script:c.Red
    Write-Host ("  $v" + ($fmt -f "16", $d, "DISM") + "$v") -ForegroundColor $script:c.Red
    Write-Host $bot -ForegroundColor $script:c.Red
    Write-Host ""

    Write-Host "  INSTALADOR" -ForegroundColor $script:c.Green
    Write-Host $top -ForegroundColor $script:c.Green
    Write-Host ("  $v" + ($fmt -f "20", $d, "Navegadores") + "$v") -ForegroundColor $script:c.Green
    Write-Host ("  $v" + ($fmt -f "21", $d, "Softwares") + "$v") -ForegroundColor $script:c.Green
    Write-Host ("  $v" + ($fmt -f "22", $d, "Atualizar Drivers") + "$v") -ForegroundColor $script:c.Green
    Write-Host ("  $v" + ($fmt -f "23", $d, "Desinstalar") + "$v") -ForegroundColor $script:c.Green
    Write-Host ("  $v" + ($fmt -f "24", $d, "Editor de Imagem") + "$v") -ForegroundColor $script:c.Green
    Write-Host $bot -ForegroundColor $script:c.Green
    Write-Host ""

    Write-Host "  OUTROS" -ForegroundColor $script:c.White
    Write-Host $top -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "30", $d, "Backup Sistema") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "31", $d, "Restaurar Sistema") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "32", $d, "WinRE") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "33", $d, "Edicoes Windows") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "34", $d, "Usuarios") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "35", $d, "CMD Cores") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "36", $d, "Windows Update") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "37", $d, "Som Mod") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "38", $d, "Gaming") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "39", $d, "Tema") + "$v") -ForegroundColor $script:c.White
    Write-Host ("  $v" + ($fmt -f "40", $d, "Sobre") + "$v") -ForegroundColor $script:c.White
    Write-Host $bot -ForegroundColor $script:c.White
    Write-Host ""

    Write-Host "  [0] Sair" -ForegroundColor $script:c.Red
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
        @{Nome = "Microsoft Edge";  Desc = "Microsoft Edge";    URL = "https://go.microsoft.com/fwlink/?linkid=2108834&Channel=Stable&language=en&PC=UC"; Args = "/silent /install"; Detalhe = "Navegador padrao do Windows. Leve e integrado ao sistema. Recomendado para uso basico."}
        @{Nome = "Google Chrome";   Desc = "Google Chrome";     URL = "https://dl.google.com/chrome/install/standalonesetup64.exe"; Args = "/silent /install"; Detalhe = "O navegador mais popular do mundo. Rapido, com muitas extensoes e sincronizacao de conta Google."}
        @{Nome = "Mozilla Firefox"; Desc = "Mozilla Firefox";   URL = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"; Args = "/S"; Detalhe = "Navegador focado em privacidade e codigo aberto. Bloqueador de rastreadores nativo."}
        @{Nome = "Brave";           Desc = "Brave";             URL = "https://laptop-updates.brave.com/latest/winx64"; Args = "/silent /install"; Detalhe = "Navegador com bloqueador de anuncios e rastreadores nativo. Recompensa usuarios com criptomoedas."}
        @{Nome = "Opera";           Desc = "Opera";             URL = "https://net.geo.opera.com/opera/stable/windows"; Args = "/silent /install"; Detalhe = "Navegador com VPN gratuita integrada, bloqueador de anuncios e Messenger na barra lateral."}
        @{Nome = "Opera GX";        Desc = "Opera GX";          URL = "https://net.geo.opera.com/opera_gx/stable/windows"; Args = "/silent /install"; Detalhe = "Navegador para gamers com limitador de CPU/RAM, integracao com Twitch e Discord."}
        @{Nome = "Vivaldi";         Desc = "Vivaldi";           URL = "https://downloads.vivaldi.com/stable/Vivaldi.8.0.4033.57.x64.exe"; Args = "/S"; Detalhe = "Navegador altamente personalizavel. Ideal para quem gosta de configurar cada detalhe."}
        @{Nome = "Tor Browser";     Desc = "Tor Browser";       URL = "https://dist.torproject.org/torbrowser/15.0.17/tor-browser-windows-x86_64-portable-15.0.17.exe"; Args = "/S"; Detalhe = "Navegador focado em anonimato. Roteia o trafego por varios servidores ao redor do mundo."}
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
                Write-Host ">>> INSTALAR $($item.Desc) <<<" -ForegroundColor $script:c.Magenta
                Write-Host ""
                Write-Host "Baixando..." -NoNewline
                $ext = if ($item.URL -match '\.msi$') { 'msi' } else { 'exe' }
                $dest = "$env:TEMP\install_$($item.Nome -replace ' ','').$ext"
                try {
                    Invoke-WebRequest -Uri $item.URL -OutFile $dest -UseBasicParsing -ErrorAction Stop
                    Write-Host " OK" -ForegroundColor $script:c.Green
                    Write-Host "Instalando..." -NoNewline
                    if ($ext -eq "msi") {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`" /quiet /norestart" -Wait -ErrorAction SilentlyContinue
                    } else {
                        Start-Process -FilePath $dest -ArgumentList $item.Args -Wait -ErrorAction SilentlyContinue
                    }
                    Write-Host " OK" -ForegroundColor $script:c.Green
                    Remove-Item $dest -Force -ErrorAction SilentlyContinue
                    Write-Host ""; Write-Host "Instalacao concluida!" -ForegroundColor $script:c.Green
                } catch {
                    Write-Host " ERRO: $($_.Exception.Message)" -ForegroundColor $script:c.Red
                }
                Wait-Key
            }
            "D" {
                Show-Banner
                Write-Host ">>> DESINSTALAR $($item.Desc) <<<" -ForegroundColor $script:c.Magenta
                Write-Host ""
                Write-Host "Procurando no sistema..." -NoNewline
                $chaves = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
                $prog = $null
                foreach ($chave in $chaves) {
                    $prog = Get-ItemProperty $chave -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$($item.Nome)*" } | Select-Object -First 1
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
                    Write-Host "$($item.Desc) nao esta instalado no sistema." -ForegroundColor $script:c.Yellow
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
                Write-Host ""; Write-Host "Desinstalacao concluida!" -ForegroundColor $script:c.Green; Wait-Key
            }
        }
    } while ($true)
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

# === FUNCOES TWEAK ===

function Tweak-ActionCenter {
    Write-Host "`n[+] Central de Acao" -ForegroundColor $script:c.Yellow
    Write-Host "  [A] Ativar" -ForegroundColor $script:c.Green
    Write-Host "  [D] Desativar" -ForegroundColor $script:c.Red
    $opt = Read-Host "Escolha"
    if ($opt -eq "A" -or $opt -eq "a") {
        Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Central de Acao ativada" -ForegroundColor $script:c.Green
    } elseif ($opt -eq "D" -or $opt -eq "d") {
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
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
            } else {
                Set-CimInstance -InputObject $pf -Property @{InitialSize=$init; MaximumSize=$max} -ErrorAction SilentlyContinue | Out-Null
            }
            Write-Host "[OK] Pagefile configurado: ${init}MB / ${max}MB" -ForegroundColor $script:c.Green
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
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdates" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Value 365 -Type DWord -Force -ErrorAction SilentlyContinue
            $regPath2 = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
            New-Item -Path $regPath2 -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $regPath2 -Name "PausedQualityDate" -Value "2077-12-31" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath2 -Name "PausedFeatureDate" -Value "2077-12-31" -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Updates pausados ate 2077" -ForegroundColor $script:c.Green
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
    $opt = Read-Host "Confirma? (S/N)"
    if ($opt -eq "S" -or $opt -eq "s") {
        foreach ($app in $apps) {
            $found = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            if ($found) {
                Remove-AppxPackage -Package $found.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                Write-Host "[OK] Removido: $app" -ForegroundColor $script:c.Green
            }
        }
    } else {
        Write-Host "[--] Operacao cancelada" -ForegroundColor $script:c.DarkGray
    }
}

# === FUNCOES LIMPEZA ===

function Clear-EventLogs {
    Write-Host "`n[+] Logs de Eventos - Limpando..." -ForegroundColor $script:c.Red
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
    $paths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
        "$env:LOCALAPPDATA\Temp",
        "$env:SystemRoot\Temp"
    )
    $freed = 0
    foreach ($path in $paths) {
        $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                $freed += $item.Length
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $mb = [math]::Round($freed / 1MB, 2)
    Write-Host "[OK] Cache limpo: ${mb}MB liberados" -ForegroundColor $script:c.Green
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
    $paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:SystemRoot\Temp\*",
        "$env:SystemRoot\Prefetch\*"
    )
    $freed = 0
    foreach ($path in $paths) {
        $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                $freed += $item.Length
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    $mb = [math]::Round($freed / 1MB, 2)
    Write-Host "[OK] Temporarios limpos: ${mb}MB liberados" -ForegroundColor $script:c.Green
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

# === FUNCOES INSTALADOR ===

function Show-BrowserInstaller {
    Show-Banner
    Write-Host "  INSTALADOR DE NAVEGADORES" -ForegroundColor $script:c.Green
    Write-Host ""
    Write-Host "  1. Google Chrome" -ForegroundColor $script:c.White
    Write-Host "  2. Mozilla Firefox" -ForegroundColor $script:c.White
    Write-Host "  3. Microsoft Edge" -ForegroundColor $script:c.White
    Write-Host "  4. Brave" -ForegroundColor $script:c.White
    Write-Host "  5. Vivaldi" -ForegroundColor $script:c.White
    Write-Host "  6. Opera" -ForegroundColor $script:c.White
    Write-Host "  7. Opera GX" -ForegroundColor $script:c.White
    Write-Host "  8. Tor Browser" -ForegroundColor $script:c.White
    Write-Host "  9. Instalar todos" -ForegroundColor $script:c.Yellow
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha o navegador"
    $browsers = @(
        @{Name="Google Chrome"; Url="https://dl.google.com/chrome/install/latest/chrome_installer.exe"; Args="/silent /install"},
        @{Name="Mozilla Firefox"; Url="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=pt-BR"; Args="/S"},
        @{Name="Microsoft Edge"; Url="https://go.microsoft.com/fwlink/?linkid=2108834&Channel=Stable&language=en&PC=UC"; Args="/silent /install"},
        @{Name="Brave"; Url="https://laptop-updates.brave.com/latest/standalone"; Args="/silent /install"},
        @{Name="Vivaldi"; Url="https://downloads.vivaldi.net/stable/Vivaldi.8.0.4033.57.x64.exe"; Args="/S"},
        @{Name="Opera"; Url="https://net.geo.opera.com/opera/stable/windows"; Args="/silent /install"},
        @{Name="Opera GX"; Url="https://net.geo.opera.com/gx/stable/windows"; Args="/silent /install"},
        @{Name="Tor Browser"; Url="https://dist.torproject.org/torbrowser/15.0.17/tor-browser-windows-x86_64-portable-15.0.17.exe"; Args="/S"}
    )
    if ($escolha -eq "0") { return }
    if ($escolha -eq "9") {
        foreach ($b in $browsers) { Install-Browser $b }
    } elseif ($escolha -ge 1 -and $escolha -le 8) {
        Install-Browser $browsers[$escolha - 1]
    } else {
        Write-Host "Opcao invalida!" -ForegroundColor $script:c.Red
    }
    Wait-Key
}

function Install-Browser {
    param($b)
    Write-Host "`n[+] $($b.Name) - Baixando..." -ForegroundColor $script:c.Green
    $tempFile = Join-Path $env:TEMP "browser_install.exe"
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($b.Url, $tempFile)
        Write-Host "[OK] Download concluido. Instalando..." -ForegroundColor $script:c.Green
        $argList = "$($b.Args)"
        Start-Process $tempFile -ArgumentList $argList -Wait -ErrorAction SilentlyContinue
        Write-Host "[OK] $($b.Name) instalado com sucesso" -ForegroundColor $script:c.Green
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[ERRO] Falha ao instalar $($b.Name): $_" -ForegroundColor $script:c.Red
    }
}

function Show-SoftwareInstaller {
    Show-Banner
    Write-Host "  INSTALADOR DE SOFTWARES" -ForegroundColor $script:c.Green
    Write-Host ""
    Write-Host "  1. 7-Zip" -ForegroundColor $script:c.White
    Write-Host "  2. VLC Media Player" -ForegroundColor $script:c.White
    Write-Host "  3. Notepad++" -ForegroundColor $script:c.White
    Write-Host "  4. Git" -ForegroundColor $script:c.White
    Write-Host "  5. Python" -ForegroundColor $script:c.White
    Write-Host "  6. Node.js LTS" -ForegroundColor $script:c.White
    Write-Host "  7. Visual Studio Code" -ForegroundColor $script:c.White
    Write-Host "  8. Discord" -ForegroundColor $script:c.White
    Write-Host "  9. Steam" -ForegroundColor $script:c.White
    Write-Host " 10. WhatsApp Desktop" -ForegroundColor $script:c.White
    Write-Host " 11. Telegram Desktop" -ForegroundColor $script:c.White
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha o software"
    $softwares = @(
        @{Name="7-Zip"; Url="https://www.7-zip.org/a/7z2409-x64.exe"; Args="/S"},
        @{Name="VLC"; Url="https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe"; Args="/S /L=1046"},
        @{Name="Notepad++"; Url="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.1/npp.8.7.1.Installer.x64.exe"; Args="/S"},
        @{Name="Git"; Url="https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"; Args="/VERYSILENT /NORESTART"},
        @{Name="Python"; Url="https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"; Args="/quiet InstallAllUsers=1 PrependPath=1"},
        @{Name="Node.js"; Url="https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi"; Args="/quiet INSTALLDIR=`"C:\Program Files\nodejs`""},
        @{Name="VS Code"; Url="https://update.code.visualstudio.com/latest/win32-x64-user/stable"; Args="/silent /install"},
        @{Name="Discord"; Url="https://dl.discordapp.net/apps/win/DiscordSetup.exe"; Args="/silent"},
        @{Name="Steam"; Url="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"; Args="/S"},
        @{Name="WhatsApp"; Url="https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe"; Args="/silent"},
        @{Name="Telegram"; Url="https://tdesktop.com/tdesktop/tdesktop.5.8.3.x64.exe"; Args="/S"}
    )
    if ($escolha -eq "0") { return }
    if ($escolha -ge 1 -and $escolha -le 11) {
        $sw = $softwares[$escolha - 1]
        Write-Host "`n[+] $($sw.Name) - Baixando..." -ForegroundColor $script:c.Green
        $tempFile = Join-Path $env:TEMP "software_install.exe"
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($sw.Url, $tempFile)
            Write-Host "[OK] Download concluido. Instalando..." -ForegroundColor $script:c.Green
            Start-Process $tempFile -ArgumentList $sw.Args -Wait -ErrorAction SilentlyContinue
            Write-Host "[OK] $($sw.Name) instalado com sucesso" -ForegroundColor $script:c.Green
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "[ERRO] Falha ao instalar $($sw.Name): $_" -ForegroundColor $script:c.Red
        }
    } else {
        Write-Host "Opcao invalida!" -ForegroundColor $script:c.Red
    }
    Wait-Key
}

function Show-ImageEditorInstaller {
    Show-Banner
    Write-Host "  EDITOR DE IMAGEM" -ForegroundColor $script:c.Green
    Write-Host ""
    Write-Host "  1. GIMP" -ForegroundColor $script:c.White
    Write-Host "  2. Microsoft Paint" -ForegroundColor $script:c.White
    Write-Host "  3. Paint.NET" -ForegroundColor $script:c.White
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha o editor"
    $editores = @(
        @{Name="GIMP"; Url="https://download.gimp.org/gimp/v3.0/windows/gimp-3.0.2-setup-3.exe"; Args="/VERYSILENT /NORESTART /ALLUSERS"},
        @{Name="Microsoft Paint"; Url="https://codeload.github.com/microsoft/PowerToys/zip/refs/heads/main"; Args=""},
        @{Name="Paint.NET"; Url="https://www.dotpdn.com/files/paint.net.5.1.4.install.x64.zip"; Args=""}
    )
    if ($escolha -eq "0") { return }
    if ($escolha -ge 1 -and $escolha -le 3) {
        $ed = $editores[$escolha - 1]
        Write-Host "`n[+] $($ed.Name) - Baixando..." -ForegroundColor $script:c.Green
        $tempFile = Join-Path $env:TEMP "editor_install.exe"
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($ed.Url, $tempFile)
            Write-Host "[OK] Download concluido. Instalando..." -ForegroundColor $script:c.Green
            if ($ed.Args) {
                Start-Process $tempFile -ArgumentList $ed.Args -Wait -ErrorAction SilentlyContinue
            } else {
                Start-Process $tempFile -Wait -ErrorAction SilentlyContinue
            }
            Write-Host "[OK] $($ed.Name) instalado com sucesso" -ForegroundColor $script:c.Green
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "[ERRO] Falha ao instalar $($ed.Name): $_" -ForegroundColor $script:c.Red
        }
    } else {
        Write-Host "Opcao invalida!" -ForegroundColor $script:c.Red
    }
    Wait-Key
}

# === FUNCOES OUTROS ===

function Run-BackupSistema {
    Write-Host "`n[+] Backup do Sistema - Criando ponto..." -ForegroundColor $script:c.Yellow
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

function Run-WinRE {
    Write-Host "`n[+] WinRE - Gerenciando..." -ForegroundColor $script:c.Yellow
    $status = reagentc /info 2>&1
    if ($status -match "Enabled") {
        Write-Host "[OK] WinRE esta ATIVADO" -ForegroundColor $script:c.Green
    } else {
        Write-Host "[--] WinRE esta DESATIVADO" -ForegroundColor $script:c.DarkGray
    }
    $res = Read-Host "Ativar/Desativar WinRE? (A/D/N)"
    if ($res -eq "A" -or $res -eq "a") {
        reagentc /enable 2>$null
        Write-Host "[OK] WinRE ativado" -ForegroundColor $script:c.Green
    } elseif ($res -eq "D" -or $res -eq "d") {
        reagentc /disable 2>$null
        Write-Host "[OK] WinRE desativado" -ForegroundColor $script:c.Green
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
        if ($escolha -ge 1 -and $escolha -le 5) {
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
            if ($res -match '^\d+$') {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value ([int]$res) -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Horario configurado: ${res}:00" -ForegroundColor $script:c.Green
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
                Set-ItemProperty -Path "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".Default" -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Sons padrao restaurados" -ForegroundColor $script:c.Green
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

function Show-Gaming {
    Show-Banner
    Write-Host "  GAMING" -ForegroundColor $script:c.Cyan
    Write-Host ""
    Write-Host "  1. Game Mode - Ativar" -ForegroundColor $script:c.White
    Write-Host "  2. Game Bar - Desativar" -ForegroundColor $script:c.White
    Write-Host "  3. GPU Scheduling - Ativar" -ForegroundColor $script:c.White
    Write-Host "  4. Prioridade Processo - Alta" -ForegroundColor $script:c.White
    Write-Host "  5. Power Plan - High Performance" -ForegroundColor $script:c.White
    Write-Host "  6. Desativar Nagle Algorithm" -ForegroundColor $script:c.White
    Write-Host "  0. Voltar" -ForegroundColor $script:c.Red
    Write-Host ""
    $escolha = Read-Host "Escolha"
    switch ($escolha) {
        "1" {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Game Mode ativado" -ForegroundColor $script:c.Green
        }
        "2" {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Game Bar desativado" -ForegroundColor $script:c.Green
        }
        "3" {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] GPU Scheduling ativado (reinicie)" -ForegroundColor $script:c.Green
        }
        "4" {
            $proc = Read-Host "Nome do processo (ex: chrome.exe)"
            if ($proc) {
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$proc"
                New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path $regPath -Name "Priority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Prioridade alta definida para $proc" -ForegroundColor $script:c.Green
            }
        }
        "5" {
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Host "[OK] Power Plan: High Performance" -ForegroundColor $script:c.Green
        }
        "6" {
            $adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
            foreach ($adapter in $adapters) {
                Set-ItemProperty -Path $adapter.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $adapter.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
            Write-Host "[OK] Nagle Algorithm desativado" -ForegroundColor $script:c.Green
        }
    }
    Wait-Key
}

function Show-Sobre {
    Write-Host ""
    Write-Host "  TL Otimizador v1.4" -ForegroundColor $script:c.Yellow
    Write-Host "  Ferramenta de otimizacao do Windows" -ForegroundColor $script:c.White
    Write-Host ""
    Write-Host "  Autor: AtdasBR" -ForegroundColor $script:c.Cyan
    Write-Host "  GitHub: github.com/AtdasBR/TL-Otimizador" -ForegroundColor $script:c.Cyan
    Write-Host "  Distribuicao: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor $script:c.DarkGray
    Write-Host ""
    Write-Host "  Funcionalidades:" -ForegroundColor $script:c.Green
    Write-Host "  - Limpeza rapida e profunda" -ForegroundColor $script:c.White
    Write-Host "  - Gerenciamento de servicos" -ForegroundColor $script:c.White
    Write-Host "  - Otimizacao de rede" -ForegroundColor $script:c.White
    Write-Host "  - Acelerar visual" -ForegroundColor $script:c.White
    Write-Host "  - Instalador de navegadores e softwares" -ForegroundColor $script:c.White
    Write-Host "  - Desinstalador universal" -ForegroundColor $script:c.White
    Write-Host "  - Driver Updater" -ForegroundColor $script:c.White
    Write-Host "  - Sistema de temas" -ForegroundColor $script:c.White
    Write-Host "  - Auto-atualizacao" -ForegroundColor $script:c.White
    Write-Host ""
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

    $opcao = Read-Host "Escolha uma opcao"

    switch ($opcao) {
        "1" { Show-Banner; Tweak-ActionCenter; Wait-Key }
        "2" { Show-Banner; Tweak-CacheUpdates; Wait-Key }
        "3" { Show-Banner; Tweak-Hibernation; Wait-Key }
        "4" { Show-Banner; Tweak-Pagefile; Wait-Key }
        "5" { Show-Banner; Tweak-TakeOwnership; Wait-Key }
        "6" { Show-Banner; Tweak-Updates2077; Wait-Key }
        "7" { Show-Banner; Tweak-CompactLZX; Wait-Key }
        "8" { Show-Banner; Tweak-RemoverUWP; Wait-Key }
        "10" { Show-Banner; Clear-EventLogs; Wait-Key }
        "11" { Show-Banner; Clear-CacheWindows; Wait-Key }
        "12" { Show-Banner; Clear-DNSCache; Wait-Key }
        "13" { Show-Banner; Clear-Temporarios; Wait-Key }
        "14" { Show-Banner; Run-LimpezaExtrema; Wait-Key }
        "15" { Show-Banner; Run-CleanMgr; Wait-Key }
        "16" { Show-Banner; Run-DISM; Wait-Key }
        "20" { Show-BrowserInstaller }
        "21" { Show-SoftwareInstaller }
        "22" { Show-Banner; Run-DriverUpdater }
        "23" { Show-Banner; Run-UniversalUninstaller }
        "24" { Show-ImageEditorInstaller }
        "30" { Show-Banner; Run-BackupSistema; Wait-Key }
        "31" { Show-Banner; Run-RestaurarSistema; Wait-Key }
        "32" { Show-Banner; Run-WinRE; Wait-Key }
        "33" { Show-Banner; Run-EdicoesWindows; Wait-Key }
        "34" { Show-Banner; Run-Usuarios; Wait-Key }
        "35" { Show-Banner; Run-CmdCores; Wait-Key }
        "36" { Show-Banner; Run-WindowsUpdate; Wait-Key }
        "37" { Show-Banner; Run-SomMod; Wait-Key }
        "38" { Show-Gaming }
        "39" { EscolherTema }
        "40" { Show-Banner; Show-Sobre; Wait-Key }
        "0" { Write-Host "Saindo..." -ForegroundColor $script:c.Green; break }
        default { Write-Host "Opcao invalida! Tente novamente." -ForegroundColor $script:c.Red; Start-Sleep -Seconds 1 }
    }
} while ($opcao -ne "0")
