@echo off
REM Disk Cleanup Tool Enhanced Edition Launcher
REM Quick launcher for the enhanced GUI with presets and statistics

echo.
echo ===================================
echo 🧹 Disk Cleanup Tool v4.0
echo Enhanced Edition
echo ===================================
echo.

REM Check for admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool_Enhanced.ps1"
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool_Enhanced.ps1"
)

pause
