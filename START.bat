@echo off
REM ============================================
REM  Disk Cleanup Tool v4.0 - Windows
REM  Double-click this file to start!
REM ============================================

title Disk Cleanup Tool

echo.
echo ============================================
echo    Disk Cleanup Tool v4.0
echo    Starting GUI...
echo ============================================
echo.

REM Check if PowerShell is available
where pwsh >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo PowerShell Core not found. Using Windows PowerShell...
    powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0DiskCleanupTool_Launcher.bat"
) else (
    pwsh -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0DiskCleanupTool_Launcher.bat"
)
