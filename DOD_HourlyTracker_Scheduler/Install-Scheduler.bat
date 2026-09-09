@echo off
REM One-click register (prefers schtasks; falls back to PowerShell)
cd /d "%~dp0"
if exist "%~dp0Install-With-Schtasks.bat" (
  call "%~dp0Install-With-Schtasks.bat"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Register-DODScheduler.ps1" %*
  pause
)
