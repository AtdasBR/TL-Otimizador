# TL Optimizer - Bootstrap (via iwr | iex)
$repoUrl = "https://raw.githubusercontent.com/AtdasBR/TL-Otimizador/master"
$targetDir = "$env:USERPROFILE\TL-Optimizer"
$scriptPath = "$targetDir\otimizar-windows.ps1"

Write-Host "Baixando TL Optimizer..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

iwr -useb "$repoUrl/otimizar-windows.ps1" -OutFile $scriptPath -ErrorAction Stop
iwr -useb "$repoUrl/tl.bat" -OutFile "$targetDir\tl.bat" -ErrorAction SilentlyContinue

Write-Host "Adicionando ao PATH..." -ForegroundColor Cyan
$p = [Environment]::GetEnvironmentVariable('PATH','User')
if ($p -notlike '*TL-Optimizer*') {
    [Environment]::SetEnvironmentVariable('PATH', "$p;$targetDir", 'User')
}

Write-Host "Pronto! Abrindo TL Optimizer..." -ForegroundColor Green
& $scriptPath
