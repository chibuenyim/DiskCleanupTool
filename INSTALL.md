# 📥 Installation Guide

## 🪟 Windows

### Option 1: Download ZIP (Easiest)

1. Go to: https://github.com/chibuenyim/DiskCleanupTool/releases
2. Download `DiskCleanupTool-v4.0.zip`
3. Extract to any folder (e.g., `C:\Tools\DiskCleanupTool`)
4. Double-click `START.bat`

That's it! No installation needed.

### Option 2: Clone Repository

```bash
git clone https://github.com/chibuenyim/DiskCleanupTool.git
cd DiskCleanupTool
START.bat
```

### Option 3: Build EXE (Optional)

```powershell
# Run as Administrator
.\build_exe.ps1

# This creates DiskCleanupTool.exe
# Place it anywhere and run it!
```

---

## 🍎 macOS

### Option 1: Homebrew (Easiest)

```bash
# Install PowerShell
brew install powershell

# Clone the tool
git clone https://github.com/chibuenyim/UniversalDiskCleanupTool.git
cd UniversalDiskCleanupTool

# Make executable
chmod +x start.sh

# Run!
./start.sh
```

### Option 2: Manual Download

1. Go to: https://github.com/chibuenyim/UniversalDiskCleanupTool/releases
2. Download `UniversalDiskCleanupTool-macOS.zip`
3. Extract to any folder
4. Open Terminal, navigate to folder
5. Run: `./start.sh`

### Create Desktop Shortcut (Optional)

```bash
# Create alias
echo 'alias diskcleanup="cd ~/Tools/UniversalDiskCleanupTool && ./start.sh"' >> ~/.zshrc
source ~/.zshrc

# Now just type: diskcleanup
```

---

## 🐧 Linux

### Option 1: Clone Repository

```bash
# Install PowerShell first

# Ubuntu/Debian:
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Fedora:
sudo dnf install -y powershell

# Arch:
yay -S powershell

# Clone the tool
git clone https://github.com/chibuenyim/UniversalDiskCleanupTool.git
cd UniversalDiskCleanupTool

# Make executable
chmod +x start.sh

# Run!
./start.sh
```

### Option 2: Manual Download

1. Go to: https://github.com/chibuenyim/UniversalDiskCleanupTool/releases
2. Download `UniversalDiskCleanupTool-Linux.tar.gz`
3. Extract: `tar -xzf UniversalDiskCleanupTool-Linux.tar.gz`
4. Navigate to folder
5. Run: `./start.sh`

### Create Command Shortcut (Optional)

```bash
# Create symlink
sudo ln -s ~/Tools/UniversalDiskCleanupTool/start.sh /usr/local/bin/diskcleanup

# Now just type: diskcleanup
```

---

## ✅ Verify Installation

### Windows:
```batch
START.bat
```
You should see the menu appear.

### macOS/Linux:
```bash
./start.sh
```
You should see the interactive menu.

---

## 🎯 First Run

1. **Launch the tool** (START.bat or ./start.sh)
2. **Choose GUI Mode** from the menu
3. **Select what to clean** (or use presets)
4. **Start cleanup**
5. **Enjoy your free space!**

---

## 📝 What Gets Installed

**Nothing permanent!** These tools are:
- ✅ Portable (no installation required)
- ✅ Self-contained (all files in one folder)
- ✅ Safe (no system modifications)
- ✅ Easy to remove (just delete the folder)

---

## 🗑️ Uninstall

Simply delete the tool folder:

```bash
# Windows
Delete C:\Tools\DiskCleanupTool

# macOS/Linux
rm -rf ~/Tools/UniversalDiskCleanupTool
```

That's it! Completely removed.

---

## 🆘 Need Help?

- **Windows Issues:** https://github.com/chibuenyim/DiskCleanupTool/issues
- **macOS/Linux Issues:** https://github.com/chibuenyim/UniversalDiskCleanupTool/issues

---

## ⭐ Quick Setup Summary

**Windows:**
1. Download ZIP
2. Extract
3. Double-click `START.bat`

**macOS:**
1. Install PowerShell: `brew install powershell`
2. Download/clone tool
3. Run: `./start.sh`

**Linux:**
1. Install PowerShell (see distro commands above)
2. Download/clone tool
3. Run: `./start.sh`

---

Made with ❤️ for easy installation
