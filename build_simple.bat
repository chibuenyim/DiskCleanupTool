@echo off
echo Creating DiskCleanupTool executable...
echo.

REM Create IExpress build configuration
(
echo [Version]
echo Class=IEXPRESS
echo SEDVersion=3
echo [Options]
echo PackagePurpose=InstallApp
echo ShowInstallProgramWindow=1
echo HideExtractAnimation=0
echo UseLongFileName=1
echo InsideCompressed=0
echo CAB_FixedSize=0
echo CAB_ResvCodeSigning=0
echo RebootMode=N
echo InstallPrompt=
echo DisplayLicense=
echo FinishMessage=
echo TargetName=DiskCleanupTool.exe
echo FriendlyName=Disk Cleanup Tool
echo AppLaunched=cmd /c "DiskCleanupTool.bat"
echo PostInstallCmd=^<None^>
echo AdminQuietInstCmd=
echo UserQuietInstCmd=
echo SourceFiles=SourceFiles
echo [SourceFiles]
echo SourceFiles0=%~dp0
echo [SourceFiles0]
echo DiskCleanupTool.bat
echo DiskCleanupTool.ps1
) > "%~dp0build_config.sed"

echo.
echo Building executable with IExpress...
iexpress /N /Q "%~dp0build_config.sed"

if exist DiskCleanupTool.exe (
    echo.
    echo ==========================================
    echo SUCCESS! DiskCleanupTool.exe created!
    echo ==========================================
    echo.
    echo Location: %~dp0DiskCleanupTool.exe
    echo.
    dir DiskCleanupTool.exe | find "DiskCleanupTool.exe"
) else (
    echo.
    echo Build failed. Please run IExpress manually:
    echo 1. Press Win+R, type: iexpress
    echo 2. Follow the wizard
)

echo.
pause
