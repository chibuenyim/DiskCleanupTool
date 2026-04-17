@echo off
REM ============================================
REM  Disk Cleanup Tool v5.1 - Windows
REM  Double-click this file to start!
REM ============================================

title Disk Cleanup Tool v5.1

echo.
echo ============================================
echo    Disk Cleanup Tool v5.1
echo    Starting GUI...
echo ============================================
echo.

REM Check if launcher script exists
if not exist "%~dp0DiskCleanupTool.ps1" (
    echo ERROR: DiskCleanupTool.ps1 not found!
    echo Please make sure you extracted all files.
    echo.
    pause
    exit /b 1
)

REM Run PowerShell script
PowerShell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to launch the application.
    echo Please make sure all files are extracted properly.
    echo.
    pause
)
