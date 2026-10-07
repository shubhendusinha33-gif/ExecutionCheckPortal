@echo off
REM ================================================================
REM  DOD Hourly Tracker — Task Scheduler (schtasks only, no install)
REM  Runs: C:\Users\shubhendu.sinha\DOD_HourlyTracker_v21.vbs
REM  Every 10 minutes, daily from 11:00 for 11 hours 5 minutes
REM  (covers 11:00 .. 22:00 inclusive)
REM ================================================================
setlocal

set "TASKNAME=DOD_HourlyTracker_10min"
set "VBS=C:\Users\shubhendu.sinha\DOD_HourlyTracker_v21.vbs"
set "WSCRIPT=%SystemRoot%\System32\wscript.exe"

if not exist "%VBS%" (
  echo ERROR: VBS not found:
  echo   %VBS%
  echo Edit this .bat and set VBS= to the correct path.
  pause
  exit /b 1
)

if not exist "%WSCRIPT%" (
  echo ERROR: wscript.exe not found at %WSCRIPT%
  pause
  exit /b 1
)

echo Removing old task if present...
schtasks /Delete /TN "%TASKNAME%" /F >nul 2>&1

echo Creating task "%TASKNAME%" ...
REM /SC DAILY /ST 11:00  = start each day at 11:00
REM /RI 10               = repeat every 10 minutes
REM /DU 11:05            = keep repeating for 11h 5m (through 22:00)
REM /RL HIGHEST          = elevated (helps Excel/Outlook COM)
REM /F                   = overwrite if exists
schtasks /Create /TN "%TASKNAME%" ^
  /TR "\"%WSCRIPT%\" //B //Nologo \"%VBS%\"" ^
  /SC DAILY /ST 11:00 /RI 10 /DU 11:05 ^
  /RL HIGHEST /F

if errorlevel 1 (
  echo.
  echo FAILED. Try running this .bat as Administrator, or use Register-DODScheduler.ps1
  pause
  exit /b 1
)

echo.
echo OK — task registered.
echo   Name     : %TASKNAME%
echo   Script   : %VBS%
echo   Schedule : every 10 min from 11:00 through ~22:00
echo.
echo Also update ALLOWED_HOURS in the VBS (LIVE mode):
echo   ALLOWED_HOURS = Array(11,12,13,14,15,16,17,18,19,20,21,22)
echo.
echo Verify:
echo   schtasks /Query /TN "%TASKNAME%" /V /FO LIST
echo.
pause
endlocal
