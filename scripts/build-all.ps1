# ================================================
#  Build script: TL Optimizer (Launcher + Instalador Inno)
#  O instalador unico do projeto e o Inno Setup (implantacao/tloptimizer.iss).
#  Executar da raiz do projeto com:
#    powershell -ExecutionPolicy Bypass -File scripts\build-all.ps1
# ================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== TL Optimizer - Build Completo ===" -ForegroundColor Cyan

# 0. Localizar ISCC (Inno Setup 6)
$iscc = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
if (-not $iscc) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    )
    $isccPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $isccPath) {
        throw "ISCC.exe (Inno Setup 6) nao encontrado. Instale com: winget install JRSoftware.InnoSetup"
    }
} else {
    $isccPath = $iscc.Source
}
Write-Host "ISCC: $isccPath" -ForegroundColor Gray

# 1. Publicar launcher single-file em build/publish (staging do instalador)
Write-Host "`n[1/4] Publicando launcher (build/publish)..." -ForegroundColor Yellow
Remove-Item "$root\build\publish\*" -Recurse -Force -ErrorAction SilentlyContinue
dotnet publish "$root\src\TLOptimizer.Launcher" `
    -c Release `
    -p:PublishSingleFile=true -p:SelfContained=true `
    -p:RuntimeIdentifier=win-x64 -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o "$root\build\publish"
if ($LASTEXITCODE -ne 0) { throw "Falha ao publicar launcher" }
Remove-Item "$root\build\publish\*.pdb" -Force -ErrorAction SilentlyContinue

# 2. Copiar recursos e scripts para o staging do instalador
Write-Host "[2/4] Copiando recursos e scripts..." -ForegroundColor Yellow
Copy-Item "$root\src\TLOptimizer.Launcher\icon.ico" "$root\build\publish\" -Force
New-Item -ItemType Directory -Path "$root\build\publish\scripts" -Force | Out-Null
Copy-Item "$root\scripts\otimizar-windows.ps1" "$root\build\publish\scripts\" -Force
if (Test-Path "$root\recursos\logos") {
    New-Item -ItemType Directory -Path "$root\build\publish\recursos\logos" -Force | Out-Null
    Copy-Item "$root\recursos\logos\*.png" "$root\build\publish\recursos\logos\" -Force
}

# 3. Sincronizar dist/publicacao (launcher + recursos publicados)
Write-Host "[3/4] Sincronizando dist/publicacao..." -ForegroundColor Yellow
Remove-Item "$root\dist\publicacao\*" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$root\dist\publicacao" -Force | Out-Null
Get-ChildItem "$root\build\publish" -Exclude "*.pdb" | Copy-Item -Destination "$root\dist\publicacao" -Recurse -Force

# 4. Compilar instalador Inno e sincronizar dist/instalador
Write-Host "[4/4] Compilando instalador Inno..." -ForegroundColor Yellow
& $isccPath "$root\implantacao\tloptimizer.iss"
if ($LASTEXITCODE -ne 0) { throw "Falha ao compilar instalador Inno" }
$novoSetup = Get-ChildItem "$root\build\installer\TLOptimizer-Setup-*.exe" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $novoSetup) { throw "Instalador nao encontrado em build/installer" }
Remove-Item "$root\dist\instalador\*" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$root\dist\instalador" -Force | Out-Null
Copy-Item $novoSetup.FullName "$root\dist\instalador\" -Force

Write-Host "`n=== Build concluido! ===" -ForegroundColor Green
Write-Host "Launcher:   $root\dist\publicacao\TLOptimizer.exe" -ForegroundColor Green
Write-Host "Instalador: $($novoSetup.Name)" -ForegroundColor Green