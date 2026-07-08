# TL Optimizer - Bootstrap (via iwr | iex)
$repoUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master"
$targetDir = "$env:USERPROFILE\TL-Optimizer"
$scriptPath = "$targetDir\otimizar-windows.ps1"

Write-Host "Baixando TL Optimizer..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
iwr -useb "$repoUrl/otimizar-windows.ps1" -OutFile $scriptPath -ErrorAction Stop

Write-Host "Adicionando ao perfil do PowerShell..." -ForegroundColor Cyan
$profileLine = "`n# TL Optimizer`nfunction tl-optimizer { & `"$scriptPath`" }`nSet-Alias -Name tl -Value tl-optimizer -Force"
$profilePath = $PROFILE.CurrentUserAllHosts
$dir = Split-Path $profilePath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
if (-not (Test-Path $profilePath) -or (Get-Content $profilePath -Raw) -notmatch '# TL Optimizer') {
    Add-Content -Path $profilePath -Value $profileLine -Force
}

Write-Host "Pronto! Abrindo TL Optimizer..." -ForegroundColor Green
& $scriptPath
Write-Host "`nDepois de reiniciar o PowerShell, digite: tl" -ForegroundColor Yellow
