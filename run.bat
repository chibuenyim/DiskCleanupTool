@echo off
REM Disk Cleanup Tool Launcher
REM This is the main executable - double-click to run

title Disk Cleanup Tool
echo.
echo ==========================================
echo   Disk Cleanup ^& Windows Update Tool
echo ==========================================
echo.
echo Starting...
echo.

REM Check for admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Run the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1"

if %errorLevel% neq 0 (
    echo.
    echo [!] Error running cleanup tool.
    echo [!] Press any key to exit...
    pause >nul
)
