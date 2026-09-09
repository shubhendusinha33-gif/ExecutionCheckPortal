#Requires -Version 5.1
<#
.SYNOPSIS
  Lightweight daemon alternative to Task Scheduler.
  Runs DOD_HourlyTracker_v21.vbs every 10 minutes between 11:00 and 22:59.

.DESCRIPTION
  Prefer Register-DODScheduler.ps1 (Task Scheduler) for production.
  Use this only if Task Scheduler is blocked by policy.

  Start (keep window open, or run via Start-Process -WindowStyle Hidden):
    powershell -ExecutionPolicy Bypass -File ".\Run-DODDaemon.ps1"

  Stop: Ctrl+C, or close the window / kill the powershell process.
#>

param(
    [string]$ScriptPath = "C:\Users\shubhendu.sinha\DOD_HourlyTracker_v21.vbs",
    [int]$IntervalMinutes = 10,
    [int]$StartHour = 11,
    [int]$EndHour   = 22   # inclusive through 22:xx
)

$ErrorActionPreference = "Continue"
$wscript = Join-Path $env:SystemRoot "System32\wscript.exe"

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Error "VBS not found: $ScriptPath"
    exit 1
}

Write-Host "DOD Daemon started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "  Window   : ${StartHour}:00 - ${EndHour}:59 every $IntervalMinutes min"
Write-Host "  Script   : $ScriptPath"
Write-Host "  Stop with Ctrl+C"
Write-Host ""

function Should-RunNow {
    $h = (Get-Date).Hour
    return ($h -ge $StartHour -and $h -le $EndHour)
}

function Invoke-DOD {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$stamp] Launching VBS..."
    # //B = batch (no script UI); wait so overlapping runs are avoided
    $p = Start-Process -FilePath $wscript `
        -ArgumentList "//B","//Nologo","`"$ScriptPath`"" `
        -PassThru -Wait -WindowStyle Hidden
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Exit code: $($p.ExitCode)"
}

# Align to next :00 / :10 / :20 / :30 / :40 / :50 boundary
function Get-MsUntilNextSlot {
    param([int]$EveryMinutes)
    $now = Get-Date
    $slot = [math]::Ceiling($now.Minute / $EveryMinutes) * $EveryMinutes
    $next = $now.Date.AddHours($now.Hour)
    if ($slot -ge 60) {
        $next = $next.AddHours(1)
    } else {
        $next = $next.AddMinutes($slot)
    }
    if ($next -le $now) { $next = $next.AddMinutes($EveryMinutes) }
    return [math]::Max(0, [int]($next - $now).TotalMilliseconds)
}

# Optional: run immediately if currently inside window
if (Should-RunNow) {
    Invoke-DOD
}

while ($true) {
    $waitMs = Get-MsUntilNextSlot -EveryMinutes $IntervalMinutes
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Next slot in $([math]::Round($waitMs/1000))s"
    Start-Sleep -Milliseconds $waitMs

    if (Should-RunNow) {
        Invoke-DOD
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Outside $StartHour-$EndHour window — skip"
    }
}
