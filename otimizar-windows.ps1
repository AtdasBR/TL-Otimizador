$ErrorActionPreference = "SilentlyContinue"
$backupDir = "$env:LOCALAPPDATA\Otimizador"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$scriptUrl = "https://is.gd/tlotimizador"

function Show-Banner {
    Clear-Host
    $t=[char]0x2554;$r=[char]0x2557;$b=[char]0x255A;$e=[char]0x255D;$h=[char]0x2550;$v=[char]0x2551
    $ln = "  $t$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    Write-Host $ln -ForegroundColor Cyan
    Write-Host "  $v            TL OPTIMIZER                $v" -ForegroundColor Cyan
    Write-Host "  $v     Otimizador de Windows v1.0        $v" -ForegroundColor DarkCyan
    Write-Host ($ln -replace $t,$b -replace $r,$e) -ForegroundColor Cyan
    Write-Host ""
}
function Show-Help {
    Clear-Host
    $c=[char]0x250C;$h=[char]0x2500;$v=[char]0x2502;$b=[char]0x2514;$r=[char]0x2510;$e=[char]0x2518
    $top = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    $mid = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$r"
    $bot = "  $b$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$e"

    Write-Host $top -ForegroundColor Cyan
    Write-Host "  $v  1. LIMPEZA SIMPLES                              $v" -ForegroundColor Green
    Write-Host "  $v  Remove arquivos temporarios, cache do sistema,   $v" -ForegroundColor DarkGray
    Write-Host "  $v  lixeira e flush de DNS. Leve e rapido.           $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  2. LIMPEZA EXTREMA (SEGURA)                      $v" -ForegroundColor Magenta
    Write-Host "  $v  Limpeza profunda: prefetch, winsxs, cache de     $v" -ForegroundColor DarkGray
    Write-Host "  $v  browsers, logs Windows, ServicePack, DISM.       $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  3. DESATIVAR SERVICOS                            $v" -ForegroundColor Green
    Write-Host "  $v  Submenu com checkboxes. Digite o numero para     $v" -ForegroundColor DarkGray
    Write-Host "  $v  alternar ON/OFF. [A]plica, [T] marca todos,      $v" -ForegroundColor DarkGray
    Write-Host "  $v  [V]olta. Itens marcados = DESATIVA,              $v" -ForegroundColor DarkGray
    Write-Host "  $v  desmarcados = REATIVA (Automatic + Start).       $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  4. OTIMIZAR REDE                                 $v" -ForegroundColor Green
    Write-Host "  $v  Libera/renova IP, Winsock reset, DNS Cloudflare  $v" -ForegroundColor DarkGray
    Write-Host "  $v  (1.1.1.1), auto-tuning TCP. Itens desmarcados    $v" -ForegroundColor DarkGray
    Write-Host "  $v  sao revertidos via backup salvo automaticamente. $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  5. AJUSTES VISUAIS                               $v" -ForegroundColor Green
    Write-Host "  $v  Modo desempenho, desativar transparencia,        $v" -ForegroundColor DarkGray
    Write-Host "  $v  animacoes, sombras/efeitos. Desmarcados sao      $v" -ForegroundColor DarkGray
    Write-Host "  $v  revertidos ao valor original (via backup).       $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  6. EXECUTAR TUDO                                 $v" -ForegroundColor Magenta
    Write-Host "  $v  Roda servicos, rede e visual com TUDO marcado,   $v" -ForegroundColor DarkGray
    Write-Host "  $v  sem interacao. Backups salvos automaticamente.   $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  7. CRIAR PONTO RESTAURACAO                       $v" -ForegroundColor Yellow
    Write-Host "  $v  Cria ponto de restauracao do Windows antes de    $v" -ForegroundColor DarkGray
    Write-Host "  $v  qualquer alteracao. Exige Protecao do Sistema.   $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  8/9/10. DESFAZER (Servicos/Rede/Visual)          $v" -ForegroundColor Cyan
    Write-Host "  $v  Restaura cada categoria a partir do ultimo       $v" -ForegroundColor DarkGray
    Write-Host "  $v  backup salvo automaticamente antes da alteracao. $v" -ForegroundColor DarkGray
    Write-Host $mid -ForegroundColor Cyan
    Write-Host "  $v  11. AJUDA                                        $v" -ForegroundColor Yellow
    Write-Host "  $v  Esta tela.                                       $v" -ForegroundColor DarkGray
    Write-Host $bot -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  USO: iwr -useb https://is.gd/tlotimizador | iex" -ForegroundColor Cyan
    Write-Host "  Quando instalado (tl), reexecuta como admin automaticamente." -ForegroundColor DarkGray
    Write-Host "  Todos os backups ficam em: %LOCALAPPDATA%\Otimizador" -ForegroundColor DarkGray
}

function Show-Menu {
    Show-Banner
    $t=[char]0x250C;$h=[char]0x2500;$v=[char]0x2502;$b=[char]0x2514
    $r=[char]0x2510;$e=[char]0x2518;$d=[char]0x25CF;$s=[char]0x25C9
    $c=[char]0x250C;$a=[char]0x2510;$l=[char]0x2514;$k=[char]0x2518

    $top = "  $t$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$a"
    $mid = "  $c$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$k"
    $bot = "  $l$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$h$k"
    $fmt = "     {0,-2}. {1}  {2,-27} "

    Write-Host $top -ForegroundColor DarkCyan
    Write-Host ("  $v" + ($fmt -f "1", $d, "Limpeza Simples") + "$v") -ForegroundColor Green
    Write-Host ("  $v" + ($fmt -f "2", $s, "Limpeza Extrema (Segura)") + "$v") -ForegroundColor Magenta
    Write-Host $mid -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor DarkCyan
    Write-Host ("  $v" + ($fmt -f "3", $d, "Desativar Servicos") + "$v") -ForegroundColor Green
    Write-Host ("  $v" + ($fmt -f "4", $d, "Otimizar Rede") + "$v") -ForegroundColor Green
    Write-Host ("  $v" + ($fmt -f "5", $d, "Ajustes Visuais") + "$v") -ForegroundColor Green
    Write-Host ("  $v" + ($fmt -f "6", $s, "EXECUTAR TUDO") + "$v") -ForegroundColor Magenta
    Write-Host $mid -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor DarkCyan
    Write-Host ("  $v" + ($fmt -f "7", $d, "Criar Ponto Restauracao") + "$v") -ForegroundColor Yellow
    Write-Host $mid -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor DarkCyan
    Write-Host ("  $v" + ($fmt -f "8", $d, "Desfazer - Servicos") + "$v") -ForegroundColor Cyan
    Write-Host ("  $v" + ($fmt -f "9", $d, "Desfazer - Rede") + "$v") -ForegroundColor Cyan
    Write-Host ("  $v" + ($fmt -f "10", $d, "Desfazer - Visual") + "$v") -ForegroundColor Cyan
    Write-Host $mid -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor DarkCyan
    Write-Host ("  $v" + ($fmt -f "11", $d, "Ajuda (explicacoes)") + "$v") -ForegroundColor Yellow
    Write-Host $mid -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host $top -ForegroundColor DarkCyan
    Write-Host "  $v             [0]  X  Sair                  $v" -ForegroundColor Red
    Write-Host $bot -ForegroundColor DarkCyan
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
    Write-Host "Backup dos servicos salvo." -ForegroundColor Gray
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
    Write-Host "Backup da rede salvo." -ForegroundColor Gray
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
    Write-Host "Backup do visual salvo." -ForegroundColor Gray
}

function New-PontoRestauracao {
    Show-Banner
    Write-Host ">>> PONTO DE RESTAURACAO <<<" -ForegroundColor Magenta
    Write-Host ""
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "ERRO: Precisa ser ADMINISTRADOR!" -ForegroundColor Red
        Wait-Key; return
    }
    $desc = Read-Host "Descricao do ponto (ex: Antes da otimizacao)"
    if (-not $desc) { $desc = "Antes da otimizacao" }
    try {
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "Ponto de restauracao '$desc' criado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao criar ponto de restauracao." -ForegroundColor Red
        Write-Host "Ative a Protecao do Sistema: Painel de Controle > Sistema > Protecao do Sistema" -ForegroundColor Yellow
    }
    Wait-Key
}

function Run-Limpeza {
    Write-Host ">>> LIMPEZA DE DISCO <<<" -ForegroundColor Magenta
    Write-Host "NOTA: Limpeza nao pode ser desfeita. Os arquivos serao excluidos permanentemente." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[1/5] Limpando arquivos temporarios..." -NoNewline
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[2/5] Limpando cache do sistema..." -NoNewline
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[3/5] Executando Cleanmgr..." -NoNewline
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[4/5] Esvaziando lixeira..." -NoNewline
    (New-Object -ComObject Shell.Application).Namespace(0xa).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[5/5] Limpando cache DNS..." -NoNewline
    ipconfig /flushdns | Out-Null
    Write-Host " OK" -ForegroundColor Green

    Write-Host ""; Write-Host "Limpeza concluida!" -ForegroundColor Green
}

function Show-ServicosSubmenu {
    param([array]$Servicos, [string]$Titulo)

    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=54
        $top = "  $([char]0x2554)$($h*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$($h*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$($h*$w)$([char]0x255D)"
        $sub = "  $([char]0x255F)$($h*$w)$([char]0x2562)"

        $i = 1
        foreach ($s in $Servicos) {
            $check = if ($s.Selected) { "[X]" } else { "[ ]" }
            $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
            $status = if ($svc) { "$($svc.Status)" } else { "AUSENTE" }
            $cor = if ($s.Selected) { "Green" } else { "DarkGray" }
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor Cyan
                Write-Host "  $v  Digite o numero para alternar ON/OFF               $v" -ForegroundColor DarkCyan
                Write-Host $sep -ForegroundColor Cyan
            }
            Write-Host "  $v  $("{0,2}" -f $i). $check $("{0,-30}" -f $s.Desc) $("{0,-12}" -f $status) $v" -ForegroundColor $cor
            $i++
        }

        Write-Host $sub -ForegroundColor Cyan
        Write-Host "  $v  [A] Aplicar     [T] Marcar todos     [V] Voltar     $v" -ForegroundColor Yellow
        Write-Host $bot -ForegroundColor Cyan
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
        @{Nome = "XblAuthManager"; Desc = "Autenticacao Xbox"; Selected = $true},
        @{Nome = "XblGameSave"; Desc = "Save game Xbox"; Selected = $true},
        @{Nome = "XboxNetApiSvc"; Desc = "Rede Xbox"; Selected = $true},
        @{Nome = "XboxGipSvc"; Desc = "Perifericos Xbox"; Selected = $true},
        @{Nome = "DiagTrack"; Desc = "Tracking de diagnosticos"; Selected = $true},
        @{Nome = "dmwappushservice"; Desc = "Roteamento WAP"; Selected = $true},
        @{Nome = "WSearch"; Desc = "Windows Search (indexacao)"; Selected = $true},
        @{Nome = "SysMain"; Desc = "SysMain (Superfetch)"; Selected = $true},
        @{Nome = "TabletInputService"; Desc = "Entrada Tablet"; Selected = $true},
        @{Nome = "RemoteRegistry"; Desc = "Registro Remoto"; Selected = $true},
        @{Nome = "RemoteDesktopServices"; Desc = "Area de Trabalho Remota"; Selected = $true},
        @{Nome = "TermService"; Desc = "Servico Terminal"; Selected = $true},
        @{Nome = "lfsvc"; Desc = "Servico Geolocalizacao"; Selected = $true},
        @{Nome = "MapsBroker"; Desc = "Download Mapas"; Selected = $true},
        @{Nome = "WbioSrvc"; Desc = "Biometria"; Selected = $true}
    )

    if ($SkipMenu) { $selecionados = $servicos }
    else { $selecionados = Show-ServicosSubmenu -Servicos $servicos -Titulo "DESATIVAR SERVICOS" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> ATIVANDO/DESATIVANDO SERVICOS <<<" -ForegroundColor Magenta
    Write-Host ""; Backup-Servicos

    $paraDesativar = $selecionados | Where-Object { $_.Selected }
    $paraAtivar = $selecionados | Where-Object { -not $_.Selected }

    foreach ($s in $paraDesativar) {
        Write-Host "DESATIVAR  [$($s.Desc)] ($($s.Nome))..." -NoNewline
        $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name $s.Nome -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s.Nome -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " DESATIVADO" -ForegroundColor Green
        } elseif ($svc) {
            Set-Service -Name $s.Nome -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " JA DESATIVADO" -ForegroundColor Yellow
        } else {
            Write-Host " NAO ENCONTRADO" -ForegroundColor Gray
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
            Write-Host " ATIVADO" -ForegroundColor Cyan
        } else {
            Write-Host " NAO ENCONTRADO" -ForegroundColor Gray
        }
    }

    Write-Host ""; Write-Host "Servicos ajustados! Use [8] no menu para desfazer." -ForegroundColor Green
}

function Run-Rede {
    param([switch]$SkipMenu)
    $itens = @(
        @{Nome = "LiberarRenovarIP"; Desc = "Liberar e renovar IP"; Selected = $true}
        @{Nome = "ResetWinsock"; Desc = "Resetar Winsock e TCP/IP"; Selected = $true}
        @{Nome = "DNSCloudflare"; Desc = "DNS Cloudflare (1.1.1.1)"; Selected = $true}
        @{Nome = "AutoTuning"; Desc = "Ajustar auto-tuning TCP"; Selected = $true}
    )

    if ($SkipMenu) { $selecionados = $itens }
    else { $selecionados = Show-GenericoSubmenu -Itens $itens -Titulo "OTIMIZAR REDE" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> APLICANDO OTIMIZACOES DE REDE <<<" -ForegroundColor Magenta
    Write-Host ""; Backup-Rede

    $paraOtimizar = $selecionados | Where-Object { $_.Selected }
    $paraReverter = $selecionados | Where-Object { -not $_.Selected }
    $backupRede = Get-Content "$backupDir\rede_backup.json" | ConvertFrom-Json -ErrorAction SilentlyContinue

    foreach ($item in $paraOtimizar) {
        switch ($item.Nome) {
            "LiberarRenovarIP" {
                Write-Host "[Liberando e renovando IP]..." -NoNewline
                ipconfig /release | Out-Null; ipconfig /renew | Out-Null
                Write-Host " OK" -ForegroundColor Green
            }
            "ResetWinsock" {
                Write-Host "[Resetando Winsock e TCP/IP]..." -NoNewline
                netsh int ip reset | Out-Null; netsh winsock reset | Out-Null
                Write-Host " OK" -ForegroundColor Green
            }
            "DNSCloudflare" {
                Write-Host "[DNS Cloudflare (1.1.1.1)]..." -NoNewline
                $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" }
                foreach ($adapter in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
                }
                Write-Host " OK" -ForegroundColor Green
            }
            "AutoTuning" {
                Write-Host "[Ajustando auto-tuning TCP]..." -NoNewline
                netsh int tcp set global autotuninglevel=normal | Out-Null
                Write-Host " OK" -ForegroundColor Green
            }
        }
    }

    foreach ($item in $paraReverter) {
        switch ($item.Nome) {
            "LiberarRenovarIP" {
                Write-Host "[Liberar/renovar IP - NAO REVERTIVEL]..." -ForegroundColor DarkGray
            }
            "ResetWinsock" {
                Write-Host "[Reset Winsock - NAO REVERTIVEL]..." -ForegroundColor DarkGray
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
                    Write-Host " RESTAURADO" -ForegroundColor Cyan
                } else {
                    Write-Host "[DNS - SEM BACKUP]" -ForegroundColor DarkGray
                }
            }
            "AutoTuning" {
                if ($backupRede -and $backupRede.AutoTuning) {
                    Write-Host "[Restaurando auto-tuning ($($backupRede.AutoTuning))]..." -NoNewline
                    netsh int tcp set global autotuninglevel=$($backupRede.AutoTuning) | Out-Null
                    Write-Host " RESTAURADO" -ForegroundColor Cyan
                } else {
                    Write-Host "[Auto-tuning - SEM BACKUP]" -ForegroundColor DarkGray
                }
            }
        }
    }

    Write-Host ""; Write-Host "Rede otimizada! Use [9] no menu para desfazer." -ForegroundColor Green
}

function Show-GenericoSubmenu {
    param([array]$Itens, [string]$Titulo)

    do {
        Clear-Host; Show-Banner
        $h=[char]0x2550;$v=[char]0x2551;$w=46
        $top = "  $([char]0x2554)$($h*$w)$([char]0x2557)"
        $sep = "  $([char]0x2560)$($h*$w)$([char]0x2563)"
        $bot = "  $([char]0x255A)$($h*$w)$([char]0x255D)"
        $sub = "  $([char]0x255F)$($h*$w)$([char]0x2562)"

        $i = 1
        foreach ($item in $Itens) {
            $check = if ($item.Selected) { "[X]" } else { "[ ]" }
            $cor = if ($item.Selected) { "Green" } else { "DarkGray" }
            if ($i -eq 1) {
                Write-Host $top -ForegroundColor Cyan
                Write-Host "  $v  Digite o numero para alternar ON/OFF       $v" -ForegroundColor DarkCyan
                Write-Host $sep -ForegroundColor Cyan
            }
            Write-Host "  $v  $("{0,2}" -f $i). $check $("{0,-35}" -f $item.Desc) $v" -ForegroundColor $cor
            $i++
        }

        Write-Host $sub -ForegroundColor Cyan
        Write-Host "  $v  [A] Aplicar   [T] Marcar todos   [V] Voltar $v" -ForegroundColor Yellow
        Write-Host $bot -ForegroundColor Cyan
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
        @{Nome = "ModoDesempenho"; Desc = "Modo desempenho (VisualFX)"; Selected = $true}
        @{Nome = "Transparencia"; Desc = "Desativar transparencia"; Selected = $true}
        @{Nome = "Animacoes"; Desc = "Desativar animacoes"; Selected = $true}
        @{Nome = "SombrasEfeitos"; Desc = "Desativar sombras e efeitos"; Selected = $true}
    )

    if ($SkipMenu) { $selecionados = $itens }
    else { $selecionados = Show-GenericoSubmenu -Itens $itens -Titulo "AJUSTES VISUAIS" }
    if ($selecionados -eq $null) { return }

    Show-Banner
    Write-Host ">>> APLICANDO AJUSTES VISUAIS <<<" -ForegroundColor Magenta
    Write-Host ""; Backup-Visual

    $paraAplicar = $selecionados | Where-Object { $_.Selected }
    $paraReverter = $selecionados | Where-Object { -not $_.Selected }
    $backupVisual = Get-Content "$backupDir\visual_backup.json" | ConvertFrom-Json -ErrorAction SilentlyContinue

    foreach ($item in $paraAplicar) {
        switch ($item.Nome) {
            "ModoDesempenho" {
                Write-Host "[Modo desempenho]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor Green
            }
            "Transparencia" {
                Write-Host "[Desativando transparencia]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor Green
            }
            "Animacoes" {
                Write-Host "[Desativando animacoes]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor Green
            }
            "SombrasEfeitos" {
                Write-Host "[Desativando sombras e efeitos]..." -NoNewline
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -ErrorAction SilentlyContinue
                Write-Host " OK" -ForegroundColor Green
            }
        }
    }

    foreach ($item in $paraReverter) {
        if (-not $backupVisual) { Write-Host "[$($item.Desc) - SEM BACKUP]" -ForegroundColor DarkGray; continue }
        $mapa = @{ModoDesempenho="VisualFXSetting"; Transparencia="EnableTransparency"; Animacoes="UserPreferencesMask"; SombrasEfeitos="ListviewShadow"}
        $regName = $mapa[$item.Nome]
        $reg = $backupVisual | Where-Object { $_.Name -eq $regName }
        if (-not $reg) { Write-Host "[$($item.Desc) - SEM BACKUP]" -ForegroundColor DarkGray; continue }
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
        Write-Host " RESTAURADO" -ForegroundColor Cyan
    }

    Write-Host ""; Write-Host "Ajustes visuais aplicados! Use [10] no menu para desfazer." -ForegroundColor Green
}

function Undo-Servicos {
    Show-Banner
    Write-Host ">>> DESFAZER - SERVICOS <<<" -ForegroundColor Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\servicos_backup.json")) {
        Write-Host "Nenhum backup de servicos encontrado." -ForegroundColor Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\servicos_backup.json" | ConvertFrom-Json
    foreach ($item in $backup) {
        Write-Host "[$($item.Nome)]..." -NoNewline
        $svc = Get-Service -Name $item.Nome -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $item.Nome -StartupType $item.StartupType -ErrorAction SilentlyContinue
            if ($item.Status -eq "Running") { Start-Service -Name $item.Nome -ErrorAction SilentlyContinue }
            Write-Host " RESTAURADO ($($item.StartupType), $($item.Status))" -ForegroundColor Green
        } else { Write-Host " NAO ENCONTRADO" -ForegroundColor Gray }
    }
    Write-Host ""; Write-Host "Servicos restaurados!" -ForegroundColor Green
    Remove-Item "$backupDir\servicos_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Undo-Rede {
    Show-Banner
    Write-Host ">>> DESFAZER - REDE <<<" -ForegroundColor Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\rede_backup.json")) {
        Write-Host "Nenhum backup de rede encontrado." -ForegroundColor Red
        Wait-Key; return
    }
    $backup = Get-Content "$backupDir\rede_backup.json" | ConvertFrom-Json

    if ($backup.AutoTuning) {
        Write-Host "[Auto-Tuning TCP] Restaurando..." -NoNewline
        netsh int tcp set global autotuninglevel=$($backup.AutoTuning) | Out-Null
        Write-Host " OK ($($backup.AutoTuning))" -ForegroundColor Green
    }

    foreach ($adapter in $backup.Dns) {
        Write-Host "[DNS - $($adapter.InterfaceName)]..." -NoNewline
        if ($adapter.DnsServers -and $adapter.DnsServers.Count -gt 0) {
            $servers = @($adapter.DnsServers | ForEach-Object { "$_" })
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers -ErrorAction SilentlyContinue
            Write-Host " RESTAURADO ($($servers -join ', '))" -ForegroundColor Green
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            Write-Host " RESTAURADO (DHCP)" -ForegroundColor Green
        }
    }

    Write-Host ""; Write-Host "Rede restaurada!" -ForegroundColor Green
    Remove-Item "$backupDir\rede_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Undo-Visual {
    Show-Banner
    Write-Host ">>> DESFAZER - VISUAL <<<" -ForegroundColor Magenta
    Write-Host ""
    if (-not (Test-Path "$backupDir\visual_backup.json")) {
        Write-Host "Nenhum backup de visual encontrado." -ForegroundColor Red
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
            Write-Host " RESTAURADO" -ForegroundColor Green
        } catch { Write-Host " ERRO" -ForegroundColor Red }
    }
    Write-Host ""; Write-Host "Ajustes visuais restaurados!" -ForegroundColor Green
    Remove-Item "$backupDir\visual_backup.json" -Force -ErrorAction SilentlyContinue
    Wait-Key
}

function Run-LimpezaExtrema {
    Write-Host ">>> LIMPEZA EXTREMA (SEGURA) <<<" -ForegroundColor Magenta
    Write-Host "Limpa profundamente sem risco ao sistema." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "[ 1/18] Arquivos temporarios (Windows + Usuario)..." -NoNewline
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 2/18] Cache do Windows (Prefetch, INetCache)..." -NoNewline
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 3/18] Cache do Windows Update (seguro - redownload)..." -NoNewline
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Start-Service bits -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 4/18] Relatorios de erro (WER)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 5/18] Dumps de memoria (crash files)..." -NoNewline
    Remove-Item -Path "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 6/18] Logs do Windows..." -NoNewline
    Get-ChildItem -Path "C:\Windows\Logs" -Recurse -Include "*.log","*.etl" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\System32\LogFiles" -Recurse -Include "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 7/18] Cache de miniaturas (thumbnails)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.db" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 8/18] Cache de fontes..." -NoNewline
    Stop-Service FontCache -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service FontCache -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[ 9/18] Cache Delivery Optimization..." -NoNewline
    Remove-Item -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[10/18] Temporarios de instalacao (setup)..." -NoNewline
    Remove-Item -Path "C:\`$Windows.~BT" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\`$Windows.~WS" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Setup\Scripts\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Panther\*.log" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[11/18] Cache do .NET Framework..." -NoNewline
    Remove-Item -Path "C:\Windows\Microsoft.NET\Framework\*\NativeImages\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Microsoft.NET\Framework64\*\NativeImages\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[12/18] Cache do DirectX Shader..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\DirectX\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Users\*\AppData\Local\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[13/18] Cache do Windows Defender..." -NoNewline
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Scans\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Network Inspection System\Support\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[14/18] Arquivos temporarios do Office..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Office\*.tmp" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Office\*.log" -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[15/18] Cache de navegadores (Edge + Chrome)..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[16/18] Cache DNS e lixeira..." -NoNewline
    ipconfig /flushdns | Out-Null
    (New-Object -ComObject Shell.Application).Namespace(0xa).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[17/18] Limpeza via CleanMgr (modo extremo)..." -NoNewline
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green

    Write-Host "[18/18] Executando DISM (limpeza de componentes)..." -NoNewline
    dism /online /cleanup-image /StartComponentCleanup /Quiet /NoRestart | Out-Null
    dism /online /cleanup-image /SPSuperseded /Quiet /NoRestart | Out-Null
    Write-Host " OK" -ForegroundColor Green

    Write-Host ""; Write-Host "LIMPEZA EXTREMA CONCLUIDA!" -ForegroundColor Green
    Write-Host "Alguns GB de espaco foram liberados." -ForegroundColor Yellow
}
function Wait-Key {
    Write-Host ""; Write-Host "Pressione ENTER para voltar ao menu..." -ForegroundColor Gray
    $null = Read-Host
}

function Show-Welcome {
    Clear-Host
    $b = [char]0x2554; $b2 = [char]0x2557; $b3 = [char]0x255A; $b4 = [char]0x255D; $h2 = [char]0x2550; $v2 = [char]0x2551
    Write-Host "  $b$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b2" -ForegroundColor Cyan
    Write-Host "  $v2       T L   O P T I M I Z E R         $v2" -ForegroundColor Cyan
    Write-Host "  $b3$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$h2$b4" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   TL Optimizer foi carregado via iwr | iex." -ForegroundColor Yellow
    Write-Host "   Escolha como deseja usa-lo:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [P] Portatil  - Roda agora, nada e salvo no PC." -ForegroundColor Green
    Write-Host "                  Use quando quiser testar ou usar" -ForegroundColor DarkGray
    Write-Host "                  uma unica vez. Comando sempre funciona." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   [I] Instalar  - Salva em $env:USERPROFILE\TL-Optimizer" -ForegroundColor Cyan
    Write-Host "                  e registra no perfil do PowerShell." -ForegroundColor Cyan
    Write-Host "                  Depois e so digitar 'tl' de qualquer lugar." -ForegroundColor DarkGray
    Write-Host ""
}

function Install-Local {
    $targetDir = "$env:USERPROFILE\TL-Optimizer"
    $scriptPath = "$targetDir\otimizar-windows.ps1"
    Write-Host "Instalando em $targetDir..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    try {
        iwr -useb "$scriptUrl" -OutFile $scriptPath -ErrorAction Stop
        Write-Host "Script salvo." -ForegroundColor Green
    } catch {
        Write-Host "Erro ao baixar o script. Salvando da memoria..." -ForegroundColor Yellow
        if ($global:MyInvocation.MyCommand.ScriptContents) {
            $global:MyInvocation.MyCommand.ScriptContents | Set-Content -Path $scriptPath -Force
        } else {
            Write-Host "Nao foi possivel salvar. Verifique a conexao." -ForegroundColor Red
            Wait-Key; return
        }
    }
    $profileLine = "`n# TL Optimizer`nfunction tl-optimizer { & `"$scriptPath`" }`nSet-Alias -Name tl -Value tl-optimizer -Force"
    $profilePath = $PROFILE.CurrentUserAllHosts
    $dir = Split-Path $profilePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not (Test-Path $profilePath) -or (Get-Content $profilePath -Raw) -notmatch '# TL Optimizer') {
        Add-Content -Path $profilePath -Value $profileLine -Force
        Write-Host "Alias 'tl' adicionado ao perfil PowerShell." -ForegroundColor Green
    } else {
        Write-Host "Alias 'tl' ja existe no perfil." -ForegroundColor Yellow
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
        Write-Host "Atalho criado na Area de Trabalho." -ForegroundColor Green
    } catch {
        Write-Host "Nao foi possivel criar atalho na Area de Trabalho." -ForegroundColor DarkGray
    }
    Write-Host "`nInstalacao concluida! Reinicie o PowerShell e digite 'tl'." -ForegroundColor Green
    Wait-Key
    & $scriptPath
    exit
}

function Run-Tudo {
    Show-Banner
    Write-Host "Executando TODAS as otimizacoes..." -ForegroundColor Magenta
    Write-Host "Backups serao salvos automaticamente." -ForegroundColor Yellow
    Write-Host ""
    Backup-Servicos; Backup-Rede; Backup-Visual
    Write-Host ""; Run-LimpezaExtrema; Write-Host ""; Run-Servicos -SkipMenu; Write-Host ""; Run-Rede -SkipMenu; Write-Host ""; Run-Visual -SkipMenu
    Write-Host ""; Write-Host "TODAS AS OTIMIZACOES CONCLUIDAS!" -ForegroundColor Green
    Write-Host "Use [8], [9] e [10] no menu para desfazer cada categoria." -ForegroundColor Yellow
    Write-Host "Recomendado reiniciar o PC." -ForegroundColor Yellow
    Wait-Key
}

# === ADMIN CHECK ===
$isAdmin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $isAdmin.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($PSCommandPath) {
        Write-Host "Reiniciando como ADMINISTRADOR..." -ForegroundColor Yellow
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } else {
        Write-Host "ERRO: TL Optimizer precisa de privilegios de ADMINISTRADOR." -ForegroundColor Red
        Write-Host "Feche este PowerShell e abra como Administrador:" -ForegroundColor Yellow
        Write-Host "  1. Clique em Iniciar, digite 'PowerShell'" -ForegroundColor Yellow
        Write-Host "  2. Clique com direito > Executar como administrador" -ForegroundColor Yellow
        Write-Host "  3. Cole o comando novamente" -ForegroundColor Yellow
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

# === MAIN LOOP ===
do {
    Show-Menu

    $opcao = Read-Host "Digite o numero da opcao"

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
        "11" { Show-Help; Wait-Key }
        "0" { Write-Host "Saindo..." -ForegroundColor Green; break }
        default { Write-Host "Opcao invalida! Tente novamente." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($opcao -ne "0")
