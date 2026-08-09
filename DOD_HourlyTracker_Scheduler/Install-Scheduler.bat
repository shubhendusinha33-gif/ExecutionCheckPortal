@echo off
REM One-click register for DOD Hourly Tracker (every 10 min, 11:00-22:00)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Register-DODScheduler.ps1" %*
pause
