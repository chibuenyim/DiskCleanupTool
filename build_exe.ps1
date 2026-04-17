# Automated Build Script for Disk Cleanup Tool
# This script will convert the PowerShell script to a standalone EXE

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Cleanup Tool - Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if PS2EXE is installed
$module = Get-Module -ListAvailable -Name ps2exe

if (-not $module) {
    Write-Host "[!] PS2EXE module not found." -ForegroundColor Yellow
    Write-Host "[*] Installing PS2EXE module..." -ForegroundColor Yellow

    try {
        Install-Module -Name ps2exe -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "[+] PS2EXE installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to install PS2EXE." -ForegroundColor Red
        Write-Host "[*] Please run: Install-Module -Name ps2exe -Force" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or use the manual methods in BUILD_INSTRUCTIONS.txt" -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host ""
Write-Host "[*] Building DiskCleanupTool.exe..." -ForegroundColor Yellow
Write-Host ""

$inputFile = "C:\Users\chibu\DiskCleanupTool.ps1"
$outputFile = "C:\Users\chibu\DiskCleanupTool.exe"

# Check if input file exists
if (-not (Test-Path $inputFile)) {
    Write-Host "[!] Error: $inputFile not found!" -ForegroundColor Red
    pause
    exit 1
}

try {
    # Import PS2EXE module
    Import-Module ps2exe -ErrorAction Stop

    # Build parameters
    $params = @{
        inputFile = $inputFile
        outputFile = $outputFile
        noConsole = $true
        requireAdmin = $true
        title = "Disk Cleanup Tool"
        iconFile = $null
    }

    # Convert to EXE
    Invoke-PS2EXE @params

    Write-Host ""
    Write-Host "[+] SUCCESS!" -ForegroundColor Green
    Write-Host "[+] EXE created: $outputFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run DiskCleanupTool.exe on any Windows PC!" -ForegroundColor Cyan
    Write-Host ""

    # Show file size
    $size = (Get-Item $outputFile).Length
    $sizeMB = [math]::Round($size/1MB, 2)
    Write-Host "File size: $sizeMB MB" -ForegroundColor Gray

} catch {
    Write-Host ""
    Write-Host "[!] Build failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try one of these alternatives:" -ForegroundColor Yellow
    Write-Host "1. Use IExpress (built into Windows) - see BUILD_INSTRUCTIONS.txt" -ForegroundColor Gray
    Write-Host "2. Use the batch file: DiskCleanupTool.bat" -ForegroundColor Gray
    Write-Host "3. Run the PowerShell script directly: DiskCleanupTool.ps1" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
