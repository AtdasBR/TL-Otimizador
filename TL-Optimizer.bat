@echo off
title TL Optimizer
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0otimizar-windows.ps1"
pause