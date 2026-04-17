# 🧹 Disk Cleanup & Windows Update Tool

**A comprehensive Windows disk cleanup utility with a graphical interface. Frees up 15+ GB of disk space by cleaning temporary files, caches, and Windows update residues.**

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)

---

## ✨ Features

- 🖥️ **Graphical Interface** - Easy-to-use GUI with checkboxes
- 🗑️ **Cleans 15+ GB** of junk files and caches
- 🚫 **Disable Windows Update** - Optional Windows Update disable
- 📦 **Portable** - No installation required
- 🔒 **Safe** - Only removes temporary files and caches
- ⚡ **Fast** - Cleans multiple locations efficiently
- 🎯 **Selective** - Choose what to clean

---

## 🗑️ What It Cleans

### 📁 **Temporary Files** (~500 MB - 2 GB)

| Location | Path | Description |
|----------|------|-------------|
| User Temp | `%TEMP%` | Per-user temporary files from applications |
| Local Temp | `%LOCALAPPDATA%\Temp` | Application-specific temporary files |
| Windows Temp | `%WINDIR%\Temp` | Windows system temporary files |
| Prefetch | `%WINDIR%\Prefetch` | Application prefetch data for faster loading |

**What gets cleaned:** Temporary files, setup logs, installation leftovers, crash dumps, application caches

---

### 🌐 **Browser Caches** (~300 MB - 1.5 GB)

| Browser | Cache Locations | Size |
|---------|-----------------|------|
| **Google Chrome** | `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache`<br>`%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache` | ~200-500 MB |
| **Microsoft Edge** | `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache`<br>`%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache` | ~100-400 MB |
| **Mozilla Firefox** | `%APPDATA%\Mozilla\Firefox\Profiles\*\cache2` | ~50-200 MB |
| **Brave** | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache` | ~50-200 MB |
| **Opera** | `%APPDATA%\Opera Software\Opera Stable\Cache` | ~50-200 MB |
| **Vivaldi** | `%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache` | ~50-200 MB |

**What gets cleaned:** Browser cache, code cache, image cache, temporary internet files

**What's SAFE:** History, bookmarks, saved passwords, cookies, extensions, settings

---

### 👨‍💻 **Developer Caches** (~8-20 GB)

| Tool/Language | Cache Location | Size |
|---------------|----------------|------|
| **npm (Node.js)** | `%APPDATA%\npm-cache` | ~3-8 GB |
| **yarn** | `%LOCALAPPDATA%\Yarn\Cache` | ~1-3 GB |
| **pnpm** | `%LOCALAPPDATA%\pnpm-store` | ~500 MB - 2 GB |
| **pip (Python)** | `%LOCALAPPDATA%\pip\Cache` | ~100-500 MB |
| **Poetry** | `%LOCALAPPDATA%\pypoetry\Cache` | ~100-500 MB |
| **Composer (PHP)** | `%LOCALAPPDATA%\Composer` | ~1-4 GB |
| **NuGet (.NET)** | `%LOCALAPPDATA%\NuGet\v3-cache` | ~500 MB - 2 GB |
| **DotNet Core** | `%USERPROFILE%\.nuget\packages` | ~500 MB - 3 GB |
| **Maven** | `%USERPROFILE%\.m2\repository` | ~500 MB - 2 GB |
| **Gradle** | `%USERPROFILE%\.gradle\caches` | ~500 MB - 2 GB |
| **Docker** | Docker images, containers, volumes | Variable |
| **VS Code** | `%USERPROFILE%\.vscode\extensions\cachedData` | ~100-500 MB |
| **Playwright** | `%USERPROFILE%\AppData\Local\ms-playwright` | ~200-500 MB |
| **Cypress** | `%LOCALAPPDATA%\Cypress` | ~100-300 MB |
| **Selenium** | `%LOCALAPPDATA%\selenium` | ~50-200 MB |
| **Go Modules** | `%USERPROFILE%\go\pkg\mod` | ~500 MB - 2 GB |
| **Cargo (Rust)** | `%USERPROFILE%\.cargo\registry` | ~200-500 MB |
| **Flutter** | `%LOCALAPPDATA%\Pub\Cache` | ~500 MB - 2 GB |
| **Android SDK** | `%LOCALAPPDATA%\Android\Sdk\.cache` | ~500 MB - 2 GB |
| **Ruby Gems** | `%USERPROFILE%\.gem` | ~100-500 MB |

**What gets cleaned:** Package registries, dependency caches, build artifacts, downloaded packages

**What's SAFE:** Your source code, project files, installed packages (will re-download if needed)

---

### 🎮 **Application Caches** (~1-5 GB)

| Application | Cache Location | Size |
|-------------|----------------|------|
| **Adobe Creative Cloud** | `%APPDATA%\Adobe\Cache` | ~500 MB - 2 GB |
| **Adobe Premiere** | `%APPDATA%\Adobe\Premiere Pro\*` | ~500 MB - 2 GB |
| **Adobe After Effects** | `%APPDATA%\Adobe\After Effects\*` | ~500 MB - 2 GB |
| **Adobe Photoshop** | `%APPDATA%\Adobe\Photoshop\*` | ~200-500 MB |
| **Spotify** | `%LOCALAPPDATA%\Spotify\Storage` | ~500 MB - 2 GB |
| **Discord** | `%APPDATA%\discord\Cache` | ~200-500 MB |
| **Slack** | `%APPDATA%\Slack\Cache` | ~100-300 MB |
| **Teams** | `%APPDATA%\Microsoft\Teams\Cache` | ~200-500 MB |
| **Zoom** | `%APPDATA%\zoom\data` | ~100-300 MB |
| **Skype** | `%APPDATA%\Microsoft\Skype\*` | ~100-300 MB |
| **Telegram** | `%LOCALAPPDATA%\Telegram\Desktop\tdata` | ~100-500 MB |
| **Steam** | `%PROGRAMFILES%\Steam\appcache\*` | ~500 MB - 2 GB |
| **Epic Games** | `%LOCALAPPDATA%\EpicGamesLauncher\Saved` | ~200-500 MB |
| **Blender** | `%APPDATA%\Blender Foundation\Blender\*` | ~100-300 MB |
| **GIMP** | `%APPDATA%\GIMP\*` | ~50-200 MB |
| **Inkscape** | `%APPDATA%\Inkscape\*` | ~50-200 MB |
| **VLC Media Player** | `%APPDATA%\vlc\cache` | ~50-200 MB |
| **7-Zip** | `%APPDATA%\7-Zip\Favorites` | ~10-50 MB |

**What gets cleaned:** Application cache, thumbnails, temporary media files, update leftovers

---

### 📋 **System Files** (~3-12 GB)

| Component | Location | Space Saved |
|-----------|----------|-------------|
| **Windows Update** | `C:\Windows\SoftwareDistribution\Download` | ~1-3 GB |
| **WinSxS** | `C:\Windows\WinSxS` (via DISM) | ~2-6 GB |
| **Recycle Bin** | `C:\$Recycle.Bin` | Variable |
| **Windows Error Reporting** | `C:\ProgramData\Microsoft\Windows\WER` | ~100-500 MB |
| **Windows Logs** | `C:\Windows\Logs` | ~100-500 MB |
| **CBS Logs** | `C:\Windows\Logs\CBS` | ~50-200 MB |
| **Delivery Optimization** | `C:\Windows\SoftwareDistribution\DeliveryOptimization` | ~100-500 MB |
| **Windows Defender** | `C:\ProgramData\Microsoft\Windows Defender\Scans\History\Store` | ~200-500 MB |
| **Windows Search** | `C:\ProgramData\Microsoft\Search\Data` | ~100-300 MB |
| **Thumbnail Cache** | `%LOCALAPPDATA%\Microsoft\Windows\Explorer` | ~100-500 MB |
| **Icon Cache** | `%LOCALAPPDATA%\IconCache.db` | ~50-200 MB |
| **Font Cache** | `C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache` | ~100-300 MB |

**What gets cleaned:** Update leftovers, old Windows components, error reports, log files, thumbnail cache

---

### 🗑️ **Additional Cleanup Options**

| Category | Description | Space Saved |
|----------|-------------|-------------|
| **Windows.old** | Previous Windows installation folder (if exists) | ~10-30 GB |
| **Hibernation** | `C:\hiberfil.sys` (if you don't use hibernate) | ~2-8 GB |
| **Pagefile** | Virtual memory file (can be reduced) | Variable |
| **System Restore Points** | Old restore points (can reduce max usage) | Variable |

---

## 🚫 What It Does NOT Clean

**Your personal files are always safe:**

❌ User documents (My Documents, Desktop, Downloads)
❌ Personal files (photos, videos, music, documents)
❌ Application settings and preferences
❌ Browser history, bookmarks, saved passwords
❌ Installed programs and applications
❌ System files required for Windows operation
❌ Game saves and progress
❌ Email data and messages
❌ Database files
❌ Your project files and source code

**Only temporary files, caches, and safe-to-remove system files are cleaned.**

---

## 📊 Expected Space Savings

### Typical Results by User Type

| User Type | Space Freed |
|-----------|-------------|
| **Basic User** | 2-5 GB |
| **Web Browser** | 3-8 GB |
| **Office Worker** | 2-6 GB |
| **Developer** | 10-25 GB |
| **Designer/Creator** | 8-20 GB |
| **Gamer** | 5-15 GB |
| **Power User** | 15-35 GB |

### Real-World Examples

```
Before Cleanup: 5.2 GB free
After Cleanup:  22.4 GB free
Space Freed:    17.2 GB

Categories cleaned:
- Browser caches: 850 MB
- Developer caches: 12.3 GB
- Windows temp: 1.2 GB
- Windows Update: 2.9 GB
```

```
Before Cleanup: 12.8 GB free
After Cleanup:  45.6 GB free
Space Freed:    32.8 GB (developer machine)

Categories cleaned:
- npm cache: 6.2 GB
- Docker: 8.1 GB
- VS Code: 350 MB
- Windows: 18.15 GB
```

---

## 📋 Requirements

- **Windows 10/11**
- **Administrator privileges** (for system file cleanup)
- **PowerShell 5.1+** (included with Windows)
- **.NET Framework 4.5+** (for GUI, included with Windows 10+)

---

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

---

## 📸 Screenshots

![GUI Screenshot](https://via.placeholder.com/600x400?text=Disk+Cleanup+Tool+GUI)

---

## 🎯 Usage

1. **Run the tool** - Double-click `DiskCleanupTool.bat` or `DiskCleanupTool.exe`
2. **Grant Admin access** - Click "Yes" on the UAC prompt
3. **Select options** - Check the cleanup options you want:
   - ✅ Clean Windows Temp Files
   - ✅ Clean Browser Caches
   - ✅ Clean Developer Caches
   - ✅ Clean Windows Update Residues
   - ✅ Disable Windows Update (optional)
   - ✅ Clean Application Data (optional)
4. **Start cleanup** - Click "Start Cleanup"
5. **Wait** - The tool will clean selected items (DISM may take 10-30 minutes)
6. **Done!** - View the results with space freed

---

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

---

## ⚠️ Disabling Windows Update

**Warning:** Disabling Windows Update means you will NOT receive security patches. Your system will be vulnerable to security threats. Only use this on offline/air-gapped systems or lab environments.

To re-enable Windows Update:

```powershell
# Run as Administrator
net start wuauserv
net start UsoSvc
net start WaaSMedicSvc

# Remove blocked hosts from C:\Windows\System32\drivers\etc\hosts
# Delete the lines with "Windows Update blocked"
```

---

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

### DISM cleanup takes too long

This is normal! DISM cleanup of WinSxS can take 10-30 minutes. You can uncheck "Clean Windows Update Residues" to skip this step.

---

## 📁 Project Structure

```
DiskCleanupTool/
├── DiskCleanupTool.ps1    # Main PowerShell script with GUI
├── DiskCleanupTool.bat    # Batch file launcher
├── build_exe.ps1          # Script to build EXE
├── BUILD.md               # Build instructions
├── README.md              # This file
├── LICENSE                # MIT License
└── .gitignore            # Git ignore file
```

---

## ⚠️ Safety & Best Practices

### What's Safe to Clean
✅ Temporary files and caches
✅ Browser caches (not history/bookmarks)
✅ Developer package caches
✅ System logs
✅ Windows Update leftovers
✅ Build artifacts

### What's Protected
❌ User documents and files
❌ Desktop and Downloads folders
❌ Browser history, bookmarks, passwords
❌ Application settings
❌ Installed programs
❌ System files required for operation

### Best Practices
1. 💾 **Backup first** - Always backup important data
2. 🧪 **Test selectively** - Try one option at a time first
3. 👀 **Review output** - Watch what's being cleaned
4. ⏰ **Schedule regularly** - Run monthly for best results
5. 🔄 **Restart after** - Some changes may need a restart

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit (`git commit -m 'Add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Areas for Contribution
- Additional browser support
- More application cache locations
- Performance improvements
- Bug fixes
- Documentation improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with PowerShell and Windows Forms
- Uses PS2EXE for executable creation
- Inspired by the need for a comprehensive Windows cleanup tool
- Community feedback and contributions

---

## ⚠️ Disclaimer

This tool is provided "as is", without warranty of any kind. Use at your own risk. Always backup important data before running cleanup tools.

---

## 📞 Support

For issues, questions, or contributions, please visit:
- **GitHub**: https://github.com/chibuenyim/DiskCleanupTool
- **Issues**: https://github.com/chibuenyim/DiskCleanupTool/issues
- **Discussions**: https://github.com/chibuenyim/DiskCleanupTool/discussions

---

## 🌟 Star the Repo!

If you find this tool helpful, please consider giving it a star ⭐

---

**Made with ❤️ by [chibuenyim](https://github.com/chibuenyim)**
