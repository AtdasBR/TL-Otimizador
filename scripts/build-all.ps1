# ================================================
#  Build script: TL Optimizer (Launcher + Setup)
#  Executar da raiz do projeto com:
#    powershell -ExecutionPolicy Bypass -File scripts\build-all.ps1
# ================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== TL Optimizer - Build Completo ===" -ForegroundColor Cyan

# 1. Publicar o launcher WinForms
Write-Host "`n[1/3] Publicando launcher..." -ForegroundColor Yellow
dotnet publish "$root\src\TLOptimizer.Launcher" -c Release `
    -p:PublishSingleFile=true -p:SelfContained=true `
    -p:RuntimeIdentifier=win-x64 -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o "$root\dist\publicacao"
if ($LASTEXITCODE -ne 0) { throw "Falha ao publicar launcher" }

# 2. Copiar logos e scripts para o publish
Write-Host "[2/3] Copiando recursos..." -ForegroundColor Yellow
if (Test-Path "$root\recursos\logos") {
    New-Item -ItemType Directory -Path "$root\dist\publicacao\recursos\logos" -Force | Out-Null
    Copy-Item "$root\recursos\logos\*.png" "$root\dist\publicacao\recursos\logos\" -Force
}
if (Test-Path "$root\scripts") {
    New-Item -ItemType Directory -Path "$root\dist\publicacao\scripts" -Force | Out-Null
    Copy-Item "$root\scripts\*.ps1" "$root\dist\publicacao\scripts\" -Force
}

# 3. Publicar o instalador WPF
Write-Host "[3/3] Publicando instalador WPF..." -ForegroundColor Yellow
Remove-Item "$root\dist\instalador\TLOptimizer.Setup.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$root\dist\instalador\*.json" -Force -ErrorAction SilentlyContinue
dotnet publish "$root\src\TLOptimizer.Setup" -c Release `
    -p:PublishSingleFile=true -p:SelfContained=true `
    -p:RuntimeIdentifier=win-x64 -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o "$root\dist\instalador"
if ($LASTEXITCODE -ne 0) { throw "Falha ao publicar instalador WPF" }

# 4. Copiar publish content para installer\package\ (para o WPF installer encontrar)
Write-Host "[4/4] Empacotando conteúdo..." -ForegroundColor Yellow
$pkgDir = "$root\dist\instalador\pacote"
if (Test-Path $pkgDir) { Remove-Item "$pkgDir\*" -Recurse -Force }
New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
Get-ChildItem "$root\dist\publicacao" -Exclude "*Setup*","*.pdb" | Copy-Item -Destination $pkgDir -Recurse -Force

Write-Host "`n=== Build concluído! ===" -ForegroundColor Green
Write-Host "Instalador: $root\dist\instalador\TLOptimizer.Setup.exe" -ForegroundColor Green
Write-Host "Conteúdo:   $root\dist\instalador\pacote\" -ForegroundColor Green
