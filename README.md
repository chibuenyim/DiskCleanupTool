# 🧹 Disk Cleanup & Windows Update Tool

A comprehensive Windows disk cleanup utility with a graphical interface. Frees up 15+ GB of disk space by cleaning temporary files, caches, and Windows update residues.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

- 🖥️ **Graphical Interface** - Easy-to-use GUI with checkboxes
- 🗑️ **Cleans 15+ GB** of junk files and caches
- 🚫 **Disable Windows Update** - Optional Windows Update disable
- 📦 **Portable** - No installation required
- 🔒 **Safe** - Only removes temporary files and caches
- ⚡ **Fast** - Cleans multiple locations efficiently

## 🧹 What It Cleans

| Category | Description | Space Saved |
|----------|-------------|-------------|
| **Windows Temp** | Temporary files from Windows and user temp folders | ~500 MB |
| **Browser Caches** | Chrome, Edge browser caches | ~500 MB |
| **Developer Caches** | npm, pip, Composer, yarn, Playwright, Cypress | ~10 GB |
| **Windows Update** | SoftwareDistribution, WinSxS cleanup | 2-6 GB |
| **CapCut Data** | CapCut application user data (optional) | ~2 GB |

## 📋 Requirements

- Windows 10/11
- Administrator privileges
- PowerShell 5.1+
- .NET Framework 4.5+ (for GUI)

## 🚀 Quick Start

### Option 1: Run from Source

```bash
# Clone the repository
git clone https://github.com/chibuenyim/DiskCleanupTool.git
cd DiskCleanupTool

# Run the tool
.\DiskCleanupTool.bat
```

### Option 2: Build EXE

```powershell
# Run the build script
.\build_exe.ps1
```

This will create `DiskCleanupTool.exe` - a standalone executable you can run anywhere!

## 📸 Screenshots

![GUI Screenshot](https://via.placeholder.com/600x400?text=Disk+Cleanup+Tool+GUI)

## 🛠️ Building from Source

### Prerequisites

```powershell
# Install PS2EXE module
Install-Module -Name ps2exe -Scope CurrentUser
```

### Build Commands

```powershell
# Import the module
Import-Module ps2exe

# Build the EXE
Invoke-PS2EXE -inputFile ".\DiskCleanupTool.ps1" -outputFile ".\DiskCleanupTool.exe" -noConsole -requireAdmin
```

## 🎯 Usage

1. **Run the tool** - Double-click `DiskCleanupTool.bat` or `DiskCleanupTool.exe`
2. **Grant Admin access** - Click "Yes" on the UAC prompt
3. **Select options** - Check the cleanup options you want
4. **Start cleanup** - Click "Start Cleanup"
5. **Wait** - The tool will clean selected items (DISM may take 10-30 minutes)
6. **Done!** - View the results with space freed

## ⚠️ Disabling Windows Update

**Warning:** Disabling Windows Update means you will NOT receive security patches. Your system will be vulnerable to security threats. Only use this on offline/air-gapped systems.

To re-enable Windows Update:

```powershell
# Run as Administrator
net start wuauserv
net start UsoSvc
net start WaaSMedicSvc

# Remove blocked hosts
notepad C:\Windows\System32\drivers\etc\hosts
# Delete the lines with "Windows Update blocked"
```

## 📁 Project Structure

```
DiskCleanupTool/
├── DiskCleanupTool.ps1    # Main PowerShell script with GUI
├── DiskCleanupTool.bat    # Batch file launcher
├── build_exe.ps1          # Script to build EXE
├── README.md              # This file
├── LICENSE                # MIT License
└── .gitignore            # Git ignore file
```

## 🔧 Troubleshooting

### "Running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### GUI doesn't appear

Make sure .NET Framework 4.5+ is installed:

```powershell
# Check .NET version
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' | Get-ItemPropertyValue -Name Release
```

### "Access denied" errors

Make sure to run as Administrator. Right-click the file and select "Run as administrator".

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with PowerShell and Windows Forms
- Uses PS2EXE for executable creation
- Inspired by the need for a comprehensive Windows cleanup tool

## ⚠️ Disclaimer

This tool is provided "as is", without warranty of any kind. Use at your own risk. Always backup important data before running cleanup tools.

## 📞 Support

For issues, questions, or contributions, please visit:
- GitHub: https://github.com/chibuenyim/DiskCleanupTool
- Issues: https://github.com/chibuenyim/DiskCleanupTool/issues

## 🌟 Star History

If you find this tool helpful, please consider giving it a star ⭐

---

Made with ❤️ by [chibuenyim](https://github.com/chibuenyim)
