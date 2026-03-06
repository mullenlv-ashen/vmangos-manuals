#!/bin/bash

#Compress logs script

LOG_DIR="/home/vmangos_server/run/bin/logs"
ARCHIVE_DIR="/home/vmangos_server/run/bin/logs/archive"
TIMESTAMP=$(date +"%b_%d_%Y_%H_%M_%S")
CURRENT_DATE=$(date +"%d.%m.%Y %H:%M:%S")
WEBHOOK_URL="https://discordapp.com/api/webhooks/<DISCORD_WEBHOOK_KEY>"


LOG_OWNER="vmangos_user"
LOG_GROUP="vmangos_group"
LOG_PERMS="666"

mkdir -p "$ARCHIVE_DIR"

cd "$LOG_DIR" || exit 1

LOG_FILES=(
  Chat.log
  Loot.log
  Trades.log
  Server.log
  Realmd.log
  LevelUp.log
  Char.log
  Scripts.log
  Anticheat.log
  Movement.log
  Perf.log
  DBErrors.log
  Ra.log
  Honor.log
  DBErrorFix.log
  Gm.log
  Gm_critical.log
  Bg.log
)

REPORT="📦 Log archive report ($CURRENT_DATE)\n\n"

SUCCESS_COUNT=0
FAIL_COUNT=0

for LOG in "${LOG_FILES[@]}"; do
  if [[ -f "$LOG" ]]; then

    ARCHIVE_NAME="${LOG%.*}_${TIMESTAMP}.tar.gz"
    ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"
    TMP_FILE="${LOG}.tmp"

    if cp "$LOG" "$TMP_FILE"; then

      if tar -czf "$ARCHIVE_PATH" "$TMP_FILE"; then
        rm -f "$TMP_FILE"

        truncate -s 0 "$LOG"

        chown "$LOG_OWNER":"$LOG_GROUP" "$LOG"
        chmod "$LOG_PERMS" "$LOG"

        REPORT+="✔ $LOG archived to $ARCHIVE_NAME\n"
        ((SUCCESS_COUNT++))

      else
        REPORT+="✘ Failed to archive $LOG\n"
        rm -f "$TMP_FILE"
        ((FAIL_COUNT++))
      fi

    else
      REPORT+="✘ Failed to create temporary copy for $LOG\n"
      ((FAIL_COUNT++))
    fi

  else
    REPORT+="⚠ $LOG not found\n"
  fi
done

REPORT+="\nSummary:\nSuccessful: $SUCCESS_COUNT\nFailed: $FAIL_COUNT"

ESCAPED_REPORT=$(printf '%s' "$REPORT" | sed ':a;N;$!ba;s/\n/\\n/g')

curl -H "Content-Type: application/json" \
     -X POST \
     -d "{\"content\":\"$ESCAPED_REPORT\"}" \
     "$WEBHOOK_URL" > /dev/null 2>&1