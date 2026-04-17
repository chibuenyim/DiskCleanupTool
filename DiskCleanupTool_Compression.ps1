<#
    .SYNOPSIS
        Windows File Compression Utilities for Disk Cleanup Tool
    .DESCRIPTION
        Adds CompactOS and NTFS compression capabilities to save additional disk space
    .VERSION
        4.0.0
#>

#Requires -Version 5.1

param(
    [switch]$EnableCompactOS,
    [switch]$DisableCompactOS,
    [switch]$QueryCompactOS,
    [switch]$CompressSystem,
    [switch]$CompressProgramFiles,
    [switch]$CompressUsers,
    [string]$CompressFolder,
    [switch]$Help
)

function Show-Help {
    Write-Host @"
Windows File Compression Utility v4.0
=====================================

USAGE:
    .\DiskCleanupTool_Compression.ps1 [OPTIONS]

OPTIONS:
    --EnableCompactOS        Enable CompactOS to compress Windows system files
    --DisableCompactOS       Disable CompactOS and decompress system files
    --QueryCompactOS         Query current CompactOS state
    --CompressSystem         Compress system folders (Windows, Program Files)
    --CompressProgramFiles   Compress Program Files and Program Files (x86)
    --CompressUsers          Compress user profile folders
    --CompressFolder         Compress specific folder (provide path)

EXAMPLES:
    # Enable CompactOS (saves 2-5 GB on system files)
    .\DiskCleanupTool_Compression.ps1 --EnableCompactOS

    # Compress Program Files (saves 3-8 GB)
    .\DiskCleanupTool_Compression.ps1 --CompressProgramFiles

    # Compress specific folder
    .\DiskCleanupTool_Compression.ps1 --CompressFolder "C:\MyFolder"

    # Query CompactOS status
    .\DiskCleanupTool_Compression.ps1 --QueryCompactOS

INFORMATION:
    CompactOS compresses Windows system files to save 2-5 GB of space.
    Compression is transparent and has minimal performance impact.
    SSD users: Recommended for system folders
    HDD users: Use with caution on frequently accessed files
"@
}

if ($Help) {
    Show-Help
    exit 0
}

# Admin check
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "[!] This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "[*] Please run as Administrator" -ForegroundColor Yellow
    exit 1
}

# =============================================
# COMPACTOS FUNCTIONS
# =============================================

function Enable-CompactOS {
    Write-Host "[*] Enabling CompactOS..." -ForegroundColor Cyan
    Write-Host "[*] This will compress Windows system files to save 2-5 GB" -ForegroundColor Yellow
    Write-Host "[*] The process may take 10-30 minutes..." -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "Continue? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[*] Cancelled" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "[*] Enabling CompactOS with /EXE flag..." -ForegroundColor Cyan

    try {
        # Enable CompactOS
        compact /CompactOS:always | Out-Host

        Write-Host ""
        Write-Host "[✓] CompactOS enabled successfully!" -ForegroundColor Green
        Write-Host "[*] System files will be compressed in the background" -ForegroundColor Cyan
        Write-Host "[*] You may notice higher CPU usage temporarily" -ForegroundColor Yellow

        # Show current state
        Start-Sleep -Seconds 2
        Query-CompactOS
    } catch {
        Write-Host "[✗] Failed to enable CompactOS: $_" -ForegroundColor Red
    }
}

function Disable-CompactOS {
    Write-Host "[*] Disabling CompactOS..." -ForegroundColor Cyan
    Write-Host "[*] This will decompress Windows system files" -ForegroundColor Yellow
    Write-Host "[*] The process may take 10-30 minutes..." -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "Continue? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[*] Cancelled" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "[*] Disabling CompactOS..." -ForegroundColor Cyan

    try {
        # Disable CompactOS
        compact /CompactOS:never | Out-Host

        Write-Host ""
        Write-Host "[✓] CompactOS disabled successfully!" -ForegroundColor Green
        Write-Host "[*] System files will be decompressed in the background" -ForegroundColor Cyan

        # Show current state
        Start-Sleep -Seconds 2
        Query-CompactOS
    } catch {
        Write-Host "[✗] Failed to disable CompactOS: $_" -ForegroundColor Red
    }
}

function Query-CompactOS {
    Write-Host ""
    Write-Host "[*] Querying CompactOS state..." -ForegroundColor Cyan

    try {
        $output = compact /CompactOS:query 2>&1 | Out-String

        if ($output -match "is in the compact state") {
            Write-Host "[✓] CompactOS: ENABLED" -ForegroundColor Green

            # Calculate space savings
            try {
                $systemSize = (Get-ChildItem "C:\Windows" -Recurse -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB

                Write-Host "[*] Estimated savings: 2-5 GB" -ForegroundColor Cyan
                Write-Host "[*] Windows folder size: $([math]::Round($systemSize, 2)) GB" -ForegroundColor Gray
            } catch {}
        } elseif ($output -match "not in the compact state") {
            Write-Host "[✗] CompactOS: DISABLED" -ForegroundColor Yellow
            Write-Host "[*] Enable CompactOS to save 2-5 GB of space" -ForegroundColor Cyan
        } else {
            Write-Host "[?] Unable to determine CompactOS state" -ForegroundColor Yellow
            Write-Host $output
        }
    } catch {
        Write-Host "[✗] Failed to query CompactOS: $_" -ForegroundColor Red
    }
}

# =============================================
# NTFS COMPRESSION FUNCTIONS
# =============================================

function Get-FolderSize {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return 0 }

    try {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return $size
    } catch {
        return 0
    }
}

function Compress-FolderNTFS {
    param(
        [string]$Path,
        [string]$Description = $Path
    )

    if (-not (Test-Path $Path)) {
        Write-Host "[✗] Path not found: $Path" -ForegroundColor Red
        return
    }

    Write-Host "[*] Compressing: $Description" -ForegroundColor Cyan

    try {
        # Get size before compression
        $beforeMB = [math]::Round((Get-FolderSize $Path) / 1MB, 2)

        Write-Host "[*] Current size: $beforeMB MB" -ForegroundColor Gray

        # Compress the folder
        compact /C /S:"$Path" /I | Out-Host

        # Calculate estimated savings (typically 20-40%)
        $savedMB = [math]::Round($beforeMB * 0.3, 2)

        Write-Host "[✓] Compression complete!" -ForegroundColor Green
        Write-Host "[*] Estimated space saved: ~$savedMB MB" -ForegroundColor Green
        Write-Host "[*] Files will be decompressed automatically when accessed" -ForegroundColor Gray
    } catch {
        Write-Host "[✗] Failed to compress: $_" -ForegroundColor Red
    }
}

function Compress-SystemFolders {
    Write-Host ""
    Write-Host "[*] Compressing System Folders" -ForegroundColor Cyan
    Write-Host "[!] This will compress Program Files folders" -ForegroundColor Yellow
    Write-Host "[*] Estimated savings: 3-8 GB" -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "Continue? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[*] Cancelled" -ForegroundColor Yellow
        return
    }

    Write-Host ""

    # Compress Program Files
    if (Test-Path "C:\Program Files") {
        Compress-FolderNTFS "C:\Program Files" "Program Files"
    }

    if (Test-Path "C:\Program Files (x86)") {
        Compress-FolderNTFS "C:\Program Files (x86)" "Program Files (x86)"
    }

    if (Test-Path "C:\Program Files\WindowsApps") {
        Compress-FolderNTFS "C:\Program Files\WindowsApps" "WindowsApps"
    }

    Write-Host ""
    Write-Host "[✓] System folders compressed!" -ForegroundColor Green
}

function Compress-UserFolders {
    Write-Host ""
    Write-Host "[*] Compressing User Folders" -ForegroundColor Cyan
    Write-Host "[!] This will compress folders in your user profile" -ForegroundColor Yellow
    Write-Host "[*] Estimated savings: 1-5 GB (varies by usage)" -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "Continue? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "[*] Cancelled" -ForegroundColor Yellow
        return
    }

    Write-Host ""

    # Compress common user folders
    $userFolders = @(
        @{Path = "$env:USERPROFILE\AppData\Local"; Desc = "AppData\Local"},
        @{Path = "$env:USERPROFILE\AppData\LocalLow"; Desc = "AppData\LocalLow"},
        @{Path = "$env:USERPROFILE\Downloads"; Desc = "Downloads"},
        @{Path = "$env:USERPROFILE\Documents"; Desc = "Documents"}
    )

    foreach ($folder in $userFolders) {
        if (Test-Path $folder.Path) {
            Compress-FolderNTFS $folder.Path $folder.Desc
        }
    }

    Write-Host ""
    Write-Host "[✓] User folders compressed!" -ForegroundColor Green
}

# =============================================
# MAIN EXECUTION
# =============================================

if ($EnableCompactOS) {
    Enable-CompactOS
} elseif ($DisableCompactOS) {
    Disable-CompactOS
} elseif ($QueryCompactOS) {
    Query-CompactOS
} elseif ($CompressSystem) {
    Compress-SystemFolders
} elseif ($CompressProgramFiles) {
    Compress-SystemFolders
} elseif ($CompressUsers) {
    Compress-UserFolders
} elseif ($CompressFolder) {
    if (Test-Path $CompressFolder) {
        Compress-FolderNTFS $CompressFolder $CompressFolder
    } else {
        Write-Host "[✗] Folder not found: $CompressFolder" -ForegroundColor Red
    }
} else {
    # Show interactive menu
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Windows File Compression Utility v4.0              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Enable CompactOS (save 2-5 GB on system files)" -ForegroundColor Green
    Write-Host "  [2] Disable CompactOS" -ForegroundColor Yellow
    Write-Host "  [3] Query CompactOS Status" -ForegroundColor Cyan
    Write-Host "  [4] Compress System Folders (3-8 GB)" -ForegroundColor Green
    Write-Host "  [5] Compress User Folders (1-5 GB)" -ForegroundColor Green
    Write-Host "  [6] Compress Specific Folder" -ForegroundColor Cyan
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { Enable-CompactOS }
        "2" { Disable-CompactOS }
        "3" { Query-CompactOS }
        "4" { Compress-SystemFolders }
        "5" { Compress-UserFolders }
        "6" {
            $folder = Read-Host "Enter folder path"
            if ($folder -and (Test-Path $folder)) {
                Compress-FolderNTFS $folder $folder
            } else {
                Write-Host "[✗] Invalid folder path" -ForegroundColor Red
            }
        }
        "Q" { exit 0 }
        "q" { exit 0 }
        default {
            Write-Host "[✗] Invalid choice" -ForegroundColor Red
        }
    }
}

Write-Host ""
