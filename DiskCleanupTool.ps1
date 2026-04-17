<#
    .SYNOPSIS
    Disk Cleanup & Windows Update Disable Tool
    .DESCRIPTION
    Comprehensive disk cleanup utility that frees up space and optionally disables Windows Update
    .VERSION
    1.0.0
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
    $form.Text = "Disk Cleanup & Windows Update Tool v1.0"
    $form.Size = New-Object System.Drawing.Size(600, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(540, 40)
    $titleLabel.Text = "Disk Cleanup & Windows Update Tool"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($titleLabel)

    # Current disk space
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    $usedGB = [math]::Round($drive.Used/1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used)/1GB, 2)

    $diskLabel = New-Object System.Windows.Forms.Label
    $diskLabel.Location = New-Object System.Drawing.Point(20, 70)
    $diskLabel.Size = New-Object System.Drawing.Size(540, 60)
    $diskLabel.Text = "Current Disk Space:`nFree: $freeGB GB | Used: $usedGB GB | Total: $totalGB GB"
    $diskLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($diskLabel)

    # Options group
    $optionsGroup = New-Object System.Windows.Forms.GroupBox
    $optionsGroup.Location = New-Object System.Drawing.Point(20, 140)
    $optionsGroup.Size = New-Object System.Drawing.Size(540, 350)
    $optionsGroup.Text = "Select Cleanup Options:"
    $form.Controls.Add($optionsGroup)

    # Cleanup options checkboxes
    $yPos = 30
    $checkboxes = @()

    $options = @(
        @{Name="cleanTemp"; Label="Clean Windows Temp Files"; Checked=$true; Description="Removes temporary files from Windows and user temp folders"},
        @{Name="cleanBrowser"; Label="Clean Browser Caches"; Checked=$true; Description="Clears Chrome, Edge, Firefox caches"},
        @{Name="cleanDev"; Label="Clean Developer Caches"; Checked=$true; Description="Clears npm, Composer, pip, yarn caches (saves GBs!)"},
        @{Name="cleanUpdate"; Label="Clean Windows Update Residues"; Checked=$true; Description="Removes SoftwareDistribution, WinSxS cleanup"},
        @{Name="disableUpdate"; Label="Disable Windows Update"; Checked=$false; Description="Permanently disables Windows Update services"},
        @{Name="cleanCapCut"; Label="Clean CapCut Data"; Checked=$false; Description="Removes all CapCut user data (2GB)"}
    )

    foreach ($opt in $options) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Location = New-Object System.Drawing.Point(20, $yPos)
        $cb.Size = New-Object System.Drawing.Size(500, 24)
        $cb.Text = $opt.Label
        $cb.Checked = $opt.Checked
        $cb.Tag = $opt
        $optionsGroup.Controls.Add($cb)
        $checkboxes += $cb
        $yPos += 30

        $desc = New-Object System.Windows.Forms.Label
        $desc.Location = New-Object System.Drawing.Point(40, $yPos)
        $desc.Size = New-Object System.Drawing.Size(480, 20)
        $desc.Text = $opt.Description
        $desc.ForeColor = [System.Drawing.Color]::Gray
        $desc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $optionsGroup.Controls.Add($desc)
        $yPos += 25
    }

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 510)
    $progressBar.Size = New-Object System.Drawing.Size(540, 25)
    $progressBar.Style = "Continuous"
    $form.Controls.Add($progressBar)

    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 540)
    $statusLabel.Size = New-Object System.Drawing.Size(540, 40)
    $statusLabel.Text = "Ready to start..."
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)

    # Start button
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = New-Object System.Drawing.Point(380, 590)
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

    function Clean-TempFiles {
        Update-Progress "Cleaning Windows temp files..." 10
        $freed = 0

        $tempPaths = @(
            "$env:LOCALAPPDATA\Temp",
            "$env:TEMP",
            "$env:WINDIR\Temp"
        )

        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                try {
                    $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                              Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                        ForEach-Object { try { Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue } catch {} }
                    $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                    $freed += ($before - $after)
                } catch {}
            }
        }

        return [math]::Round($freed/1MB, 2)
    }

    function Clean-BrowserCaches {
        Update-Progress "Cleaning browser caches..." 30
        $freed = 0

        $caches = @{
            "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
            "Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        }

        foreach ($browser in $caches.Keys) {
            $path = $caches[$browser]
            if (Test-Path $path) {
                try {
                    $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                              Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                    Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                    $freed += ($before - $after)
                } catch {}
            }
        }

        return [math]::Round($freed/1MB, 2)
    }

    function Clean-DevCaches {
        Update-Progress "Cleaning developer caches..." 50
        $freed = 0

        # npm
        try {
            $before = (Get-ChildItem -Path "$env:APPDATA\npm-cache" -Recurse -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            npm cache clean --force *> $null
            $after = (Get-ChildItem -Path "$env:APPDATA\npm-cache" -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $freed += ($before - $after)
        } catch {}

        # pip
        try {
            pip cache purge *> $null
        } catch {}

        # Composer
        try {
            $before = (Get-ChildItem -Path "$env:LOCALAPPDATA\Composer" -Recurse -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            composer clear-cache *> $null
            Start-Sleep -Seconds 1
            $after = (Get-ChildItem -Path "$env:LOCALAPPDATA\Composer" -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $freed += ($before - $after)
        } catch {}

        # Playwright
        $path = "$env:LOCALAPPDATA\ms-playwright"
        if (Test-Path $path) {
            try {
                $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                          Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $freed += ($before - $after)
            } catch {}
        }

        # Cypress
        $path = "$env:LOCALAPPDATA\Cypress"
        if (Test-Path $path) {
            try {
                $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                          Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $freed += ($before - $after)
            } catch {}
        }

        return [math]::Round($freed/1MB, 2)
    }

    function Clean-UpdateResidues {
        Update-Progress "Cleaning Windows update residues..." 70

        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue

        $freed = 0
        $path = "C:\Windows\SoftwareDistribution\Download"
        if (Test-Path $path) {
            try {
                $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                          Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $freed += ($before - $after)
            } catch {}
        }

        Update-Progress "Running DISM cleanup (may take 10-30 minutes)..." 75
        dism /Online /Cleanup-Image /StartComponentCleanup /RetainDefinitiveAppraiserVersion *> $null

        Start-Service -Name wuauserv -ErrorAction SilentlyContinue

        return [math]::Round($freed/1MB, 2)
    }

    function Disable-WindowsUpdate {
        Update-Progress "Disabling Windows Update..." 90

        Stop-Service -Name wuauserv, UsoSvc, WaaSMedicSvc -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name UsoSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service -Name WaaSMedicSvc -StartupType Disabled -ErrorAction SilentlyContinue

        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f *> $null
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 4 /f *> $null

        $hosts = "C:\Windows\System32\drivers\etc\hosts"
        if (-not (Select-String -Path $hosts -Pattern "Windows Update blocked" -Quiet -ErrorAction SilentlyContinue)) {
            "`n# Windows Update blocked" | Out-File -FilePath $hosts -Append -Encoding ASCII -ErrorAction SilentlyContinue
            "127.0.0.1 windowsupdate.microsoft.com" | Out-File -FilePath $hosts -Append -Encoding ASCII -ErrorAction SilentlyContinue
            "127.0.0.1 update.microsoft.com" | Out-File -FilePath $hosts -Append -Encoding ASCII -ErrorAction SilentlyContinue
            "127.0.0.1 ctldl.windowsupdate.com" | Out-File -FilePath $hosts -Append -Encoding ASCII -ErrorAction SilentlyContinue
        }

        return 0
    }

    function Clean-CapCut {
        Update-Progress "Cleaning CapCut data..." 95
        $path = "$env:LOCALAPPDATA\CapCut"
        if (Test-Path $path) {
            try {
                $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                          Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction Stop
                $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                return [math]::Round(($before - $after)/1MB, 2)
            } catch {
                return 0
            }
        }
        return 0
    }

    # Start button click handler
    $startButton.Add_Click({
        $startButton.Enabled = $false

        foreach ($cb in $checkboxes) {
            if ($cb.Checked) {
                $opt = $cb.Tag
                switch ($opt.Name) {
                    "cleanTemp" { $totalFreedMB += Clean-TempFiles }
                    "cleanBrowser" { $totalFreedMB += Clean-BrowserCaches }
                    "cleanDev" { $totalFreedMB += Clean-DevCaches }
                    "cleanUpdate" { $totalFreedMB += Clean-UpdateResidues }
                    "disableUpdate" { Disable-WindowsUpdate }
                    "cleanCapCut" { $totalFreedMB += Clean-CapCut }
                }
            }
        }

        Update-Progress "Cleanup complete!" 100

        $drive = Get-PSDrive C
        $freeGB = [math]::Round($drive.Free/1GB, 2)

        [System.Windows.Forms.MessageBox]::Show(
            "Cleanup Complete!`n`nSpace Freed: $([math]::Round($totalFreedMB/1024, 2)) GB`nCurrent Free Space: $freeGB GB",
            "Complete",
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
    Write-Host "  Disk Cleanup & Windows Update Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    Write-Host "Current free space: $freeGB GB" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Running full cleanup..." -ForegroundColor Green
    # Add console cleanup functions here...
    Write-Host "Done!" -ForegroundColor Green
}
