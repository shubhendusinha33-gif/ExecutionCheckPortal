#Requires -Version 5.1
<#
.SYNOPSIS
  Removes the DOD_HourlyTracker scheduled task.
#>
param(
    [string]$TaskName = "DOD_HourlyTracker_10min"
)

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host "Task not found: $TaskName"
    exit 0
}

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Removed task: $TaskName" -ForegroundColor Yellow
