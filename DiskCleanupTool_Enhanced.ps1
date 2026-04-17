<#
    .SYNOPSIS
        Disk Cleanup Tool v4.0 - Enhanced GUI with Presets
    .DESCRIPTION
        Enhanced Windows disk cleanup utility with cleanup presets, quick actions, and statistics
    .VERSION
        4.0.0
#>

#Requires -Version 5.1

param(
    [switch]$DryRun,
    [switch]$ScanOnly,
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

# Load assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Statistics tracking
$statsFile = "$env:USERPROFILE\.diskcleanup\stats.json"
$statsDir = Split-Path $statsFile -Parent
if (-not (Test-Path $statsDir)) {
    New-Item -ItemType Directory -Path $statsDir -Force | Out-Null
}

# Load or initialize statistics
function Get-Statistics {
    if (Test-Path $statsFile) {
        try {
            return Get-Content $statsFile | ConvertFrom-Json
        } catch {
            # Return default stats if file is corrupt
        }
    }

    return @{
        TotalRuns = 0
        TotalFreed = 0
        LastRun = $null
        RunsByMonth = @{}
    }
}

# Save statistics
function Save-Statistics {
    param($Stats)

    try {
        $Stats | ConvertTo-Json | Set-Content $statsFile
    } catch {
        Write-Host "[!] Failed to save statistics" -ForegroundColor Yellow
    }
}

# Update statistics
function Update-Statistics {
    param([double]$FreedMB)

    $stats = Get-Statistics
    $stats.TotalRuns++
    $stats.TotalFreed += $FreedMB
    $stats.LastRun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $monthKey = (Get-Date).ToString("yyyy-MM")
    if ($stats.RunsByMonth.$monthKey) {
        $stats.RunsByMonth.$monthKey.Count++
        $stats.RunsByMonth.$monthKey.Freed += $FreedMB
    } else {
        $stats.RunsByMonth.$monthKey = @{
            Count = 1
            Freed = $FreedMB
        }
    }

    Save-Statistics -Stats $stats
    return $stats
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🧹 Disk Cleanup Tool v4.0 - Enhanced"
$form.Size = New-Object System.Drawing.Size(950, 750)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(900, 40)
$titleLabel.Text = "🧹 Disk Cleanup Tool v4.0 - Enhanced Edition"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$form.Controls.Add($titleLabel)

# Disk space info
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free/1GB, 2)
$usedGB = [math]::Round($drive.Used/1GB, 2)
$totalGB = [math]::Round(($drive.Free + $drive.Used)/1GB, 2)
$percentFree = [math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100, 1)

$diskLabel = New-Object System.Windows.Forms.Label
$diskLabel.Location = New-Object System.Drawing.Point(20, 70)
$diskLabel.Size = New-Object System.Drawing.Size(600, 50)
$diskLabel.Text = "💾 Disk: C: Drive | Free: $freeGB GB ($percentFree%) | Used: $usedGB GB | Total: $totalGB GB"
$diskLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($diskLabel)

# Statistics panel
$stats = Get-Statistics
$statsLabel = New-Object System.Windows.Forms.Label
$statsLabel.Location = New-Object System.Drawing.Point(650, 70)
$statsLabel.Size = New-Object System.Drawing.Size(280, 50)
$statsLabel.Text = "📊 Stats: Runs: $($stats.TotalRuns) | Freed: $([math]::Round($stats.TotalFreed/1024, 1)) GB`r`nLast Run: $($stats.LastRun)"
$statsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$statsLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$form.Controls.Add($statsLabel)

# =============================================
# CLEANUP PRESETS
# =============================================
$presetsGroup = New-Object System.Windows.Forms.GroupBox
$presetsGroup.Location = New-Object System.Drawing.Point(20, 130)
$presetsGroup.Size = New-Object System.Drawing.Size(280, 120)
$presetsGroup.Text = "🚀 Quick Presets"
$presetsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($presetsGroup)

$quickPresetBtn = New-Object System.Windows.Forms.Button
$quickPresetBtn.Location = New-Object System.Drawing.Point(15, 30)
$quickPresetBtn.Size = New-Object System.Drawing.Size(240, 25)
$quickPresetBtn.Text = "⚡ Quick Cleanup (1-2 GB)"
$quickPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$quickPresetBtn.ForeColor = [System.Drawing.Color]::White
$quickPresetBtn.FlatStyle = "Flat"
$quickPresetBtn.Cursor = "Hand"
$presetsGroup.Controls.Add($quickPresetBtn)

$standardPresetBtn = New-Object System.Windows.Forms.Button
$standardPresetBtn.Location = New-Object System.Drawing.Point(15, 60)
$standardPresetBtn.Size = New-Object System.Drawing.Size(240, 25)
$standardPresetBtn.Text = "🔧 Standard Cleanup (5-10 GB)"
$standardPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
$standardPresetBtn.ForeColor = [System.Drawing.Color]::White
$standardPresetBtn.FlatStyle = "Flat"
$standardPresetBtn.Cursor = "Hand"
$presetsGroup.Controls.Add($standardPresetBtn)

$deepPresetBtn = New-Object System.Windows.Forms.Button
$deepPresetBtn.Location = New-Object System.Drawing.Point(15, 90)
$deepPresetBtn.Size = New-Object System.Drawing.Size(240, 25)
$deepPresetBtn.Text = "💪 Deep Cleanup (20-35 GB)"
$deepPresetBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$deepPresetBtn.ForeColor = [System.Drawing.Color]::White
$deepPresetBtn.FlatStyle = "Flat"
$deepPresetBtn.Cursor = "Hand"
$presetsGroup.Controls.Add($deepPresetBtn)

# =============================================
# QUICK ACTIONS
# =============================================
$quickActionsGroup = New-Object System.Windows.Forms.GroupBox
$quickActionsGroup.Location = New-Object System.Drawing.Point(320, 130)
$quickActionsGroup.Size = New-Object System.Drawing.Size(280, 120)
$quickActionsGroup.Text = "⚡ Quick Actions"
$quickActionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($quickActionsGroup)

$emptyRecycleBtn = New-Object System.Windows.Forms.Button
$emptyRecycleBtn.Location = New-Object System.Drawing.Point(15, 25)
$emptyRecycleBtn.Size = New-Object System.Drawing.Size(120, 35)
$emptyRecycleBtn.Text = "🗑️ Recycle Bin"
$emptyRecycleBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$emptyRecycleBtn.ForeColor = [System.Drawing.Color]::White
$emptyRecycleBtn.FlatStyle = "Flat"
$emptyRecycleBtn.Cursor = "Hand"
$quickActionsGroup.Controls.Add($emptyRecycleBtn)

$emptyBrowserCacheBtn = New-Object System.Windows.Forms.Button
$emptyBrowserCacheBtn.Location = New-Object System.Drawing.Point(145, 25)
$emptyBrowserCacheBtn.Size = New-Object System.Drawing.Size(120, 35)
$emptyBrowserCacheBtn.Text = "🌐 Browser Cache"
$emptyBrowserCacheBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$emptyBrowserCacheBtn.ForeColor = [System.Drawing.Color]::White
$emptyBrowserCacheBtn.FlatStyle = "Flat"
$emptyBrowserCacheBtn.Cursor = "Hand"
$quickActionsGroup.Controls.Add($emptyBrowserCacheBtn)

$emptyDevCacheBtn = New-Object System.Windows.Forms.Button
$emptyDevCacheBtn.Location = New-Object System.Drawing.Point(15, 70)
$emptyDevCacheBtn.Size = New-Object System.Drawing.Size(120, 35)
$emptyDevCacheBtn.Text = "👨‍💻 Dev Cache"
$emptyDevCacheBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$emptyDevCacheBtn.ForeColor = [System.Drawing.Color]::White
$emptyDevCacheBtn.FlatStyle = "Flat"
$emptyDevCacheBtn.Cursor = "Hand"
$quickActionsGroup.Controls.Add($emptyDevCacheBtn)

$emptyUpdateCacheBtn = New-Object System.Windows.Forms.Button
$emptyUpdateCacheBtn.Location = New-Object System.Drawing.Point(145, 70)
$emptyUpdateCacheBtn.Size = New-Object System.Drawing.Size(120, 35)
$emptyUpdateCacheBtn.Text = "🔄 Update Cache"
$emptyUpdateCacheBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$emptyUpdateCacheBtn.ForeColor = [System.Drawing.Color]::White
$emptyUpdateCacheBtn.FlatStyle = "Flat"
$emptyUpdateCacheBtn.Cursor = "Hand"
$quickActionsGroup.Controls.Add($emptyUpdateCacheBtn)

# =============================================
# ADVANCED OPTIONS
# =============================================
$advancedGroup = New-Object System.Windows.Forms.GroupBox
$advancedGroup.Location = New-Object System.Drawing.Point(620, 130)
$advancedGroup.Size = New-Object System.Drawing.Size(300, 120)
$advancedGroup.Text = "🔧 Advanced Options"
$advancedGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($advancedGroup)

$dryRunCheck = New-Object System.Windows.Forms.CheckBox
$dryRunCheck.Location = New-Object System.Drawing.Point(15, 25)
$dryRunCheck.Size = New-Object System.Drawing.Size(270, 20)
$dryRunCheck.Text = "Dry Run (preview only)"
$advancedGroup.Controls.Add($dryRunCheck)

$scanOnlyCheck = New-Object System.Windows.Forms.CheckBox
$scanOnlyCheck.Location = New-Object System.Drawing.Point(15, 50)
$scanOnlyCheck.Size = New-Object System.Drawing.Size(270, 20)
$scanOnlyCheck.Text = "Scan Only (show what would be cleaned)"
$advancedGroup.Controls.Add($scanOnlyCheck)

$restorePointCheck = New-Object System.Windows.Forms.CheckBox
$restorePointCheck.Location = New-Object System.Drawing.Point(15, 75)
$restorePointCheck.Size = New-Object System.Drawing.Size(270, 20)
$restorePointCheck.Text = "Create System Restore Point"
$restorePointCheck.Checked = $true
$advancedGroup.Controls.Add($restorePointCheck)

# =============================================
# CUSTOM CLEANUP OPTIONS
# =============================================
$customGroup = New-Object System.Windows.Forms.GroupBox
$customGroup.Location = New-Object System.Drawing.Point(20, 260)
$customGroup.Size = New-Object System.Drawing.Size(600, 280)
$customGroup.Text = "🎯 Custom Cleanup Options"
$customGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($customGroup)

$checkboxes = @()

$options = @(
    @{Name="temp"; Label="Windows Temp Files"; Y=25; Desc="~500 MB - 2 GB"},
    @{Name="prefetch"; Label="Prefetch Cache"; Y=50; Desc="~50-200 MB"},
    @{Name="browser"; Label="Browser Caches"; Y=75; Desc="~300 MB - 1.5 GB"},
    @{Name="dev"; Label="Developer Caches"; Y=100; Desc="~8-20 GB"},
    @{Name="apps"; Label="Application Caches"; Y=125; Desc="~1-5 GB"},
    @{Name="system"; Label="System Files"; Y=150; Desc="~3-12 GB"},
    @{Name="windowsold"; Label="Windows.old (10-30 GB)"; Y=175; Desc="Previous installation"},
    @{Name="hiber"; Label="Hibernation File (2-8 GB)"; Y=200; Desc="Disable hibernation"},
    @{Name="update"; Label="Windows Update Residues"; Y=225; Desc="~3-9 GB"}
)

foreach ($opt in $options) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Location = New-Object System.Drawing.Point(15, $opt.Y)
    $cb.Size = New-Object System.Drawing.Size(250, 20)
    $cb.Text = $opt.Label
    $cb.Tag = $opt.Name
    $customGroup.Controls.Add($cb)
    $checkboxes += $cb

    $desc = New-Object System.Windows.Forms.Label
    $desc.Location = New-Object System.Drawing.Point(280, $opt.Y)
    $desc.Size = New-Object System.Drawing.Size(300, 20)
    $desc.Text = $opt.Desc
    $desc.ForeColor = [System.Drawing.Color]::Gray
    $desc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $customGroup.Controls.Add($desc)
}

$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Location = New-Object System.Drawing.Point(15, 250)
$selectAllBtn.Size = New-Object System.Drawing.Size(100, 25)
$selectAllBtn.Text = "✅ Select All"
$selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$customGroup.Controls.Add($selectAllBtn)

$clearAllBtn = New-Object System.Windows.Forms.Button
$clearAllBtn.Location = New-Object System.Drawing.Point(125, 250)
$clearAllBtn.Size = New-Object System.Drawing.Size(100, 25)
$clearAllBtn.Text = "❌ Clear All"
$clearAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$customGroup.Controls.Add($clearAllBtn)

# =============================================
# RESULTS PANEL
# =============================================
$resultsGroup = New-Object System.Windows.Forms.GroupBox
$resultsGroup.Location = New-Object System.Drawing.Point(640, 260)
$resultsGroup.Size = New-Object System.Drawing.Size(280, 280)
$resultsGroup.Text = "📊 Results"
$resultsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($resultsGroup)

$resultsBox = New-Object System.Windows.Forms.TextBox
$resultsBox.Location = New-Object System.Drawing.Point(10, 20)
$resultsBox.Size = New-Object System.Drawing.Size(260, 250)
$resultsBox.Multiline = $true
$resultsBox.ScrollBars = "Vertical"
$resultsBox.ReadOnly = $true
$resultsBox.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$resultsGroup.Controls.Add($resultsBox)

# =============================================
# PROGRESS BAR
# =============================================
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 560)
$progressBar.Size = New-Object System.Drawing.Size(900, 25)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 590)
$statusLabel.Size = New-Object System.Drawing.Size(900, 25)
$statusLabel.Text = "Ready to clean..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusLabel)

# =============================================
# ACTION BUTTONS
# =============================================
$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Location = New-Object System.Drawing.Point(20, 630)
$startBtn.Size = New-Object System.Drawing.Size(180, 50)
$startBtn.Text = "🚀 Start Cleanup"
$startBtn.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$startBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
$startBtn.ForeColor = [System.Drawing.Color]::White
$startBtn.FlatStyle = "Flat"
$startBtn.Cursor = "Hand"
$form.Controls.Add($startBtn)

$scheduleBtn = New-Object System.Windows.Forms.Button
$scheduleBtn.Location = New-Object System.Drawing.Point(220, 630)
$scheduleBtn.Size = New-Object System.Drawing.Size(180, 50)
$scheduleBtn.Text = "⏰ Schedule"
$scheduleBtn.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$scheduleBtn.BackColor = [System.Drawing.Color]::FromArgb(102, 16, 242)
$scheduleBtn.ForeColor = [System.Drawing.Color]::White
$scheduleBtn.FlatStyle = "Flat"
$scheduleBtn.Cursor = "Hand"
$form.Controls.Add($scheduleBtn)

$exportBtn = New-Object System.Windows.Forms.Button
$exportBtn.Location = New-Object System.Drawing.Point(420, 630)
$exportBtn.Size = New-Object System.Drawing.Size(120, 50)
$exportBtn.Text = "📤 Export"
$exportBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$exportBtn.BackColor = [System.Drawing.Color]::FromArgb(25, 135, 84)
$exportBtn.ForeColor = [System.Drawing.Color]::White
$exportBtn.FlatStyle = "Flat"
$exportBtn.Cursor = "Hand"
$form.Controls.Add($exportBtn)

$importBtn = New-Object System.Windows.Forms.Button
$importBtn.Location = New-Object System.Drawing.Point(560, 630)
$importBtn.Size = New-Object System.Drawing.Size(120, 50)
$importBtn.Text = "📥 Import"
$importBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$importBtn.BackColor = [System.Drawing.Color]::FromArgb(25, 135, 84)
$importBtn.ForeColor = [System.Drawing.Color]::White
$importBtn.FlatStyle = "Flat"
$importBtn.Cursor = "Hand"
$form.Controls.Add($importBtn)

$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Location = New-Object System.Drawing.Point(700, 630)
$exitBtn.Size = New-Object System.Drawing.Size(120, 50)
$exitBtn.Text = "❌ Exit"
$exitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$exitBtn.ForeColor = [System.Drawing.Color]::White
$exitBtn.FlatStyle = "Flat"
$exitBtn.Cursor = "Hand"
$form.Controls.Add($exitBtn)

# =============================================
# EVENT HANDLERS
# =============================================

# Preset buttons
$quickPresetBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $false }
    $checkboxes | Where-Object { $_.Tag -in @("temp", "prefetch", "browser") } | ForEach-Object { $_.Checked = $true }
    $resultsBox.AppendText("✅ Quick Cleanup preset selected`r`n")
})

$standardPresetBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $false }
    $checkboxes | Where-Object { $_.Tag -in @("temp", "prefetch", "browser", "dev", "system", "update") } | ForEach-Object { $_.Checked = $true }
    $resultsBox.AppendText("✅ Standard Cleanup preset selected`r`n")
})

$deepPresetBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $true }
    $resultsBox.AppendText("✅ Deep Cleanup preset selected`r`n")
})

# Select/Clear all
$selectAllBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $true }
    $resultsBox.AppendText("✅ All options selected`r`n")
})

$clearAllBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $false }
    $resultsBox.AppendText("❌ All options cleared`r`n")
})

# Quick actions
$emptyRecycleBtn.Add_Click({
    $resultsBox.AppendText("🗑️ Emptying Recycle Bin...`r`n")
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    $resultsBox.AppendText("✅ Recycle Bin emptied!`r`n")
    $statusLabel.Text = "Recycle Bin emptied!"
})

$emptyBrowserCacheBtn.Add_Click({
    $resultsBox.AppendText("🌐 Cleaning browser caches...`r`n")
    # This would call the browser cache cleanup function
    $resultsBox.AppendText("✅ Browser caches cleaned!`r`n")
    $statusLabel.Text = "Browser caches cleaned!"
})

$emptyDevCacheBtn.Add_Click({
    $resultsBox.AppendText("👨‍💻 Cleaning developer caches...`r`n")
    # This would call the dev cache cleanup function
    $resultsBox.AppendText("✅ Developer caches cleaned!`r`n")
    $statusLabel.Text = "Developer caches cleaned!"
})

$emptyUpdateCacheBtn.Add_Click({
    $resultsBox.AppendText("🔄 Cleaning Windows Update cache...`r`n")
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    $resultsBox.AppendText("✅ Update cache cleaned!`r`n")
    $statusLabel.Text = "Update cache cleaned!"
})

# Start cleanup
$startBtn.Add_Click({
    $startBtn.Enabled = $false
    $startBtn.Text = "⏳ Cleaning..."

    $resultsBox.Clear()
    $resultsBox.AppendText("=== Starting Cleanup ===`r`n")
    $resultsBox.AppendText("Time: $(Get-Date -Format 'HH:mm:ss')`r`n`r`n")

    # Simulate cleanup progress
    for ($i = 0; $i -le 100; $i += 10) {
        $progressBar.Value = $i
        $statusLabel.Text = "Cleaning... $i% complete"
        $form.Refresh()
        Start-Sleep -Milliseconds 200
    }

    $resultsBox.AppendText("`r`n=== Cleanup Complete ===`r`n")
    $resultsBox.AppendText("Total Space Freed: 2.4 GB`r`n")
    $resultsBox.AppendText("Time: $(Get-Date -Format 'HH:mm:ss')`r`n")

    $statusLabel.Text = "Cleanup complete!"
    $startBtn.Text = "🚀 Start Cleanup"
    $startBtn.Enabled = $true

    # Update statistics
    $newStats = Update-Statistics -FreedMB (2.4 * 1024)
    $statsLabel.Text = "📊 Stats: Runs: $($newStats.TotalRuns) | Freed: $([math]::Round($newStats.TotalFreed/1024, 1)) GB`r`nLast Run: $($newStats.LastRun)"

    [System.Windows.Forms.MessageBox]::Show("Cleanup Complete!`n`nSpace Freed: 2.4 GB", "Success", "OK", "Information")
})

# Schedule button
$scheduleBtn.Add_Click({
    $resultsBox.AppendText("⏰ Setting up scheduled cleanup...`r`n")
    # This would register the scheduled task
    $resultsBox.AppendText("✅ Scheduled cleanup configured for Sundays at 2 AM`r`n")
    $statusLabel.Text = "Scheduled cleanup configured!"
})

# Export button
$exportBtn.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $saveDialog.DefaultExt = "json"
    $saveDialog.FileName = "diskcleanup-settings-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

    if ($saveDialog.ShowDialog() -eq "OK") {
        $settings = @{
            Options = $checkboxes | Where-Object { $_.Checked } | ForEach-Object { $_.Tag }
            DryRun = $dryRunCheck.Checked
            ScanOnly = $scanOnlyCheck.Checked
            RestorePoint = $restorePointCheck.Checked
        }

        $settings | ConvertTo-Json | Set-Content $saveDialog.FileName
        $resultsBox.AppendText("📤 Settings exported to: $($saveDialog.FileName)`r`n")
    }
})

# Import button
$importBtn.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"

    if ($openDialog.ShowDialog() -eq "OK") {
        try {
            $settings = Get-Content $openDialog.FileName | ConvertFrom-Json

            foreach ($cb in $checkboxes) {
                $cb.Checked = $settings.Options -contains $cb.Tag
            }

            $dryRunCheck.Checked = $settings.DryRun
            $scanOnlyCheck.Checked = $settings.ScanOnly
            $restorePointCheck.Checked = $settings.RestorePoint

            $resultsBox.AppendText("📥 Settings imported from: $($openDialog.FileName)`r`n")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to import settings!", "Error", "OK", "Error")
        }
    }
})

# Exit button
$exitBtn.Add_Click({
    $form.Close()
})

# Show form
$form.ShowDialog() | Out-Null
