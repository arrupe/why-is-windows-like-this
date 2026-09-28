@echo off

powershell -NoProfile -Command ^
"Get-WinEvent -LogName System -MaxEvents 1000 | Where-Object {$_.LevelDisplayName -in @('Error','Critical')} | Select TimeCreated,ProviderName,Id,LevelDisplayName,Message | Out-GridView"

pause