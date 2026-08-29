@echo off

rem "%~dp0elevator.exe" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Custom-MalwNrpt.ps1"

"%~dp0elevator.exe" powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Scripts/Custom-MalwNrpt.ps1'; Pause"