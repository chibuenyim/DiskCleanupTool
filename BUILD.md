# 📦 Build Instructions

## Quick Start - Just Run It!

Simply double-click **`run.bat`** to launch the tool!

## Creating a Standalone EXE

### Method 1: Using IExpress (Built into Windows)

1. Press **Win+R** and type: `iexpress`
2. Follow the wizard:
   - Select "Create new Self Extraction Directive file"
   - Select "Extract files and run an installation command"
   - Name: "Disk Cleanup Tool"
   - Select "No prompt"
   - Select "Don't display a license"
   - Add files: `run.bat`, `DiskCleanupTool.ps1`
   - Install program: `run.bat`
   - Select "Hidden" window style
   - Select "No message"
   - Save as: `DiskCleanupTool.exe`
   - Select "No restart"
   - Click **Finish**

### Method 2: Using PS2EXE

```powershell
# Install PS2EXE
Install-Module -Name ps2exe -Scope CurrentUser

# Import the module
Import-Module ps2exe

# Build the EXE
Invoke-PS2EXE `
    -inputFile ".\DiskCleanupTool.ps1" `
    -outputFile ".\DiskCleanupTool.exe" `
    -noConsole `
    -requireAdmin
```

### Method 3: Using the Build Script

```powershell
.\build_exe.ps1
```

## Files Included

- `run.bat` - Main launcher (use this!)
- `DiskCleanupTool.ps1` - PowerShell script with GUI
- `build_exe.ps1` - Automated build script
- `build_simple.bat` - IExpress build script
- `README.md` - Documentation

## Distribution

To distribute the tool:

1. Copy these files to a folder:
   - `run.bat`
   - `DiskCleanupTool.ps1`

2. Or build an EXE using one of the methods above

3. Distribute the EXE or folder

## System Requirements

- Windows 10/11
- Administrator privileges
- PowerShell 5.1+
- .NET Framework 4.5+ (for GUI)
