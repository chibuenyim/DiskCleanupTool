@echo off
title Disk Cleanup Tool
echo Launching Disk Cleanup Tool...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Error running script. Press any key to exit...
    pause >nul
)
