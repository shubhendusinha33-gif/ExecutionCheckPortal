@echo off
REM Remove DOD Hourly Tracker scheduled task (schtasks only)
set "TASKNAME=DOD_HourlyTracker_10min"
schtasks /Delete /TN "%TASKNAME%" /F
if errorlevel 1 (
  echo Task not found or could not delete: %TASKNAME%
) else (
  echo Removed: %TASKNAME%
)
pause
