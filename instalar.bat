@echo off
title Instalar TL Optimizer
cd /d "%~dp0"
set "TARGET_DIR=%USERPROFILE%\TL-Optimizer"

echo Copiando arquivos para %TARGET_DIR%...
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
copy /Y "%~dp0otimizar-windows.ps1" "%TARGET_DIR%\otimizar-windows.ps1" >nul
copy /Y "%~dp0TL-Optimizer.bat" "%TARGET_DIR%\TL-Optimizer.bat" >nul
copy /Y "%~dp0tl.bat" "%TARGET_DIR%\tl.bat" >nul

echo Adicionando ao PATH do usuario (via PowerShell)...
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('PATH','User'); if ($p -notlike '*TL-Optimizer*') { [Environment]::SetEnvironmentVariable('PATH',$p+';%TARGET_DIR%','User') }"

echo.
echo =======================================
echo  TL Optimizer instalado com sucesso!
echo =======================================
echo.
echo Abra um NOVO CMD e digite:  tl
echo.
pause >nul
exit
