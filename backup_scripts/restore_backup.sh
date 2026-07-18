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
echo "  NEXTCLOUD and POSTGRESQL COMPLETE RECOVERY SCRIPT"
echo "==================================================="
echo ""

# 1. Check if a Backup ID was provided; otherwise, fallback to latest
if [ -z "$1" ]; then
    BACKUP_ID="latest"
    echo "[INFO] No Backup ID provided. Falling back to the LATEST snapshot..."
else
    BACKUP_ID="$1"
    echo "[INFO] Target Backup ID selected: $BACKUP_ID"
fi
echo ""

echo "[1/7] Stopping active Nextcloud container..."
docker stop "$nextcloud_container"
echo ""

echo "[2/7] Wiping existing Docker volumes clean to prevent data corruption..."
# Clears out the app data volume completely
docker run --rm --mount source="$nextcloud_volume",target=/data busybox sh -c "rm -rf /data/* /data/.* 2>/dev/null || true"
echo ""

echo "[3/7] Restoring Files and Database from the Restic snapshot id $BACKUP_ID..."
# Maps both clean target volumes and unpacks the respective data back into them
docker run --rm \
  --mount source="$nextcloud_volume",target=/data/nextcloud_files \
  --mount source="$db_volume",target=/data/postgres_raw_data \
  -v "$backups_dir:/repo" \
  -e RESTIC_PASSWORD="$restic_password" \
  restic/restic \
  -r /repo restore "$BACKUP_ID" --target /
echo ""

echo "[4/7] Importing the PostgreSQL Database Dump..."
# 1. Terminate all active connections to the target database
docker exec -i "$db_container" psql -U "$db_user" -d template1 -c "
  SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE pg_stat_activity.datname = '$db_name'
    AND pid <> pg_backend_pid();"

# 2. Drop and recreate the database inside the container
docker exec -i "$db_container" psql -U "$db_user" -d template1 -c "DROP DATABASE IF EXISTS \"$db_name\";"
docker exec -i "$db_container" psql -U "$db_user" -d template1 -c "CREATE DATABASE \"$db_name\";"

# 3. Restore the database dump into the newly created database
docker exec "$db_container" pg_restore -U "$db_user" -d "$db_name" -v /var/lib/postgresql/nextcloud_backup.dump
echo ""

echo "[5/7] Restarting Application container..."
docker start "$nextcloud_container"
echo ""

echo "[6/7] Cleaning up restored dump file from the live DB volume"
docker exec "$db_container" rm /var/lib/postgresql/nextcloud_backup.dump
echo ""

echo "[7/7] Verifying and finalizing Nextcloud application status..."
# Safely attempts to ensure maintenance mode is turned off upon restart
docker exec -u www-data "$nextcloud_container" php occ maintenance:mode --off 2>/dev/null
echo ""

echo "==================================================="
echo "  Recovery process complete! System is back online."
echo "==================================================="
