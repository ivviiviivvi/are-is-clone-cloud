# Personal Knowledge Base Sync Script for Windows
# This script syncs your personal knowledge base across multiple cloud providers
#
# Usage: .\sync-knowledge-base.ps1 [-DryRun] [-Verbose]
#

param(
    [switch]$DryRun,
    [switch]$Verbose
)

# Configuration
$PrimaryRemote = "icloud:KnowledgeBase"
$BackupRemotes = @(
    "dropbox:KnowledgeBase/Backup-iCloud",
    "gdrive:KnowledgeBase/Backup-iCloud",
    "onedrive:KnowledgeBase/Backup-iCloud"
)

$LogDir = "$env:USERPROFILE\logs"
$LogFile = Join-Path $LogDir "rclone-kb-sync-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Function to log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Function to sync to a backup remote
function Sync-ToBackup {
    param([string]$BackupRemote)
    
    Write-Log "Syncing to $BackupRemote..."
    
    $rcloneArgs = @(
        "sync",
        $PrimaryRemote,
        $BackupRemote,
        "--log-file=$LogFile",
        "--exclude", "*.tmp",
        "--exclude", "*.temp",
        "--exclude", ".DS_Store",
        "--exclude", "Thumbs.db",
        "--exclude", "desktop.ini",
        "--stats=1m",
        "--stats-one-line"
    )
    
    if ($DryRun) {
        $rcloneArgs += "--dry-run"
    }
    
    if ($Verbose) {
        $rcloneArgs += "-v"
    }
    
    $process = Start-Process -FilePath "rclone" -ArgumentList $rcloneArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Log "✓ Successfully synced to $BackupRemote"
        return $true
    } else {
        Write-Log "✗ Failed to sync to $BackupRemote"
        return $false
    }
}

# Main sync process
Write-Log "========================================="
Write-Log "Starting Knowledge Base Sync"
Write-Log "Primary: $PrimaryRemote"

if ($DryRun) {
    Write-Log "Running in dry-run mode (no changes will be made)"
}

Write-Log "========================================="

# Check if rclone is installed
try {
    $null = Get-Command rclone -ErrorAction Stop
} catch {
    Write-Log "✗ Error: rclone is not installed or not in PATH"
    exit 1
}

# Check if primary remote is accessible
$checkProcess = Start-Process -FilePath "rclone" -ArgumentList @("lsd", $PrimaryRemote) `
    -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\rclone-check.txt" `
    -RedirectStandardError "$env:TEMP\rclone-check-err.txt"

if ($checkProcess.ExitCode -ne 0) {
    Write-Log "✗ Error: Cannot access primary remote $PrimaryRemote"
    exit 1
}

Write-Log "✓ Primary remote is accessible"

# Sync to each backup remote
$FailedSyncs = 0
foreach ($backupRemote in $BackupRemotes) {
    if (-not (Sync-ToBackup $backupRemote)) {
        $FailedSyncs++
    }
}

# Report summary
Write-Log "========================================="
Write-Log "Sync Summary"
Write-Log "Total backup remotes: $($BackupRemotes.Count)"
Write-Log "Failed syncs: $FailedSyncs"
Write-Log "Log file: $LogFile"
Write-Log "========================================="

if ($FailedSyncs -eq 0) {
    Write-Log "✓ All syncs completed successfully"
    exit 0
} else {
    Write-Log "✗ Some syncs failed. Check log for details."
    exit 1
}
