#!/bin/bash

#MYSQL backup script

# ================== SETTINGS ==================

BACKUP_DIR="/home/backups"
LOG_FILE="/var/log/mysql_backup.log"
DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/<DISCORD_WEBHOOK_KEY>"

# =================================================

TIMESTAMP="$(date "+%b_%d_%Y_%H_%M_%S")"
FILENAME="mysql_backup_${TIMESTAMP}.sql.gz"
BACKUP_PATH="$BACKUP_DIR/$FILENAME"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

log "Backup started"

# Dump + compress
if mariadb-dump --all-databases | gzip > "$BACKUP_PATH"; then

    SIZE=$(du -h "$BACKUP_PATH" | awk '{print $1}')

    MESSAGE="✅ **MySQL Backup SUCCESS**\n🗄 File: \`$FILENAME\`\n📦 Size: **$SIZE**\n🖥 Host: \`$(hostname)\`"

    log "Backup completed successfully, file: $FILENAME, size: $SIZE"

else
    EXIT_CODE=$?
    MESSAGE="❌ **MySQL Backup FAILED**\n⚠ Exit code: $EXIT_CODE\n🖥 Host: \`$(hostname)\`"

    log "Backup FAILED with exit code $EXIT_CODE"
fi

# Sending discord message
curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "{\"content\": \"$MESSAGE\"}" \
     "$DISCORD_WEBHOOK_URL" >/dev/null