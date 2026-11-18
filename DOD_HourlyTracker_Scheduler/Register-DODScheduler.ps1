#Requires -Version 5.1
<#
.SYNOPSIS
  Registers a Windows Scheduled Task that runs DOD_HourlyTracker_v21.vbs
  every 10 minutes from 11:00 through 22:00 (local time).

.DESCRIPTION
  Task name : DOD_HourlyTracker_10min
  Trigger   : Daily at 11:00, repeat every 10 min for 11h 5m (covers 22:00)
  Action    : wscript.exe //B //Nologo "<script path>"

  Run once (same Windows user that owns Outlook/Excel):
    powershell -ExecutionPolicy Bypass -File ".\Register-DODScheduler.ps1"
#>

param(
    [string]$ScriptPath = "C:\Users\shubhendu.sinha\DOD_HourlyTracker_v21.vbs",
    [string]$TaskName   = "DOD_HourlyTracker_10min",
    [string]$StartTime  = "11:00",
    [int]$IntervalMinutes = 10,
    [int]$DurationHours   = 11,
    [int]$DurationExtraMinutes = 5
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Error "VBS not found: $ScriptPath`nPass -ScriptPath with the correct location."
}

$wscript = Join-Path $env:SystemRoot "System32\wscript.exe"
if (-not (Test-Path -LiteralPath $wscript)) {
    Write-Error "wscript.exe not found at $wscript"
}

Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue |
    Unregister-ScheduledTask -Confirm:$false

$action = New-ScheduledTaskAction `
    -Execute $wscript `
    -Argument "//B //Nologo `"$ScriptPath`""

$start = [datetime]::Today.Add([timespan]::ParseExact($StartTime, "hh\:mm", $null))
$interval = New-TimeSpan -Minutes $IntervalMinutes
$duration = New-TimeSpan -Hours $DurationHours -Minutes $DurationExtraMinutes

# Compatible pattern: Daily trigger + copy Repetition from a Once trigger
$daily = New-ScheduledTaskTrigger -Daily -At $start
$once  = New-ScheduledTaskTrigger -Once -At $start `
    -RepetitionInterval $interval `
    -RepetitionDuration $duration
$daily.Repetition = $once.Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -MultipleInstances IgnoreNew `
    -RestartCount 1 `
    -RestartInterval (New-TimeSpan -Minutes 2)

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $daily `
    -Settings $settings `
    -Principal $principal `
    -Description "VMM DOD Hourly Tracker — every $IntervalMinutes min from $StartTime through ~22:00" |
    Out-Null

Write-Host ""
Write-Host "Registered task: $TaskName" -ForegroundColor Green
Write-Host "  Script   : $ScriptPath"
Write-Host "  Schedule : every $IntervalMinutes min, daily from $StartTime for $($DurationHours)h ${DurationExtraMinutes}m"
Write-Host "  Runs as  : $env:USERDOMAIN\$env:USERNAME (Interactive)"
Write-Host ""
Write-Host "Verify:"
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Get-ScheduledTaskInfo"
Write-Host ""
Write-Host "In the VBS set:"
Write-Host "  ALLOWED_HOURS = Array(11,12,13,14,15,16,17,18,19,20,21,22)"
Write-Host "  Const TEST_MODE = False   (when ready for live mail)"
Write-Host ""
