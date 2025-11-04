# Quick Start: Personal Knowledge Base Setup

This quick start guide helps you get up and running with a
multi-cloud personal knowledge base in minutes.

## Prerequisites

- Install rclone: `https://rclone.org/install/`
- Active accounts with cloud providers (iCloud, Dropbox, Google Drive,
  OneDrive)

## Quick Setup (5 minutes)

### 1. Configure Your First Remote

```console
$ rclone config
n) New remote
name> gdrive
Storage> drive
# Follow OAuth prompts to authenticate
```

### 2. Create Knowledge Base Directory

```console
$ rclone mkdir gdrive:KnowledgeBase
# Creates the main directory
```

### 3. Sync Your First Files

```console
$ rclone sync ~/Documents gdrive:KnowledgeBase/Documents -P
# Syncs with progress display
```

## Next Steps

### Add More Cloud Providers

Repeat step 1 for:

- iCloud Drive (type: `iclouddrive`)
- Dropbox (type: `dropbox`)
- OneDrive (type: `onedrive`)

### Create Unified View

```console
$ rclone config
n) New remote
name> kb-unified
Storage> union
upstreams> gdrive:KnowledgeBase dropbox:KnowledgeBase icloud:KnowledgeBase onedrive:KnowledgeBase
```

### Mount Locally

```console
$ rclone mount kb-unified: ~/KnowledgeBase --vfs-cache-mode writes --daemon
# Mounts unified view as local directory
```

Now access your unified knowledge base at `~/KnowledgeBase`!

## Full Guide

For comprehensive instructions, see:
`docs/content/guides/personal-knowledge-base.md`

Or visit: `https://rclone.org/guides/personal-knowledge-base/`

## Automation Scripts

Ready-to-use scripts available:

- Linux/Mac: `docs/content/guides/sync-knowledge-base.sh`
- Windows: `docs/content/guides/sync-knowledge-base.ps1`

## Need Help?

- Documentation: `https://rclone.org/docs/`
- Forum: `https://forum.rclone.org/`
- GitHub: `https://github.com/rclone/rclone`
