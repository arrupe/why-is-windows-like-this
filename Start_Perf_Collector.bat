@echo off
setlocal

REM Create date/time stamp
for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value ^| find "="') do set DTS=%%I

set YYYY=%DTS:~0,4%
set MM=%DTS:~4,2%
set DD=%DTS:~6,2%
set HH=%DTS:~8,2%
set MIN=%DTS:~10,2%

set LOGDIR=C:\PerfLogs\SlowPC\%YYYY%-%MM%-%DD%_%HH%-%MIN%

mkdir "%LOGDIR%" >nul 2>&1

logman stop "Slow PC Investigation" >nul 2>&1

logman update "Slow PC Investigation" ^
-o "%LOGDIR%\SlowPC"

logman start "Slow PC Investigation"

echo.
echo ========================================
echo Performance Logging Started
echo ========================================
echo.
echo Log Folder:
echo %LOGDIR%
echo.
echo Reproduce the slowdown.
echo Run Stop_Perf_Collector.bat when finished.
echo.

start "" explorer "%LOGDIR%"

pause
endlocal