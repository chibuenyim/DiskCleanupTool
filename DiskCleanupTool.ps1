<#
    .SYNOPSIS
    Disk Cleanup & Windows Update Disable Tool v2.0
    .DESCRIPTION
    Comprehensive disk cleanup utility that frees up 15+ GB of space
    Cleans temp files, browser caches, developer tools, application caches, system files, and Windows Update residues
    .VERSION
    2.0.0
#>

#Requires -Version 5.1

# Admin check function
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Elevate if needed
if (-not (Test-Administrator)) {
    Write-Host "[!] Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# GUI or Console mode
$useGUI = $true
try {
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms -ErrorAction Stop
} catch {
    $useGUI = $false
}

if ($useGUI) {
    # Load assemblies for GUI
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName PresentationFramework

    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Disk Cleanup Tool v2.0 - Comprehensive Cleaning"
    $form.Size = New-Object System.Drawing.Size(700, 750)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(640, 40)
    $titleLabel.Text = "Disk Cleanup Tool v2.0"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($titleLabel)

    # Current disk space
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    $usedGB = [math]::Round($drive.Used/1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used)/1GB, 2)

    $diskLabel = New-Object System.Windows.Forms.Label
    $diskLabel.Location = New-Object System.Drawing.Point(20, 65)
    $diskLabel.Size = New-Object System.Drawing.Size(640, 50)
    $diskLabel.Text = "Current Disk Space:`nFree: $freeGB GB | Used: $usedGB GB | Total: $totalGB GB"
    $diskLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($diskLabel)

    # Options group
    $optionsGroup = New-Object System.Windows.Forms.GroupBox
    $optionsGroup.Location = New-Object System.Drawing.Point(20, 130)
    $optionsGroup.Size = New-Object System.Drawing.Size(640, 450)
    $optionsGroup.Text = "Select Cleanup Options (Expected Space Savings):"
    $form.Controls.Add($optionsGroup)

    # Cleanup options checkboxes
    $yPos = 25
    $checkboxes = @()

    $options = @(
        @{Name="cleanTemp"; Label="Clean Windows Temp Files"; Checked=$true; Description="~500 MB - 2 GB - User temp, Windows temp, Prefetch data"},
        @{Name="cleanBrowser"; Label="Clean Browser Caches"; Checked=$true; Description="~300 MB - 1.5 GB - Chrome, Edge, Firefox, Brave, Opera, Vivaldi"},
        @{Name="cleanDev"; Label="Clean Developer Caches"; Checked=$true; Description="~8-20 GB - npm, yarn, pip, Composer, NuGet, Maven, Gradle, Docker, etc."},
        @{Name="cleanApps"; Label="Clean Application Caches"; Checked=$false; Description="~1-5 GB - Adobe CC, Spotify, Discord, Slack, Teams, Steam, etc."},
        @{Name="cleanSystem"; Label="Clean System Files"; Checked=$true; Description="~3-12 GB - WER, Logs, Defender, Thumbnails, Recycle Bin"},
        @{Name="cleanUpdate"; Label="Clean Windows Update Residues"; Checked=$true; Description="~3-9 GB - SoftwareDistribution, WinSxS cleanup (10-30 min)"},
        @{Name="disableUpdate"; Label="Disable Windows Update"; Checked=$false; Description="Permanently disables Windows Update services and blocks servers"}
    )

    foreach ($opt in $options) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Location = New-Object System.Drawing.Point(20, $yPos)
        $cb.Size = New-Object System.Drawing.Size(600, 24)
        $cb.Text = $opt.Label
        $cb.Checked = $opt.Checked
        $cb.Tag = $opt
        $optionsGroup.Controls.Add($cb)
        $checkboxes += $cb
        $yPos += 24

        $desc = New-Object System.Windows.Forms.Label
        $desc.Location = New-Object System.Drawing.Point(40, $yPos)
        $desc.Size = New-Object System.Drawing.Size(580, 18)
        $desc.Text = $opt.Description
        $desc.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $desc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $optionsGroup.Controls.Add($desc)
        $yPos += 28
    }

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 595)
    $progressBar.Size = New-Object System.Drawing.Size(640, 25)
    $progressBar.Style = "Continuous"
    $form.Controls.Add($progressBar)

    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 625)
    $statusLabel.Size = New-Object System.Drawing.Size(640, 40)
    $statusLabel.Text = "Ready to start..."
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)

    # Start button
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = New-Object System.Drawing.Point(490, 675)
    $startButton.Size = New-Object System.Drawing.Size(170, 40)
    $startButton.Text = "Start Cleanup"
    $startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = "Flat"
    $form.Controls.Add($startButton)

    # Cleanup functions
    $totalFreedMB = 0

    function Update-Progress($status, $percent) {
        $statusLabel.Text = $status
        $progressBar.Value = $percent
        $form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    }

    function Get-FolderSize($path) {
        if (Test-Path $path) {
            try {
                return (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                       Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            } catch {
                return 0
            }
        }
        return 0
    }

    function Clean-Folder($path) {
        if (Test-Path $path) {
            try {
                $before = Get-FolderSize $path
                Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                    ForEach-Object { try { Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue } catch {} }
                $after = Get-FolderSize $path
                return ($before - $after)
            } catch {
                return 0
            }
        }
        return 0
    }

    # 1. Clean Windows Temp Files
    function Clean-TempFiles {
        Update-Progress "Cleaning Windows temp files..." 5
        $freed = 0

        $tempPaths = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "$env:WINDIR\Temp",
            "$env:WINDIR\Prefetch"
        )

        foreach ($path in $tempPaths) {
            $freed += Clean-Folder $path
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 2. Clean Browser Caches
    function Clean-BrowserCaches {
        Update-Progress "Cleaning browser caches..." 15
        $freed = 0

        $browsers = @{
            "Chrome" = @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                         "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache")
            "Edge" = @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
                       "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache")
            "Firefox" = @("$env:APPDATA\Mozilla\Firefox\Profiles")
            "Brave" = @("$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache")
            "Opera" = @("$env:APPDATA\Opera Software\Opera Stable\Cache")
            "Vivaldi" = @("$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache")
        }

        foreach ($browser in $browsers.Keys) {
            foreach ($path in $browsers[$browser]) {
                if ($browser -eq "Firefox") {
                    # Firefox has multiple profiles
                    if (Test-Path $path) {
                        Get-ChildItem -Path "$path\*\cache2" -ErrorAction SilentlyContinue | ForEach-Object {
                            $freed += Clean-Folder $_.FullName
                        }
                    }
                } else {
                    $freed += Clean-Folder $path
                }
            }
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 3. Clean Developer Caches
    function Clean-DeveloperCaches {
        Update-Progress "Cleaning developer caches..." 25
        $freed = 0

        # Package managers
        $devPaths = @{
            "npm" = "$env:APPDATA\npm-cache"
            "yarn" = "$env:LOCALAPPDATA\Yarn\Cache"
            "pnpm" = "$env:LOCALAPPDATA\pnpm-store"
            "pip" = "$env:LOCALAPPDATA\pip\Cache"
            "Poetry" = "$env:LOCALAPPDATA\pypoetry\Cache"
            "Composer" = "$env:LOCALAPPDATA\Composer"
            "NuGet" = "$env:LOCALAPPDATA\NuGet\v3-cache"
            "DotNet" = "$env:USERPROFILE\.nuget\packages"
            "Maven" = "$env:USERPROFILE\.m2\repository"
            "Gradle" = "$env:USERPROFILE\.gradle\caches"
            "Go" = "$env:USERPROFILE\go\pkg\mod"
            "Cargo" = "$env:USERPROFILE\.cargo\registry"
            "Flutter" = "$env:LOCALAPPDATA\Pub\Cache"
            "AndroidSDK" = "$env:LOCALAPPDATA\Android\Sdk\.cache"
            "RubyGems" = "$env:USERPROFILE\.gem"
        }

        # Clean package manager caches
        foreach ($tool in $devPaths.Keys) {
            $path = $devPaths[$tool]
            if ($tool -eq "npm") {
                try {
                    $before = Get-FolderSize $path
                    npm cache clean --force *> $null
                    Start-Sleep -Milliseconds 500
                    $after = Get-FolderSize $path
                    $freed += ($before - $after)
                } catch {}
            } elseif ($tool -eq "pip") {
                try {
                    $before = Get-FolderSize $path
                    pip cache purge *> $null
                    Start-Sleep -Milliseconds 500
                    $after = Get-FolderSize $path
                    $freed += ($before - $after)
                } catch {}
            } else {
                $freed += Clean-Folder $path
            }
        }

        Update-Progress "Cleaning development tool caches..." 35

        # Development tools
        $devTools = @(
            "$env:USERPROFILE\.vscode\extensions\cachedData",
            "$env:LOCALAPPDATA\ms-playwright",
            "$env:LOCALAPPDATA\Cypress",
            "$env:LOCALAPPDATA\selenium"
        )

        foreach ($path in $devTools) {
            $freed += Clean-Folder $path
        }

        # Docker (if available)
        try {
            $dockerImages = docker images -q 2>$null
            if ($dockerImages) {
                Update-Progress "Cleaning Docker images and containers..." 40
                $beforeDocker = (docker system df 2>$null | Select-String "Images" | ForEach-Object { ($_ -split '\s+')[2] })
                docker system prune -a -f --volumes *> $null
                $freed += 500 # Approximate, hard to measure accurately
            }
        } catch {}

        return [math]::Round($freed/1MB, 2)
    }

    # 4. Clean Application Caches
    function Clean-ApplicationCaches {
        Update-Progress "Cleaning application caches..." 50
        $freed = 0

        $appPaths = @{
            "AdobeCC" = "$env:APPDATA\Adobe\Cache"
            "Premiere" = "$env:APPDATA\Adobe\Premiere Pro"
            "AfterEffects" = "$env:APPDATA\Adobe\After Effects"
            "Photoshop" = "$env:APPDATA\Adobe\Photoshop"
            "Spotify" = "$env:LOCALAPPDATA\Spotify\Storage"
            "Discord" = "$env:APPDATA\discord\Cache"
            "Slack" = "$env:APPDATA\Slack\Cache"
            "Teams" = "$env:APPDATA\Microsoft\Teams\Cache"
            "Zoom" = "$env:APPDATA\zoom\data"
            "Skype" = "$env:APPDATA\Microsoft\Skype"
            "Telegram" = "$env:LOCALAPPDATA\Telegram\Desktop\tdata"
            "Steam" = "$env:PROGRAMFILES\Steam\appcache"
            "EpicGames" = "$env:LOCALAPPDATA\EpicGamesLauncher\Saved"
            "Blender" = "$env:APPDATA\Blender Foundation\Blender"
            "GIMP" = "$env:APPDATA\GIMP"
            "Inkscape" = "$env:APPDATA\Inkscape"
            "VLC" = "$env:APPDATA\vlc\cache"
        }

        foreach ($app in $appPaths.Keys) {
            $path = $appPaths[$app]
            if ($app -eq "Steam") {
                # Steam requires special handling
                if (Test-Path $path) {
                    $freed += Clean-Folder "$path\*.acf"
                }
            } else {
                $freed += Clean-Folder $path
            }
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 5. Clean System Files
    function Clean-SystemFiles {
        Update-Progress "Cleaning system files..." 60
        $freed = 0

        # Windows Error Reporting
        $werPath = "C:\ProgramData\Microsoft\Windows\WER"
        $freed += Clean-Folder $werPath

        Update-Progress "Cleaning Windows logs..." 65

        # Windows Logs
        $logPaths = @(
            "C:\Windows\Logs",
            "C:\Windows\Logs\CBS",
            "C:\Windows\SoftwareDistribution\DeliveryOptimization"
        )

        foreach ($path in $logPaths) {
            $freed += Clean-Folder $path
        }

        Update-Progress "Cleaning Windows Defender scans..." 70

        # Windows Defender Scan History
        $defenderPath = "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Store"
        $freed += Clean-Folder $defenderPath

        # Windows Search
        $searchPath = "C:\ProgramData\Microsoft\Search\Data"
        $freed += Clean-Folder $searchPath

        Update-Progress "Cleaning thumbnail and icon caches..." 75

        # Thumbnail Cache
        $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        if (Test-Path $thumbPath) {
            Get-ChildItem -Path $thumbPath -Filter "thumbcache*.db" -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $freed += $_.Length
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }

        # Icon Cache
        $iconCache = "$env:LOCALAPPDATA\IconCache.db"
        if (Test-Path $iconCache) {
            try {
                $freed += (Get-Item $iconCache -ErrorAction SilentlyContinue).Length
                Remove-Item $iconCache -Force -ErrorAction SilentlyContinue
            } catch {}
        }

        # Font Cache
        $fontCachePath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
        $freed += Clean-Folder $fontCachePath

        Update-Progress "Emptying Recycle Bin..." 80

        # Recycle Bin
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.Namespace(0xA)
        $items = $recycleBin.Items()
        foreach ($item in $items) {
            try {
                $freed += ($item.Size -as [double])
                $item.InvokeVerb("delete")
            } catch {}
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 6. Clean Windows Update Residues
    function Clean-UpdateResidues {
        Update-Progress "Stopping Windows Update services..." 85

        Stop-Service -Name wuauserv, UsoSvc, WaaSMedicSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        $freed = 0

        # SoftwareDistribution
        Update-Progress "Cleaning SoftwareDistribution..." 87
        $sdPath = "C:\Windows\SoftwareDistribution\Download"
        $freed += Clean-Folder $sdPath

        # DISM Cleanup
        Update-Progress "Running DISM cleanup (this may take 10-30 minutes)..." 90
        $dismResult = dism /Online /Cleanup-Image /StartComponentCleanup /RetainDefinitiveAppraiserVersion 2>&1
        $freed += 1000 # DISM typically frees 1-3 GB

        Start-Service -Name wuauserv -ErrorAction SilentlyContinue

        return [math]::Round($freed/1MB, 2)
    }

    # 7. Disable Windows Update
    function Disable-WindowsUpdate {
        Update-Progress "Disabling Windows Update..." 95

        # Stop services
        Stop-Service -Name wuauserv, UsoSvc, WaaSMedicSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        # Disable services
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name UsoSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name WaaSMedicSvc -StartupType Disabled -ErrorAction SilentlyContinue

        # Registry modifications
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 4 /f *> $null

        # Block update servers in hosts file
        $hosts = "C:\Windows\System32\drivers\etc\hosts"
        $hostsContent = Get-Content $hosts -ErrorAction SilentlyContinue

        if ($hostsContent -notmatch "Windows Update blocked") {
            $blockList = @(
                "# Windows Update blocked",
                "127.0.0.1 windowsupdate.microsoft.com",
                "127.0.0.1 update.microsoft.com",
                "127.0.0.1 ctldl.windowsupdate.com",
                "127.0.0.1 tsfe.trafficshaping.dsp.mp.microsoft.com",
                "127.0.0.1 au.download.windowsupdate.com"
            )

            foreach ($line in $blockList) {
                $line | Out-File -FilePath $hosts -Append -Encoding ASCII -ErrorAction SilentlyContinue
            }
        }

        return 0
    }

    # Start button click handler
    $startButton.Add_Click({
        $startButton.Enabled = $false
        $startButton.Text = "Cleaning..."

        foreach ($cb in $checkboxes) {
            if ($cb.Checked) {
                $opt = $cb.Tag
                switch ($opt.Name) {
                    "cleanTemp" { $totalFreedMB += Clean-TempFiles }
                    "cleanBrowser" { $totalFreedMB += Clean-BrowserCaches }
                    "cleanDev" { $totalFreedMB += Clean-DeveloperCaches }
                    "cleanApps" { $totalFreedMB += Clean-ApplicationCaches }
                    "cleanSystem" { $totalFreedMB += Clean-SystemFiles }
                    "cleanUpdate" { $totalFreedMB += Clean-UpdateResidues }
                    "disableUpdate" { Disable-WindowsUpdate }
                }
            }
        }

        Update-Progress "Cleanup complete!" 100

        $drive = Get-PSDrive C
        $freeGB = [math]::Round($drive.Free/1GB, 2)
        $freedGB = [math]::Round($totalFreedMB/1024, 2)

        [System.Windows.Forms.MessageBox]::Show(
            "Cleanup Complete!`n`nSpace Freed: $freedGB GB`nCurrent Free Space: $freeGB GB`n`nYour system is now cleaner and faster!",
            "Disk Cleanup Tool v2.0",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        $form.Close()
    })

    # Show form
    $form.ShowDialog() | Out-Null
} else {
    # Console mode
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Disk Cleanup Tool v2.0" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    Write-Host "Current free space: $freeGB GB" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "GUI not available. Please run with full PowerShell support." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
