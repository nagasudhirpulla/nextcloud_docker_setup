#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$(readlink -f "$0")")" || exit 1

# Load environment variables
if [ -f ./config.sh ]; then
    source ./config.sh
else
    echo "Error: config.sh file not found!"
    exit 1
fi

echo "==================================================="
echo "  NEXTCLOUD and POSTGRESQL BACKUP SCRIPT"
echo "==================================================="
echo

echo "[1/7] running nextcloud cron job..."
docker exec -u www-data "$nextcloud_container" php /var/www/html/cron.php

echo "[2/7] enabling nextcloud maintenance mode..."
docker exec -u www-data "$nextcloud_container" php occ maintenance:mode --on
echo ""

echo "[3/7] create a clean database dump directly into the db storage volume"
docker exec "$db_container" pg_dump -U "$db_user" -d "$db_name" -F c -f /var/lib/postgresql/nextcloud_backup.dump
echo ""

echo "[4/7] running the daily deduplicated backup (files + database logical backup file)..."
# This maps both volumes into a single /data directory inside the restic container
docker run --rm \
  --mount source="$nextcloud_volume",target=/data/nextcloud_files \
  --mount source="$db_volume",target=/data/postgres_raw_data \
  -v "$backups_dir:/repo" \
  -e RESTIC_PASSWORD="$restic_password" \
  restic/restic \
  -r /repo backup \
  /data/nextcloud_files \
  /data/postgres_raw_data/nextcloud_backup.dump
echo ""

echo "[5/7] disabling nextcloud maintenance mode..."
docker exec -u www-data "$nextcloud_container" php occ maintenance:mode --off
echo ""

echo "[6/7] pruning old data (keeping last 365 days)..."
docker run --rm \
  -v "$backups_dir:/repo" \
  -e RESTIC_PASSWORD="$restic_password" \
  restic/restic \
  -r /repo forget \
  --keep-within "$restic_retention" --prune
echo ""

echo "[7/7] cleaning up temporary dump file from the live db volume"
docker exec "$db_container" rm /var/lib/postgresql/nextcloud_backup.dump

echo "Backup process complete! Both volumes are securely stored on your Linux host."
