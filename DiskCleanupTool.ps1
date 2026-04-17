<#
    .SYNOPSIS
    Disk Cleanup & Windows Update Tool v4.0
    .DESCRIPTION
    Comprehensive disk cleanup utility with advanced features
    Cleans temp files, browser caches, developer tools, application caches, system files, and Windows Update residues
    .VERSION
    4.0.0
#>

#Requires -Version 5.1

param(
    [switch]$DryRun,
    [switch]$ScanOnly,
    [string]$ConfigFile,
    [switch]$ExportSettings,
    [switch]$ImportSettings,
    [switch]$Schedule,
    [switch]$Verbose
)

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

# Configuration management
$script:Config = @{
    Version = "4.0.0"
    LastRun = $null
    TotalCleaned = 0
    ScanResults = @{}
    LogFile = "$env:TEMP\DiskCleanupTool.log"
    MaxLogSize = 10MB
}

# Load configuration
function Load-Config {
    param([string]$Path)

    if (Test-Path $Path) {
        try {
            $configData = Get-Content $Path | ConvertFrom-Json
            $script:Config = $configData
            Write-Host "[+] Configuration loaded from $Path" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[!] Failed to load configuration" -ForegroundColor Red
            return $false
        }
    }
    return $false
}

# Save configuration
function Save-Config {
    param([string]$Path)

    try {
        $script:Config.LastRun = Get-Date
        $script:Config | ConvertTo-Json | Set-Content $Path
        Write-Host "[+] Configuration saved to $Path" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to save configuration" -ForegroundColor Red
    }
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console with color
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        default { Write-Host $logEntry }
    }

    # Write to log file
    try {
        $logEntry | Out-File -FilePath $script:Config.LogFile -Append -ErrorAction Stop

        # Rotate log if too large
        if ((Get-Item $script:Config.LogFile).Length -gt 10MB) {
            $archivePath = "$script:Config.LogFile.old"
            Move-Item -Path $script:Config.LogFile -Destination $archivePath -Force
            Start-Sleep -Milliseconds 100
        }
    } catch {
        # Silently fail if logging fails
    }
}

# Get folder size safely
function Get-FolderSizeSafe {
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

# Clean folder safely
function Remove-FolderSafe {
    param(
        [string]$Path,
        [string]$Description = $Path
    )

    if (-not (Test-Path $Path)) {
        Write-Log "Skipping $Description (not found)" "INFO"
        return 0
    }

    $before = Get-FolderSizeSafe $Path

    if ($ScanOnly) {
        $script:Config.ScanResults[$Description] = $before
        Write-Log "[$Description] Would free: $([math]::Round($before/1MB, 2)) MB" "INFO"
        return 0
    }

    if ($DryRun) {
        Write-Log "[DRY RUN] Would clean: $Description ($([math]::Round($before/1MB, 2)) MB)" "WARNING"
        return 0
    }

    try {
        Write-Log "Cleaning: $Description..." "INFO"
        Remove-Item -Path "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
        $after = Get-FolderSizeSafe $Path
        $freed = $before - $after

        Write-Log "Freed from $Description`: $([math]::Round($freed/1MB, 2)) MB" "SUCCESS"
        return $freed
    } catch {
        Write-Log "Failed to clean $Description`: $_" "ERROR"
        return 0
    }
}

# Schedule cleanup task
function Register-ScheduledCleanup {
    Write-Log "Registering scheduled cleanup task..." "INFO"

    $taskName = "DiskCleanupTool"
    $scriptPath = $PSCommandPath

    try {
        # Check if task exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

        if ($existingTask) {
            Write-Log "Task already exists. Updating..." "INFO"
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        # Create new task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -All"

        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Description "Weekly disk cleanup"

        Write-Log "Scheduled task registered successfully!" "SUCCESS"
        Write-Log "Task will run weekly on Sundays at 2:00 AM" "INFO"
    } catch {
        Write-Log "Failed to register scheduled task: $_" "ERROR"
    }
}

# Export settings
function Export-Settings {
    $settingsPath = "$env:USERPROFILE\DiskCleanupTool_Settings.json"

    $settings = @{
        Version = $script:Config.Version
        ExportDate = Get-Date
        DefaultOptions = @{
            CleanTemp = $true
            CleanBrowser = $true
            CleanDev = $true
            CleanApps = $false
            CleanSystem = $true
            CleanUpdate = $true
            DisableUpdate = $false
        }
    }

    try {
        $settings | ConvertTo-Json | Set-Content $settingsPath
        Write-Log "Settings exported to: $settingsPath" "SUCCESS"
    } catch {
        Write-Log "Failed to export settings: $_" "ERROR"
    }
}

# Import settings
function Import-Settings {
    $settingsPath = "$env:USERPROFILE\DiskCleanupTool_Settings.json"

    if (-not (Test-Path $settingsPath)) {
        Write-Log "Settings file not found: $settingsPath" "ERROR"
        return $false
    }

    try {
        $settings = Get-Content $settingsPath | ConvertFrom-Json
        Write-Log "Settings imported successfully!" "SUCCESS"
        Write-Log "Imported: $($settings.DefaultOptions | Out-String)" "INFO"
        return $true
    } catch {
        Write-Log "Failed to import settings: $_" "ERROR"
        return $false
    }
}

# Handle command-line switches
if ($ExportSettings) {
    Export-Settings
    exit 0
}

if ($ImportSettings) {
    Import-Settings
    exit 0
}

if ($Schedule) {
    Register-ScheduledCleanup
    exit 0
}

if ($ConfigFile) {
    Load-Config $ConfigFile
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
    $form.Text = "Disk Cleanup Tool v4.0 - Advanced Features"
    $form.Size = New-Object System.Drawing.Size(750, 850)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(690, 40)
    $titleLabel.Text = "Disk Cleanup Tool v4.0"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($titleLabel)

    # Current disk space
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    $usedGB = [math]::Round($drive.Used/1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used)/1GB, 2)

    $diskLabel = New-Object System.Windows.Forms.Label
    $diskLabel.Location = New-Object System.Drawing.Point(20, 65)
    $diskLabel.Size = New-Object System.Drawing.Size(690, 50)
    $diskLabel.Text = "Current Disk Space:`nFree: $freeGB GB | Used: $usedGB GB | Total: $totalGB GB"
    $diskLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($diskLabel)

    # Options group
    $optionsGroup = New-Object System.Windows.Forms.GroupBox
    $optionsGroup.Location = New-Object System.Drawing.Point(20, 130)
    $optionsGroup.Size = New-Object System.Drawing.Size(340, 520)
    $optionsGroup.Text = "Select Cleanup Options:"
    $form.Controls.Add($optionsGroup)

    # Cleanup options checkboxes
    $yPos = 25
    $checkboxes = @()

    $options = @(
        @{Name="cleanTemp"; Label="Clean Windows Temp Files"; Checked=$true; Description="~500 MB - 2 GB"},
        @{Name="cleanPrefetch"; Label="Clean Prefetch Cache"; Checked=$true; Description="~50-200 MB"},
        @{Name="cleanBrowser"; Label="Clean Browser Caches"; Checked=$true; Description="~300 MB - 1.5 GB"},
        @{Name="cleanDev"; Label="Clean Developer Caches"; Checked=$true; Description="~8-20 GB"},
        @{Name="cleanApps"; Label="Clean Application Caches"; Checked=$false; Description="~1-5 GB"},
        @{Name="cleanSystem"; Label="Clean System Files"; Checked=$true; Description="~3-12 GB"},
        @{Name="cleanWindowsOld"; Label="Clean Windows.old"; Checked=$false; Description="~10-30 GB"},
        @{Name="cleanHiber"; Label="Remove Hibernation File"; Checked=$false; Description="~2-8 GB"},
        @{Name="cleanUpdate"; Label="Clean Windows Update Residues"; Checked=$true; Description="~3-9 GB"},
        @{Name="disableUpdate"; Label="Disable Windows Update"; Checked=$false; Description="Permanent"}
    )

    foreach ($opt in $options) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Location = New-Object System.Drawing.Point(20, $yPos)
        $cb.Size = New-Object System.Drawing.Size(300, 24)
        $cb.Text = $opt.Label
        $cb.Checked = $opt.Checked
        $cb.Tag = $opt
        $optionsGroup.Controls.Add($cb)
        $checkboxes += $cb

        $desc = New-Object System.Windows.Forms.Label
        $desc.Location = New-Object System.Drawing.Point(40, $yPos + 20)
        $desc.Size = New-Object System.Drawing.Size(280, 18)
        $desc.Text = $opt.Description
        $desc.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $desc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $optionsGroup.Controls.Add($desc)
        $yPos += 48
    }

    # Advanced options group
    $advancedGroup = New-Object System.Windows.Forms.GroupBox
    $advancedGroup.Location = New-Object System.Drawing.Point(380, 130)
    $advancedGroup.Size = New-Object System.Drawing.Size(340, 200)
    $advancedGroup.Text = "Advanced Options:"
    $form.Controls.Add($advancedGroup)

    # Dry run checkbox
    $dryRunCheck = New-Object System.Windows.Forms.CheckBox
    $dryRunCheck.Location = New-Object System.Drawing.Point(20, 30)
    $dryRunCheck.Size = New-Object System.Drawing.Size(300, 24)
    $dryRunCheck.Text = "Dry Run (scan only, no changes)"
    $advancedGroup.Controls.Add($dryRunCheck)

    # Scan only checkbox
    $scanOnlyCheck = New-Object System.Windows.Forms.CheckBox
    $scanOnlyCheck.Location = New-Object System.Drawing.Point(20, 60)
    $scanOnlyCheck.Size = New-Object System.Drawing.Size(300, 24)
    $scanOnlyCheck.Text = "Scan Only (preview results)"
    $advancedGroup.Controls.Add($scanOnlyCheck)

    # Create restore point
    $restorePointCheck = New-Object System.Windows.Forms.CheckBox
    $restorePointCheck.Location = New-Object System.Drawing.Point(20, 90)
    $restorePointCheck.Size = New-Object System.Drawing.Size(300, 24)
    $restorePointCheck.Text = "Create System Restore Point"
    $restorePointCheck.Checked = $true
    $advancedGroup.Controls.Add($restorePointCheck)

    # Verbose logging
    $verboseCheck = New-Object System.Windows.Forms.CheckBox
    $verboseCheck.Location = New-Object System.Drawing.Point(20, 120)
    $verboseCheck.Size = New-Object System.Drawing.Size(300, 24)
    $verboseCheck.Text = "Verbose Logging"
    $advancedGroup.Controls.Add($verboseCheck)

    # Export/Import buttons
    $exportBtn = New-Object System.Windows.Forms.Button
    $exportBtn.Location = New-Object System.Drawing.Point(20, 155)
    $exportBtn.Size = New-Object System.Drawing.Size(100, 30)
    $exportBtn.Text = "Export Settings"
    $exportBtn.Add_Click({ Export-Settings })
    $advancedGroup.Controls.Add($exportBtn)

    $importBtn = New-Object System.Windows.Forms.Button
    $importBtn.Location = New-Object System.Drawing.Point(130, 155)
    $importBtn.Size = New-Object System.Drawing.Size(100, 30)
    $importBtn.Text = "Import Settings"
    $importBtn.Add_Click({ Import-Settings })
    $advancedGroup.Controls.Add($importBtn)

    # Schedule button
    $scheduleBtn = New-Object System.Windows.Forms.Button
    $scheduleBtn.Location = New-Object System.Drawing.Point(240, 155)
    $scheduleBtn.Size = New-Object System.Drawing.Size(80, 30)
    $scheduleBtn.Text = "Schedule"
    $scheduleBtn.Add_Click({ Register-ScheduledCleanup })
    $advancedGroup.Controls.Add($scheduleBtn)

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 665)
    $progressBar.Size = New-Object System.Drawing.Size(700, 25)
    $progressBar.Style = "Continuous"
    $form.Controls.Add($progressBar)

    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 695)
    $statusLabel.Size = New-Object System.Drawing.Size(700, 40)
    $statusLabel.Text = "Ready to start..."
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)

    # Results textbox
    $resultsBox = New-Object System.Windows.Forms.TextBox
    $resultsBox.Location = New-Object System.Drawing.Point(380, 350)
    $resultsBox.Size = New-Object System.Drawing.Size(340, 280)
    $resultsBox.Multiline = $true
    $resultsBox.ScrollBars = "Vertical"
    $resultsBox.ReadOnly = $true
    $resultsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $form.Controls.Add($resultsBox)

    # Cleanup functions
    $totalFreedMB = 0

    function Update-Progress($status, $percent) {
        $statusLabel.Text = $status
        $progressBar.Value = $percent
        $form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        if ($verboseCheck.Checked) {
            $resultsBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $status`r`n")
        }
    }

    # 1. Clean Windows Temp Files
    function Clean-TempFiles {
        Update-Progress "Cleaning Windows temp files..." 10
        $freed = 0

        $tempPaths = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "$env:WINDIR\Temp"
        )

        foreach ($path in $tempPaths) {
            $freed += Remove-FolderSafe $path "Temp Files"
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 2. Clean Prefetch
    function Clean-Prefetch {
        Update-Progress "Cleaning Prefetch cache..." 15
        $prefetchPath = "$env:WINDIR\Prefetch"
        return [math]::Round((Remove-FolderSafe $prefetchPath "Prefetch")/1MB, 2)
    }

    # 3. Clean Browser Caches
    function Clean-BrowserCaches {
        Update-Progress "Cleaning browser caches..." 25
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
                    if (Test-Path $path) {
                        Get-ChildItem -Path "$path\*\cache2" -ErrorAction SilentlyContinue | ForEach-Object {
                            $freed += Remove-FolderSafe $_.FullName "$browser cache"
                        }
                    }
                } else {
                    $freed += Remove-FolderSafe $path "$browser cache"
                }
            }
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 4. Clean Developer Caches
    function Clean-DeveloperCaches {
        Update-Progress "Cleaning developer caches..." 35
        $freed = 0

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
        }

        foreach ($tool in $devPaths.Keys) {
            $path = $devPaths[$tool]
            if ($tool -eq "npm") {
                try {
                    $before = Get-FolderSizeSafe $path
                    npm cache clean --force *> $null
                    Start-Sleep -Milliseconds 500
                    $after = Get-FolderSizeSafe $path
                    $freed += ($before - $after)
                } catch {}
            } elseif ($tool -eq "pip") {
                try {
                    $before = Get-FolderSizeSafe $path
                    pip cache purge *> $null
                    Start-Sleep -Milliseconds 500
                    $after = Get-FolderSizeSafe $path
                    $freed += ($before - $after)
                } catch {}
            } else {
                $freed += Remove-FolderSafe $path "$tool cache"
            }
        }

        Update-Progress "Cleaning development tools..." 45

        $devTools = @(
            "$env:USERPROFILE\.vscode\extensions\cachedData",
            "$env:LOCALAPPDATA\ms-playwright",
            "$env:LOCALAPPDATA\Cypress",
            "$env:LOCALAPPDATA\selenium"
        )

        foreach ($path in $devTools) {
            $freed += Remove-FolderSafe $path
        }

        # Docker
        try {
            $dockerImages = docker images -q 2>$null
            if ($dockerImages) {
                Update-Progress "Cleaning Docker..." 50
                docker system prune -f --volumes *> $null
                $freed += 500
            }
        } catch {}

        return [math]::Round($freed/1MB, 2)
    }

    # 5. Clean Application Caches
    function Clean-ApplicationCaches {
        Update-Progress "Cleaning application caches..." 55
        $freed = 0

        $appPaths = @{
            "AdobeCC" = "$env:APPDATA\Adobe\Cache"
            "Spotify" = "$env:LOCALAPPDATA\Spotify\Storage"
            "Discord" = "$env:APPDATA\discord\Cache"
            "Slack" = "$env:APPDATA\Slack\Cache"
            "Teams" = "$env:APPDATA\Microsoft\Teams\Cache"
            "Zoom" = "$env:APPDATA\zoom\data"
            "Telegram" = "$env:LOCALAPPDATA\Telegram\Desktop\tdata"
            "Steam" = "$env:PROGRAMFILES\Steam\appcache"
            "EpicGames" = "$env:LOCALAPPDATA\EpicGamesLauncher\Saved"
        }

        foreach ($app in $appPaths.Keys) {
            $path = $appPaths[$app]
            $freed += Remove-FolderSafe $path "$app cache"
        }

        return [math]::Round($freed/1MB, 2)
    }

    # 6. Clean System Files
    function Clean-SystemFiles {
        Update-Progress "Cleaning system files..." 65
        $freed = 0

        $sysPaths = @(
            "C:\ProgramData\Microsoft\Windows\WER",
            "C:\Windows\Logs",
            "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Store",
            "C:\ProgramData\Microsoft\Search\Data"
        )

        foreach ($path in $sysPaths) {
            $freed += Remove-FolderSafe $path
        }

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
        $freed += Remove-FolderSafe $fontCachePath "Font cache"

        # Recycle Bin
        Update-Progress "Emptying Recycle Bin..." 80
        try {
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0xA)
            $items = $recycleBin.Items()
            foreach ($item in $items) {
                try {
                    $freed += ($item.Size -as [double])
                    $item.InvokeVerb("delete")
                } catch {}
            }
        } catch {}

        return [math]::Round($freed/1MB, 2)
    }

    # 7. Clean Windows.old
    function Clean-WindowsOld {
        Update-Progress "Checking for Windows.old folder..." 85

        $windowsOldPath = "C:\Windows.old"
        if (-not (Test-Path $windowsOldPath)) {
            Update-Progress "No Windows.old folder found" 85
            return 0
        }

        $sizeBefore = Get-FolderSizeSafe $windowsOldPath

        if ($ScanOnly -or $DryRun) {
            Update-Progress "Windows.old found: $([math]::Round($sizeBefore/1GB, 2)) GB" 85
            return 0
        }

        try {
            Update-Progress "Removing Windows.old (may take several minutes)..." 85
            Takeown-Item -Path $windowsOldPath -AclObjectSizeLimit 100KB | Out-Null
            Get-ChildItem -Path $windowsOldPath -Recurse | ForEach-Object {
                try {
                    $acl = Get-Acl $_.FullName
                    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                        $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                    )
                    Set-Acl $_.FullName $acl
                } catch {}
            }
            Remove-Item -Path $windowsOldPath -Recurse -Force -ErrorAction Stop
            $sizeAfter = 0
            return [math]::Round(($sizeBefore - $sizeAfter)/1MB, 2)
        } catch {
            Update-Progress "Failed to remove Windows.old. Try manually." 85
            return 0
        }
    }

    # 8. Remove Hibernation
    function Remove-Hibernation {
        Update-Progress "Checking hibernation file..." 88

        $hiberFile = "C:\hiberfil.sys"
        if (-not (Test-Path $hiberFile)) {
            return 0
        }

        if ($ScanOnly -or $DryRun) {
            Update-Progress "Hibernation file found: $([math]::Round(((Get-Item $hiberFile).Length)/1GB, 2)) GB" 88
            return 0
        }

        try {
            Update-Progress "Disabling hibernation and removing file..." 88
            powercfg.exe /hibernate off *> $null
            Start-Sleep -Seconds 2

            if (Test-Path $hiberFile) {
                $sizeBefore = (Get-Item $hiberFile).Length
                Remove-Item -Path $hiberFile -Force -ErrorAction Stop
                return [math]::Round($sizeBefore/1MB, 2)
            }
        } catch {
            Update-Progress "Failed to remove hibernation file" 88
            return 0
        }
    }

    # 9. Clean Windows Update Residues
    function Clean-UpdateResidues {
        Update-Progress "Stopping Windows Update services..." 90

        Stop-Service -Name wuauserv, UsoSvc, WaaSMedicSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        $freed = 0
        $sdPath = "C:\Windows\SoftwareDistribution\Download"
        $freed += Remove-FolderSafe $sdPath "Windows Update"

        Update-Progress "Running DISM cleanup (this may take 10-30 minutes)..." 92
        dism /Online /Cleanup-Image /StartComponentCleanup /RetainDefinitiveAppraiserVersion *> $null

        Start-Service -Name wuauserv -ErrorAction SilentlyContinue

        return [math]::Round($freed/1MB, 2)
    }

    # 10. Disable Windows Update
    function Disable-WindowsUpdate {
        Update-Progress "Disabling Windows Update..." 98

        Stop-Service -Name wuauserv, UsoSvc, WaaSMedicSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name UsoSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name WaaSMedicSvc -StartupType Disabled -ErrorAction SilentlyContinue

        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 4 /f *> $null

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
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = New-Object System.Drawing.Point(20, 745)
    $startButton.Size = New-Object System.Drawing.Size(170, 40)
    $startButton.Text = "Start Cleanup"
    $startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = "Flat"
    $form.Controls.Add($startButton)

    $startButton.Add_Click({
        $startButton.Enabled = $false
        $startButton.Text = "Cleaning..."

        # Create restore point if requested
        if ($restorePointCheck.Checked -and -not ($ScanOnly -or $DryRun)) {
            Update-Progress "Creating System Restore Point..." 0
            try {
                Checkpoint-ComputerPool -Description "DiskCleanupTool" -ErrorAction Stop
            } catch {
                Write-Log "Failed to create restore point: $_" "WARNING"
            }
        }

        $resultsBox.Clear()
        $resultsBox.AppendText("=== Disk Cleanup Tool v4.0 ===`r`n")
        $resultsBox.AppendText("Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n")
        $resultsBox.AppendText("Mode: $(if ($DryRun) {'DRY RUN'} elseif ($ScanOnly) {'SCAN ONLY'} else {'NORMAL'})`r`n`r`n")

        foreach ($cb in $checkboxes) {
            if ($cb.Checked) {
                $opt = $cb.Tag
                switch ($opt.Name) {
                    "cleanTemp" { $totalFreedMB += Clean-TempFiles }
                    "cleanPrefetch" { $totalFreedMB += Clean-Prefetch }
                    "cleanBrowser" { $totalFreedMB += Clean-BrowserCaches }
                    "cleanDev" { $totalFreedMB += Clean-DeveloperCaches }
                    "cleanApps" { $totalFreedMB += Clean-ApplicationCaches }
                    "cleanSystem" { $totalFreedMB += Clean-SystemFiles }
                    "cleanWindowsOld" { $totalFreedMB += Clean-WindowsOld }
                    "cleanHiber" { $totalFreedMB += Remove-Hibernation }
                    "cleanUpdate" { $totalFreedMB += Clean-UpdateResidues }
                    "disableUpdate" { Disable-WindowsUpdate }
                }
            }
        }

        Update-Progress "Cleanup complete!" 100

        $drive = Get-PSDrive C
        $freeGB = [math]::Round($drive.Free/1GB, 2)
        $freedGB = [math]::Round($totalFreedMB/1024, 2)

        $resultsBox.AppendText("`r`n=== RESULTS ===`r`n")
        $resultsBox.AppendText("Total Space Freed: $freedGB GB`r`n")
        $resultsBox.AppendText("Current Free Space: $freeGB GB`r`n")
        $resultsBox.AppendText("Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n")

        [System.Windows.Forms.MessageBox]::Show(
            "Cleanup Complete!`n`nSpace Freed: $freedGB GB`nCurrent Free Space: $freeGB GB`n`nYour system is now cleaner and faster!",
            "Disk Cleanup Tool v4.0",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        $startButton.Text = "Complete"
    })

    # Show form
    $form.ShowDialog() | Out-Null
} else {
    # Console mode
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Disk Cleanup Tool v4.0" -ForegroundColor Cyan
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
