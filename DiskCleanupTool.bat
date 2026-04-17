@echo off
title Disk Cleanup Tool v2.0
echo Launching Disk Cleanup Tool v2.0 - Comprehensive Cleaning...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Error running script. Press any key to exit...
    pause >nul
)
