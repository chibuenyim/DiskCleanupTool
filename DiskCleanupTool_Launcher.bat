@echo off
REM Disk Cleanup Tool Launcher v4.0
REM Main launcher with menu for all tools

title Disk Cleanup Tool v4.0

:MENU
cls
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║     🧹 Disk Cleanup Tool v4.0 - Launcher Menu           ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo Choose an option:
echo.
echo   [1] Standard GUI (Original)
echo       - Full-featured GUI with all options
echo       - Windows temp, browser, dev, app, system cleanup
echo       - Advanced options: dry run, scan only, restore points
echo.
echo   [2] Enhanced GUI (NEW)
echo       - Quick presets: Quick, Standard, Deep cleanup
echo       - Quick actions: Recycle Bin, Browser, Dev, Update cache
echo       - Statistics tracking and history
echo       - Export/Import settings
echo.
echo   [3] Compression Utility (NEW)
echo       - Enable/disable CompactOS (save 2-5 GB)
echo       - Compress system folders (save 3-8 GB)
echo       - Compress user folders (save 1-5 GB)
echo       - NTFS compression for specific folders
echo.
echo   [4] Command-Line Mode
echo       - Run cleanup without GUI
echo       - Use scripts for automation
echo.
echo   [5] Scheduled Cleanup
echo       - Set up automatic weekly cleanup
echo       - Runs Sundays at 2 AM
echo.
echo   [6] View Statistics
echo       - See cleanup history
echo       - Total space freed
echo.
echo   [7] Help / Documentation
echo.
echo   [Q] Quit
echo.

set /p choice="Enter your choice: "

if /i "%choice%"=="1" goto STANDARD
if /i "%choice%"=="2" goto ENHANCED
if /i "%choice%"=="3" goto COMPRESSION
if /i "%choice%"=="4" goto CMDLINE
if /i "%choice%"=="5" goto SCHEDULE
if /i "%choice%"=="6" goto STATS
if /i "%choice%"=="7" goto HELP
if /i "%choice%"=="Q" goto QUIT
if /i "%choice%"=="q" goto QUIT

echo.
echo Invalid choice. Please try again.
pause
goto MENU

:STANDARD
echo.
echo Launching Standard GUI...
powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1"
pause
goto MENU

:ENHANCED
echo.
echo Launching Enhanced GUI...
powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool_Enhanced.ps1"
pause
goto MENU

:COMPRESSION
echo.
echo Launching Compression Utility...
powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool_Compression.ps1"
pause
goto MENU

:CMDLINE
echo.
echo Command-Line Mode
echo.
echo Available options:
echo   --DryRun       Preview cleanup without changes
echo   --ScanOnly     Scan and show what would be cleaned
echo   --Verbose      Show detailed output
echo.
echo Example: DiskCleanupTool.ps1 --DryRun --Verbose
echo.
set /p cmdline="Enter additional options (press Enter for none): "
powershell -ExecutionPolicy Bypass -File "%~dp0DiskCleanupTool.ps1" %cmdline%
pause
goto MENU

:SCHEDULE
echo.
echo Setting up scheduled cleanup...
powershell -ExecutionPolicy Bypass -Command "& '%~dp0DiskCleanupTool.ps1' -Schedule"
pause
goto MENU

:STATS
echo.
echo Cleanup Statistics
echo ═══════════════════
echo.
if exist "%USERPROFILE%\.diskcleanup\stats.json" (
    powershell -Command "$stats = Get-Content '%USERPROFILE%\.diskcleanup\stats.json' | ConvertFrom-Json; Write-Host 'Total Runs: ' $stats.TotalRuns; Write-Host 'Total Freed: ' ([math]::Round($stats.TotalFreed/1GB, 2)) ' GB'; Write-Host 'Last Run: ' $stats.LastRun"
) else (
    echo No statistics found yet. Run a cleanup first.
)
echo.
pause
goto MENU

:HELP
echo.
echo Disk Cleanup Tool v4.0 - Help
echo ════════════════════════════════
echo.
echo REPOSITORIES:
echo   Windows Tool:
echo   https://github.com/chibuenyim/DiskCleanupTool
echo.
echo   Universal Tool:
echo   https://github.com/chibuenyim/UniversalDiskCleanupTool
echo.
echo FEATURES:
echo   - Cleans 20-35 GB of disk space
echo   - 60+ application cache locations
echo   - 15+ package managers
echo   - 20+ developer tools
echo   - Windows Update cleanup
echo   - Windows.old removal (10-30 GB)
echo   - Hibernation removal (2-8 GB)
echo   - CompactOS compression (2-5 GB)
echo   - NTFS compression (1-8 GB)
echo.
echo SAFETY:
echo   - Only removes temporary files and caches
echo   - Never touches your documents or personal files
echo   - Optional system restore point creation
echo   - Dry run mode to preview changes
echo.
pause
goto MENU

:QUIT
echo.
echo Thanks for using Disk Cleanup Tool!
echo.
timeout /t 2 >nul
exit
