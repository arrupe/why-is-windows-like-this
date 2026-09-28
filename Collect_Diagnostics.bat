@echo off
setlocal

REM =========================================
REM Create Timestamp
REM =========================================

for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value ^| find "="') do set DTS=%%I

set YYYY=%DTS:~0,4%
set MM=%DTS:~4,2%
set DD=%DTS:~6,2%
set HH=%DTS:~8,2%
set MIN=%DTS:~10,2%

set LOGDIR=C:\PerfLogs\Diagnostics\%YYYY%-%MM%-%DD%_%HH%-%MIN%

mkdir "%LOGDIR%" >nul 2>&1

echo.
echo =========================================
echo Collecting Diagnostics...
echo =========================================
echo.
echo Output Folder:
echo %LOGDIR%
echo.

REM =========================================
REM System Information
REM =========================================

systeminfo > "%LOGDIR%\SystemInfo.txt"

REM =========================================
REM Running Processes
REM =========================================

tasklist /v > "%LOGDIR%\TaskList.txt"

powershell -Command ^
"Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 100 Name,Id,CPU,@{Name='MemoryMB';Expression={[math\]::Round($_.WorkingSet64/1MB,2)}} | Out-File '%LOGDIR%\TopProcesses.txt'"

REM =========================================
REM Drivers
REM =========================================

driverquery /v > "%LOGDIR%\Drivers.txt"

REM =========================================
REM Startup Programs
REM =========================================

wmic startup get Caption,Command > "%LOGDIR%\StartupApps.txt"

REM =========================================
REM Services
REM =========================================

sc queryex type= service state= all > "%LOGDIR%\Services.txt"

REM =========================================
REM Memory Information
REM =========================================

wmic memorychip get Manufacturer,Capacity,Speed > "%LOGDIR%\Memory.txt"

REM =========================================
REM Disk Information
REM =========================================

wmic diskdrive get Model,Size,Status > "%LOGDIR%\DiskDrives.txt"

wmic logicaldisk get DeviceID,VolumeName,FileSystem,FreeSpace,Size > "%LOGDIR%\DiskUsage.txt"

powershell -Command ^
"Get-PhysicalDisk | Format-List * | Out-File '%LOGDIR%\PhysicalDisks.txt'"

powershell -Command ^
"Get-Volume | Format-Table * | Out-File '%LOGDIR%\Volumes.txt'"

REM =========================================
REM Network Information
REM =========================================

ipconfig /all > "%LOGDIR%\IPConfig.txt"

netstat -ano > "%LOGDIR%\Netstat.txt"

REM =========================================
REM Power Configuration
REM =========================================

powercfg /energy /duration 60 /output "%LOGDIR%\EnergyReport.html"

powercfg /qh > "%LOGDIR%\PowerPlanSettings.txt"

powercfg /getactivescheme > "%LOGDIR%\ActivePowerPlan.txt"

REM =========================================
REM Event Viewer
REM =========================================

wevtutil qe System ^
/q:"*[System[(Level=1 or Level=2)]]" ^
/f:text /c:300 ^
> "%LOGDIR%\SystemErrors.txt"

wevtutil qe Application ^
/q:"*[System[(Level=1 or Level=2)]]" ^
/f:text /c:300 ^
> "%LOGDIR%\ApplicationErrors.txt"

REM =========================================
REM Boot Performance Events
REM =========================================

wevtutil qe Microsoft-Windows-Diagnostics-Performance/Operational ^
/f:text /c:200 ^
> "%LOGDIR%\BootPerformance.txt"

REM =========================================
REM Windows Integrity
REM =========================================

sfc /verifyonly > "%LOGDIR%\SFCVerify.txt"

REM =========================================
REM Resource Utilization Snapshot
REM =========================================

typeperf "\Processor(_Total)\%% Processor Time" ^
"\Memory\Available MBytes" ^
"\PhysicalDisk(_Total)\%% Disk Time" ^
-sc 30 > "%LOGDIR%\LivePerformanceSnapshot.csv"

REM =========================================
REM Performance Monitor Report
REM =========================================

echo.
echo Generating Performance Report...
echo This takes about 60 seconds...
echo.

perfmon /report

echo.
echo =========================================
echo Diagnostics Collection Complete
echo =========================================
echo.
echo Results Saved To:
echo %LOGDIR%
echo.

start "" explorer "%LOGDIR%"

pause
endlocal