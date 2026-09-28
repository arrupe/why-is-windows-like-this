# Windows 11 Work PC Guide: Debloating and Troubleshooting

This guide covers two jobs:

1. **Debloating**: which built-in Windows 11 apps are safe to remove from a work PC, which to leave alone, how to remove them, and how to get them back.
2. **Troubleshooting**: a step-by-step process for working out why a PC is slow, freezing, crashing, or throwing errors, ordered from five-minute checks to deep diagnostics.

Unless a step says otherwise, run PowerShell as Administrator: right-click the Start button and choose **Terminal (Admin)**.

---

## Part 1: Debloating a Work PC

### Before you start

- **Managed devices.** On a company PC managed by Intune or Group Policy, some apps are pushed by policy and will reinstall on their own. Check with IT before removing anything beyond the "Very safe" list.
- **Create a restore point.** Press **Win+R**, type `sysdm.cpl`, open the System Protection tab, and click Create. If Create is greyed out, click Configure and turn on protection for the C: drive first.
- **Set expectations.** Removing built-in apps tidies the Start menu and frees a little disk space, but it rarely makes a PC noticeably faster. The changes that actually help are listed at the end of this part.
- **Avoid one-click "debloat" scripts from the internet.** They are the most common cause of the breakage described under "Do not remove".

### Very safe to remove

- Clipchamp
- TikTok
- Spotify
- Solitaire Collection
- News
- Microsoft Family
- Windows Maps
- Xbox Console Companion / Xbox app
- Xbox Game Bar (if you don't game)
- Xbox TCUI
- Xbox Identity Provider (if you don't use Xbox services)
- Movies & TV
- Weather
- Microsoft To Do
- Skype
- LinkedIn (if installed)
- Cortana (on older installs)

### Usually safe to remove

- Photos (if you have another image viewer)
- Paint 3D
- Mixed Reality Portal
- Quick Assist (unless your IT team uses it for remote support)
- OneNote (if you don't use it)
- People
- Journal
- Camera (on a desktop with no webcam)

### Be careful before removing

These won't usually break Windows, but many people end up reinstalling them:

- Microsoft Store
- Notepad
- Paint
- Snipping Tool
- Calculator
- Media Player
- Phone Link
- Terminal
- PowerShell 7

### Do not remove

- Edge
- WebView2 Runtime
- .NET Framework and .NET Runtime
- Microsoft Visual C++ Redistributables
- Windows Security (Defender)
- Search
- Start menu components
- App Installer
- Windows Shell Experience Host
- Store infrastructure packages

Removing these can cause blank Start menus, broken search, application crashes, login problems, and Store installation failures.

### Recommended keep list for a work PC

For a PC used for Excel and VBA, Power BI, Fabric, Power Automate, and Microsoft 365 admin tools, keep:

- **Edge**: many admin portals and single sign-on flows assume it is present
- **Microsoft Store**: Power BI Desktop and other apps install and update through it
- **WebView2 Runtime**: embedded in Office, Teams, Power BI, and many other apps
- **Terminal** and **PowerShell**
- **Notepad**, **Calculator**, **Snipping Tool**, and **Photos**
- **Quick Assist**, if IT uses it for remote support

Everything in the "Very safe" list is fair game.

### How to remove an app

**Settings:** Settings > Apps > Installed apps > the three-dot menu next to the app > Uninstall.

**PowerShell** (current user only):

```powershell
# See what is installed
Get-AppxPackage | Select-Object Name, PackageFullName | Sort-Object Name

# Remove one app (example: Clipchamp)
Get-AppxPackage *Clipchamp* | Remove-AppxPackage
```

To remove an app for every account on the PC and stop it reinstalling for new accounts (PowerShell as Administrator):

```powershell
Get-AppxPackage -AllUsers *Clipchamp* | Remove-AppxPackage -AllUsers
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Clipchamp*" | Remove-AppxProvisionedPackage -Online
```

Keep wildcards specific. `*Xbox*` matches several packages, and `*Store*` would catch the Microsoft Store itself. Run `Get-AppxPackage *name*` on its own to see what a wildcard matches before adding `Remove-AppxPackage`.

### How to restore an app you removed by mistake

- Reinstall it from the Microsoft Store (search by name), or with `winget install` from a terminal.
- If the Microsoft Store itself is missing, run `wsreset -i` from PowerShell to reinstall it.
- To re-register a built-in app whose files are still on disk (example: the Store):

```powershell
Get-AppxPackage -AllUsers *WindowsStore* | ForEach-Object {
    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
}
```

- If the Start menu, search, or the Store are broken and nothing above fixes them, run an in-place repair: Settings > System > Recovery > **Fix problems using Windows Update**. This reinstalls Windows while keeping apps, settings, and files.

### Changes that actually improve performance

Roughly in order of impact:

1. **Replace an HDD with an SSD.** The single biggest upgrade for an older PC. Part 2, step 5 shows how to check which one you have.
2. **Add RAM** if memory load sits at 90% or higher (Part 2, step 7). 16 GB is a sensible minimum for Excel, Power BI, Teams, and a browser open at the same time.
3. **Disable startup apps.** Settings > Apps > Startup, or Task Manager > Startup apps. Teams, OneDrive, Spotify, and manufacturer utilities are common offenders.
4. **Remove third-party antivirus** if Windows Security (Defender) is in use. Two antivirus products running at once is a classic cause of 100% disk usage.
5. **Clean up browser extensions.**
6. **Remove OEM bloatware** (Dell, HP, and Lenovo helper apps), but keep the manufacturer's driver and firmware update tool (Dell Command Update, Lenovo System Update, HP Support Assistant), which IT may rely on.
7. **Keep 15 to 20% of the system drive free** and turn on Storage Sense (Settings > System > Storage).
8. **Set the power mode to Best performance** on desktops and docked laptops (Settings > System > Power & battery > Power mode).
9. **Install pending Windows and driver updates and restart.** A PC that has been waiting on a restart for weeks often runs badly.

---

## Part 2: Investigating Slowdowns, Crashes, and Errors

Work down the steps in order. The first seven steps find the cause most of the time; the later steps are for stubborn cases. Part 3 has a condensed order and a symptom-to-step table.

### 1. Task Manager

Press **Ctrl+Shift+Esc**.

On the **Processes** tab, sort by CPU, Memory, and Disk in turn. Red flags:

- One process holding 50% or more CPU constantly
- Memory at 90% or higher with nothing heavy open
- Disk pinned at 100%. This is normal for a few minutes after boot on an HDD, but not normal all day, and rarely normal on an SSD.

On the **Startup apps** tab, disable anything non-essential, starting with entries marked High impact.

The **Performance** tab also shows the CPU model, RAM amount, and whether each drive is an SSD or HDD, which you will need if you ask for help (see the end of this guide).

### 2. Resource Monitor

Press **Win+R**, type `resmon`, and press Enter. Resource Monitor shows what Task Manager hides: which files each process is reading and writing, per-process disk response time, memory hard faults, and network use by process.

- **Disk tab:** expand Disk Activity and sort by Total (B/sec) to see which process and which file is generating the load. A Response Time consistently above 20 ms on an SSD points to a struggling drive or a process hammering it.
- **Memory tab:** a process with a high Hard Faults/sec is being paged to disk because RAM is short.
- **CPU tab:** right-click a hung process and choose Analyze Wait Chain to see what it is waiting on.

### 3. Event Viewer

Press **Win+X** and choose **Event Viewer**, then open **Windows Logs > System**.

Levels:

- **Warning**: often harmless on its own, but the same warning repeating can point at the root cause.
- **Error**: the ones to read. Disk and controller errors here can mean a failing drive, controller, or cable.
- **Critical**: the most severe. Kernel-Power Event ID 41 means the PC lost power or crashed without shutting down cleanly.

Use **Filter Current Log** and check these **Event sources**:

| Source | What it usually means |
|---|---|
| Disk, Ntfs, storahci, iaStorAC, volmgr | Storage. Disk 7 (bad block), 11 (controller error), and 153 (I/O retried) point at the drive or cable. Ntfs 55 means file system corruption; run `chkdsk` (step 5). |
| Kernel-Power, Kernel-Boot | Unexpected shutdowns, power problems, boot problems |
| WHEA-Logger | Hardware errors reported by the CPU, memory, or PCIe bus. Repeated entries mean failing hardware or a bad driver. |
| Service Control Manager | Services failing or timing out at startup |
| DistributedCOM | Event ID 10016 is extremely common and harmless. Ignore it unless something else points here. |

Also check **Windows Logs > Application** for app crashes (source Application Error, Event ID 1000) if one program is the problem.

PowerShell shortcuts (as Administrator):

```powershell
# Error and Critical events from the last 7 days in a sortable grid
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} |
    Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
    Out-GridView
```

```powershell
# Which sources are producing the most errors
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} |
    Group-Object ProviderName | Sort-Object Count -Descending |
    Select-Object Count, Name
```

`Out-GridView` is built into Windows PowerShell 5.1. In PowerShell 7 replace it with `Format-List` or install the `Microsoft.PowerShell.GraphicalTools` module.

To find out whether a specific error matters, search for the source and Event ID together (for example "storahci event 129"), or paste the source, ID, and message into Copilot or Claude.

### 4. Reliability Monitor

Press **Win+R**, type `perfmon /rel`, and press Enter.

This gives a day-by-day timeline of application crashes, Windows failures, failed updates, and driver problems. Look for the date the stability line dropped, then check what was installed or updated in the days just before it. Click any event and choose **View technical details** for the specifics.

### 5. Drive health and Windows file repair

**Check the drives:**

```powershell
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus
```

```powershell
Get-Volume | Select-Object DriveLetter, FileSystemLabel, HealthStatus,
    @{n="FreeGB"; e={[math]::Round($_.SizeRemaining/1GB, 1)}},
    @{n="SizeGB"; e={[math]::Round($_.Size/1GB, 1)}}
```

Red flags:

- **MediaType is HDD.** If the PC still runs Windows from a hard drive, that is often the biggest reason it feels slow.
- **HealthStatus is anything other than Healthy.** Back up the data before doing anything else.
- **Less than 10% free** on the system drive.

**Check the file system** if Event Viewer showed Ntfs or Disk errors:

```powershell
chkdsk C: /scan
```

This runs while Windows is up. If it reports problems, run `chkdsk C: /f` and restart to let it repair the drive.

**Repair Windows system files.** Run DISM first, because it repairs the component store that SFC pulls replacement files from, then run SFC:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
```

```powershell
sfc /scannow
```

These fix corruption caused by failed updates or aggressive debloat scripts. DISM needs to download files from Windows Update; if that fails on the work network, ask IT.

**If you think a debloat or uninstall caused the problem:**

```powershell
Get-AppxPackage | Select-Object Name | Sort-Object Name
```

Verify these are still present:

```text
Microsoft.WindowsStore
Microsoft.DesktopAppInstaller
Microsoft.Windows.Search
Microsoft.Windows.ShellExperienceHost
Microsoft.Windows.StartMenuExperienceHost
MicrosoftWindows.Client.WebExperience
```

If any are missing, see "How to restore an app" in Part 1.

### 6. System Diagnostics report

```powershell
perfmon /report
```

Wait about 60 seconds. Windows generates a report listing driver problems, services causing delays, hardware issues, and excessive startup time. Read the **Warnings** section at the top first. This is one of the best built-in diagnostics and takes almost no effort.

### 7. Temperatures, clocks, and memory load (HWiNFO)

Download the portable version of [HWiNFO](https://www.hwinfo.com/download/) and launch **HWiNFO64** in **Sensors-only** mode. (The free version is licensed for personal use; business use may need a paid license, so check first.)

**CPU temperatures.** Expand the CPU section and look at CPU Package, Core Max, and the individual core temperatures.

- Problematic if sustained at 90°C or above, or frequently spiking to 95 to 100°C.
- Check the **Thermal Throttling** and **Core Thermal Throttling** values. If either shows Yes, or the maximum column hits 100°C often, the CPU is slowing itself down to stay cool. Usual fixes: clear dust from the fans and vents, use a laptop on a hard surface rather than fabric, or have the thermal paste replaced.

**CPU clocks.** Look at the core clocks or effective clocks. A CPU with a base speed around 3 GHz should not sit at 400 or 800 MHz during active use. If clocks are stuck low but temperatures are fine, check for **Power Limit Exceeded** flags, a power plan set to Power saver, or, on a laptop, an underpowered charger.

**Memory.** Look at **Physical Memory Load**. Sitting at 90 to 100% most of the time means the PC needs more RAM or fewer things running.

**Drives.** Expand the storage device and look at:

- **Drive Temperature**: many NVMe drives throttle above about 70°C
- **Drive Failure** and **Drive Warning** flags: should both be No
- **Remaining Life** (SSDs): low values mean the drive is wearing out

### 8. Memory test

Press **Win+R**, type `mdsched.exe`, and choose **Restart now and check for problems**.

The test takes 10 to 30 minutes and the result appears after you log back in. It is also recorded in Event Viewer under Windows Logs > System with the source **MemoryDiagnostics-Results**. Any error means the RAM should be reseated or replaced. For a more thorough test, boot MemTest86 from a USB stick and let it run overnight.

### 9. Capture a performance log over time

For problems that come and go, capture counters over time with a Performance Monitor data collector set, then review the log after the slowdown happens.

**Create the collector** (one time, PowerShell as Administrator):

```powershell
New-Item -ItemType Directory -Force C:\PerfLogs\SlowPC | Out-Null

logman create counter "Slow PC Investigation" -o "C:\PerfLogs\SlowPC\SlowPC" -f bincirc -max 512 -si 00:00:05 -c "\Processor(_Total)\% Processor Time" "\Memory\Available MBytes" "\PhysicalDisk(_Total)\Avg. Disk Queue Length" "\PhysicalDisk(_Total)\Avg. Disk sec/Read" "\PhysicalDisk(_Total)\Avg. Disk sec/Write" "\Process(*)\% Processor Time" "\Process(*)\Private Bytes" "\Process(*)\IO Data Bytes/sec"
```

**Start capturing** when the PC starts feeling slow, or before the time of day it usually does:

```powershell
logman start "Slow PC Investigation"
logman query "Slow PC Investigation"
```

The query should show **Status: Running**.

**Reproduce the problem**, or keep working until the slowdown happens.

**Stop capturing** as soon as it does:

```powershell
logman stop "Slow PC Investigation"
Get-ChildItem C:\PerfLogs\SlowPC -Recurse -Filter *.blg
```

**Collect diagnostics** right afterward. Run this as Administrator; it writes a set of text files next to the log:

```powershell
$out = "C:\PerfLogs\SlowPC\Diagnostics_$(Get-Date -Format yyyyMMdd_HHmm)"
New-Item -ItemType Directory -Force $out | Out-Null

# Recent Error and Critical events
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -MaxEvents 300 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
    Format-List | Out-File "$out\SystemErrors.txt" -Width 200

# Boot performance (Event ID 100 is boot time; 101 to 110 name what slowed it)
Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 200 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Format-List | Out-File "$out\BootPerformance.txt" -Width 200

# Top processes by CPU time, with memory and handle counts
Get-Process | Sort-Object CPU -Descending | Select-Object -First 30 Name, Id, CPU,
    @{n="WorkingSetMB"; e={[math]::Round($_.WorkingSet64/1MB)}}, Handles |
    Format-Table -AutoSize | Out-File "$out\TopProcesses.txt" -Width 200

# Drives and volumes
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus,
    @{n="SizeGB"; e={[math]::Round($_.Size/1GB)}} |
    Format-Table -AutoSize | Out-File "$out\PhysicalDisks.txt" -Width 200
Get-Volume | Format-Table -AutoSize | Out-File "$out\Volumes.txt" -Width 200

# Startup entries
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User |
    Format-Table -AutoSize | Out-File "$out\StartupApps.txt" -Width 200

# Power and energy report (also flags devices and drivers with problems)
powercfg /energy /output "$out\EnergyReport.html" /duration 60

Write-Host "Diagnostics saved to $out"
```

**Open the log.** Double-click the `.blg` file, or run `perfmon`, open **Performance Monitor**, right-click the graph, choose **Properties > Source > Log files > Add**, and select the file.

**What to look for:**

| Problem | Counter | Concerning when |
|---|---|---|
| CPU | % Processor Time | Constantly 90 to 100% |
| Disk | Avg. Disk Queue Length | Constantly above 2 |
| Disk | Avg. Disk sec/Read | Above 20 ms (an SSD should be well under 10 ms) |
| Memory | Available MBytes | Drops below 500 MB |
| One process | % Processor Time, Private Bytes, IO Data Bytes/sec | One process dominates any of these |

Then open the diagnostics folder, starting with `SystemErrors.txt`, `BootPerformance.txt`, `EnergyReport.html`, `TopProcesses.txt`, and `PhysicalDisks.txt`.

Between the `.blg` file and the diagnostics folder you can usually say with confidence whether the culprit is hardware (SSD, RAM, overheating), Windows corruption, a driver, a startup program, antivirus, Outlook or OneDrive, or another specific process.

When you are finished, remove the collector:

```powershell
logman delete "Slow PC Investigation"
```

### 10. Sysinternals: Process Explorer and Process Monitor

Download the [Sysinternals Suite](https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite). Check the PC's architecture first:

```powershell
[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
```

If the output is **Arm64**, download the ARM64 suite; otherwise download the standard one. Extract the zip to a folder.

**Process Explorer** is a much more detailed Task Manager. Run it as Administrator and look for:

- **High CPU**: sort by the CPU column.
- **High handles**: add the Handle Count column (View > Select Columns > Process Performance). A runaway process can have tens of thousands of handles.
- **High I/O**: add I/O Reads and I/O Writes (View > Select Columns > Process I/O). This often catches software that Task Manager misses.

Hover over a process to see its full command line and parent, which helps identify unfamiliar entries.

**Process Monitor (ProcMon)** is the deep option for pauses, freezes, and stutters. Start a capture, reproduce the problem, stop the capture, then:

- Filter to the suspect process (Filter > Filter, Process Name is ...).
- Watch the **Result** column for `NAME NOT FOUND`, `ACCESS DENIED`, or `SHARING VIOLATION` repeating hundreds of times.
- Use **Tools > Process Activity Summary** and **File Summary** to see which processes and files dominate.

PCs have been made unusably slow by one application trying to open a missing file hundreds of times per second, and ProcMon shows that immediately.

### 11. Clean boot test

This separates Windows itself from third-party software.

1. Press **Win+R**, type `msconfig`, and press Enter.
2. On the **Services** tab, tick **Hide all Microsoft services**, then click **Disable all**.
3. On the **Startup** tab, click **Open Task Manager** and disable every startup app.
4. Click OK and restart.

If the PC is suddenly fast, hardware and Windows are fine and third-party software is the culprit. Re-enable half the services, restart, and repeat until you find the one responsible.

When finished, open `msconfig` again and choose **Normal startup** on the General tab, then re-enable the startup apps you want.

### 12. New user profile test

Many "slow computers" are actually damaged user profiles. Create a temporary local admin account (PowerShell as Administrator; the first command prompts for a password):

```powershell
net user TestAdmin * /add
net localgroup administrators TestAdmin /add
```

Sign in to the new account and use the PC normally. If it is fast there, the likely causes are:

- A corrupt Windows profile
- A corrupt Outlook profile
- OneDrive cache problems
- A broken search index

Delete the test account when you are done: `net user TestAdmin /delete`, then remove its profile folder under System Properties > Advanced > User Profiles > Settings.

On a work PC joined to Microsoft Entra or a domain, local account creation may be blocked by policy. If so, sign in with a second work account or ask IT.

### 13. DPC latency (LatencyMon)

For audio glitches, mouse lag, random stuttering, and intermittent freezes, run LatencyMon for 10 to 15 minutes during normal use. (Free for personal use; business use may need a license.)

The **Drivers** tab, sorted by highest execution time, names the driver responsible. Common offenders are network, Wi-Fi, graphics, and audio drivers. Updating or rolling back that one driver usually fixes it.

### 14. SSD benchmark (CrystalDiskMark)

Run CrystalDiskMark against the system drive. Rough expectations for sequential read:

| Drive type | Expected |
|---|---|
| NVMe SSD | 2,000 to 7,000 MB/s depending on generation |
| SATA SSD | About 500 MB/s |
| HDD | About 100 to 150 MB/s |

An NVMe SSD reading at 100 MB/s has found your problem. Drives can look healthy in SMART data and still perform terribly. Before blaming the drive, check that it is not nearly full and not overheating (step 7).

### 15. Windows Performance Recorder and Analyzer

For a definitive answer when nothing else finds it. `wpr.exe` ships with Windows 11; Windows Performance Analyzer (WPA) is a separate download from the Microsoft Store or the Windows ADK.

Start a trace (PowerShell as Administrator), reproduce the slowdown, then stop it:

```powershell
wpr -start GeneralProfile
```

```powershell
wpr -stop C:\PerfLogs\trace.etl
```

Open the `.etl` file in WPA. This is what Microsoft engineers use, and it can identify driver latency, DPC spikes, disk waits, CPU bottlenecks, interrupt storms, and slow boot drivers. Traces grow quickly, so keep the capture to a few minutes.

### 16. Safe Mode: the definitive hardware vs software test

Hold **Shift** while clicking Restart, then choose **Troubleshoot > Advanced options > Startup Settings > Restart** and press **4** for Safe Mode.

- Still slow in Safe Mode: hardware problem (drive, RAM, overheating).
- Fast in Safe Mode: Windows, a driver, or software.

Booting from a Windows PE or recovery USB gives the same answer but will prompt for the BitLocker recovery key on most work PCs, so involve IT before doing that.

---

## Part 3: Recommended Investigation Order

When someone says "this PC is super slow and I can't figure out why":

1. Task Manager (step 1)
2. Resource Monitor (step 2)
3. Event Viewer and Reliability Monitor (steps 3 and 4)
4. HWiNFO (step 7)
5. Drive health, DISM and SFC, and the System Diagnostics report (steps 5 and 6)
6. Clean boot (step 11)
7. New user profile (step 12)
8. Process Explorer (step 10)
9. Process Monitor (step 10)
10. WPR and WPA (step 15)

Most causes are identified by the seventh item. The memory test, LatencyMon, CrystalDiskMark, the performance log capture, and Safe Mode are targeted checks to pull in when the symptoms point that way:

| Symptom | Likely causes | Start with |
|---|---|---|
| Slow from the moment you log in | Startup apps, HDD, not enough RAM | Steps 1, 5, 7 |
| Fine at first, slows down after an hour or two | Memory leak, thermal throttling, runaway process | Steps 1, 7, 9, 10 |
| Disk stuck at 100% | HDD, antivirus conflict, search indexing, failing drive | Steps 2, 5, 14 |
| Stutter, audio glitches, mouse lag | Driver DPC latency | Steps 13, 3 |
| Random reboots or blue screens | Power, RAM, overheating, driver | Steps 3 (Kernel-Power, WHEA), 8, 7 |
| One app is slow (Outlook, Excel, Teams) | Add-ins, profile or cache, OneDrive sync | Steps 12, 10 |
| Slow for one user but fine for another | Corrupt user profile | Step 12 |
| Slow even after clean boot and a new profile | Hardware or Windows corruption | Steps 16, 5 |

## Information to Collect Before Asking for Help

Whether escalating to IT or asking an AI assistant which diagnostic to run next, have this ready:

- CPU model, RAM amount, and whether the system drive is an SSD or HDD (Task Manager > Performance)
- Windows version and build (**Win+R**, `winver`)
- Laptop or desktop, and whether it was on battery, plugged in, or docked when slow
- What is slow: boot, login, Outlook, Excel, the browser, or everything
- When it slows down: immediately after login, only after running for a while, all the time, or only during certain tasks
- What changed recently: updates, new software, new peripherals
- The output of the `Get-PhysicalDisk` command (step 5), the error-count command (step 3), and the Warnings section of the System Diagnostics report (step 6)

With that, the next diagnostic step can be chosen directly instead of checking everything.
