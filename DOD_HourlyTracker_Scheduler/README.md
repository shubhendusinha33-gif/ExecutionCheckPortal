# DOD Hourly Tracker — Windows Scheduler (every 10 min, 11:00–22:00)

Triggers `C:\Users\shubhendu.sinha\DOD_HourlyTracker_v21.vbs` on a Windows PC that has IE/Excel/Outlook available (same machine the VBS already runs on).

## Recommended: Task Scheduler (no install)

Built-in Windows only — nothing to install.

### Easiest (double-click)

1. Copy this folder to the Windows PC that already runs the VBS.
2. Right-click **`Install-With-Schtasks.bat`** → **Run as administrator**.
3. Confirm with: `schtasks /Query /TN DOD_HourlyTracker_10min /V /FO LIST`

Remove: double-click **`Uninstall-With-Schtasks.bat`**.

### PowerShell alternative (same schedule)

```powershell
cd <path-to>\DOD_HourlyTracker_Scheduler
powershell -ExecutionPolicy Bypass -File .\Register-DODScheduler.ps1
```

Remove: `.\Unregister-DODScheduler.ps1`

### VBS time-gate (required for LIVE mode)

In `DOD_HourlyTracker_v21.vbs`, set:

```vb
ALLOWED_HOURS = Array(11,12,13,14,15,16,17,18,19,20,21,22)
Const TEST_MODE = False   ' when ready for live recipients
```

Open `taskschd.msc` → **DOD_HourlyTracker_10min** to inspect visually.

## Alternative: keep-alive daemon

If Task Scheduler is blocked by policy:

```powershell
powershell -ExecutionPolicy Bypass -File .\Run-DODDaemon.ps1
```

Leave that window running (or start it at logon via a shortcut / startup folder). Prefer Task Scheduler for unattended use.

## Schedule details

| Setting | Value |
|--------|--------|
| First run | 11:00 |
| Interval | every 10 minutes |
| Last window hour | 22:xx (duration 11h 5m from 11:00) |
| Overlap | `IgnoreNew` — skips if previous run still going |
| Time gate | VBS `ALLOWED_HOURS` still applies in LIVE mode |

## Important

- GitHub is **not** required for this; these scripts only register a local Windows task.
- The daemon/task must run on the **Windows** machine with the portal, Excel workbook, and Outlook profile — not on this Linux cloud agent.
- Every successful run can send mail; 10-minute cadence means many emails unless `smartSkip` / hour gate / `TEST_MODE` limits work.
