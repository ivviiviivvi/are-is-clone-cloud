#!/bin/bash
#
# Personal Knowledge Base Sync Script
# This script syncs your personal knowledge base across multiple cloud providers
#
# Usage: ./sync-knowledge-base.sh [--dry-run] [--verbose]
#

set -e

# Configuration
PRIMARY_REMOTE="icloud:KnowledgeBase"
BACKUP_REMOTES=(
    "dropbox:KnowledgeBase/Backup-iCloud"
    "gdrive:KnowledgeBase/Backup-iCloud"
    "onedrive:KnowledgeBase/Backup-iCloud"
)

LOG_DIR="${HOME}/logs"
LOG_FILE="${LOG_DIR}/rclone-kb-sync-$(date +%Y%m%d-%H%M%S).log"
FILTER_FILE="${HOME}/.rclone-kb-filter"

# Parse arguments
DRY_RUN=""
VERBOSE=""
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN="--dry-run"
            echo "Running in dry-run mode (no changes will be made)"
            ;;
        --verbose|-v)
            VERBOSE="-v"
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be transferred without making changes"
            echo "  --verbose    Show detailed output"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
done

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to sync to a backup remote
sync_to_backup() {
    local backup_remote=$1
    log "Syncing to ${backup_remote}..."
    
    rclone sync "${PRIMARY_REMOTE}" "${backup_remote}" \
        ${DRY_RUN} \
        ${VERBOSE} \
        --log-file="${LOG_FILE}" \
        --exclude "*.tmp" \
        --exclude "*.temp" \
        --exclude ".DS_Store" \
        --exclude "Thumbs.db" \
        --exclude "desktop.ini" \
        --stats=1m \
        --stats-one-line
    
    if [ $? -eq 0 ]; then
        log "✓ Successfully synced to ${backup_remote}"
    else
        log "✗ Failed to sync to ${backup_remote}"
        return 1
    fi
}

# Main sync process
log "========================================="
log "Starting Knowledge Base Sync"
log "Primary: ${PRIMARY_REMOTE}"
log "========================================="

# Check if primary remote is accessible
if ! rclone lsd "${PRIMARY_REMOTE}" > /dev/null 2>&1; then
    log "✗ Error: Cannot access primary remote ${PRIMARY_REMOTE}"
    exit 1
fi

log "✓ Primary remote is accessible"

# Sync to each backup remote
FAILED_SYNCS=0
for backup_remote in "${BACKUP_REMOTES[@]}"; do
    if ! sync_to_backup "${backup_remote}"; then
        FAILED_SYNCS=$((FAILED_SYNCS + 1))
    fi
done

# Report summary
log "========================================="
log "Sync Summary"
log "Total backup remotes: ${#BACKUP_REMOTES[@]}"
log "Failed syncs: ${FAILED_SYNCS}"
log "Log file: ${LOG_FILE}"
log "========================================="

if [ ${FAILED_SYNCS} -eq 0 ]; then
    log "✓ All syncs completed successfully"
    exit 0
else
    log "✗ Some syncs failed. Check log for details."
    exit 1
fi
