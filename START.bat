@echo off
REM ============================================
REM  Disk Cleanup Tool v5.0
REM  Double-click this file to start!
REM ============================================

title Disk Cleanup Tool v5.0

echo.
echo ============================================
echo    Disk Cleanup Tool v5.0
echo    Starting...
echo ============================================
echo.

REM Check if EXE exists
if exist "DiskCleanupTool.exe" (
    start "" "DiskCleanupTool.exe"
) else if exist "DiskCleanupTool.ps1" (
    REM Run PowerShell script
    PowerShell -ExecutionPolicy Bypass -File "DiskCleanupTool.ps1"
) else (
    echo ERROR: DiskCleanupTool not found!
    echo Please make sure you extracted all files.
    pause
)
