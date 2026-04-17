╔═══════════════════════════════════════════════════════════════╗
║          Disk Cleanup & Windows Update Tool v1.0               ║
╚═══════════════════════════════════════════════════════════════╝

QUICK START
============

Option 1: Double-click "DiskCleanupTool.bat"
Option 2: Double-click "DiskCleanupTool.ps1"
Option 3: Run "build_exe.ps1" to create a standalone EXE

REQUIREMENTS
============

- Windows 10/11
- Administrator privileges
- PowerShell 5.1+


FEATURES
========

This tool will help you free up disk space by cleaning:

  ✓ Windows temporary files
  ✓ Browser caches (Chrome, Edge)
  ✓ Developer caches (npm, pip, Composer, yarn)
  ✓ Windows update residues (saves 2-6 GB!)
  ✓ Optional: Disable Windows Update
  ✓ Optional: Clean CapCut data

All with an easy-to-use graphical interface!


USAGE
=====

1. Double-click "DiskCleanupTool.bat"
2. Click "Yes" when prompted for Administrator access
3. Select the cleanup options you want
4. Click "Start Cleanup"
5. Wait for completion (may take 10-30 minutes for DISM)


HOW TO CREATE AN EXE FILE
==========================

If you want a standalone .exe file:

1. Right-click "build_exe.ps1"
2. Select "Run with PowerShell"
3. The script will automatically install PS2EXE and build DiskCleanupTool.exe

OR run manually in PowerShell (Admin):

  cd "C:\Users\chibu\DiskCleanupTool"
  .\build_exe.ps1

The resulting EXE can be copied to any Windows computer!


PORTABLE
========

This tool is completely portable! Copy the entire folder to:

- USB drive
- Network share
- Another computer

And run it anywhere!


SAFETY
======

- Only cleans temporary files and caches
- Does NOT delete your documents, pictures, or personal files
- Developer caches will be regenerated when needed
- Windows Update residues are safe to remove


DISABLING WINDOWS UPDATE
=========================

If you choose to disable Windows Update:

- Windows will no longer download or install updates
- Your system will NOT receive security patches
- Use with caution - recommended for offline/air-gapped systems only

To re-enable (if needed):

1. Open PowerShell (Admin)
2. Run: net start wuauserv
3. Run: net start UsoSvc
4. Delete the "# Windows Update blocked" section from:
   C:\Windows\System32\drivers\etc\hosts


TROUBLESHOOTING
===============

Q: "Running scripts is disabled on this system"
A: Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Q: GUI doesn't appear
A: Make sure .NET Framework 4.5+ is installed

Q: "Access denied" errors
A: Make sure to run as Administrator


FILES INCLUDED
==============

DiskCleanupTool.ps1  - Main PowerShell script with GUI
DiskCleanupTool.bat  - Batch file launcher
build_exe.ps1        - Script to create standalone EXE
README.txt           - This file


VERSION HISTORY
===============

v1.0.0 - Initial release
  - GUI interface
  - Multiple cleanup options
  - Windows Update disable functionality
  - DISM integration for WinSxS cleanup


SUPPORT
=======

Created with Claude Code
For issues or questions, refer to the build instructions.


LICENSE
=======

Free to use and modify.
Use at your own risk. Always backup important data.
