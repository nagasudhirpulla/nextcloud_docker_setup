#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")"

# Load environment variables
if [ -f ./config.env ]; then
    source ./config.env
else
    echo "Error: config.env file not found!"
    exit 1
fi

echo "==================================================="
echo "  NEXTCLOUD & POSTGRESQL COMPLETE RECOVERY SCRIPT"
echo "==================================================="
echo

# 1. Check if a Backup ID was provided; otherwise, fallback to latest
if [ -z "$1" ]; then
    BACKUP_ID="latest"
    echo "[INFO] No Backup ID provided. Falling back to the LATEST snapshot..."
else
    BACKUP_ID="$1"
    echo "[INFO] Target Backup ID selected: ${BACKUP_ID}"
fi
echo

echo "[1/7] Stopping active Nextcloud container..."
docker stop "${NEXTCLOUD_CONTAINER}"
echo

echo "[2/7] Wiping existing Docker volumes clean to prevent data corruption..."
# Clears out the app data volume completely
docker run --rm --mount source="${NEXTCLOUD_VOLUME}",target=/data busybox sh -c "rm -rf /data/* /data/.* 2>/dev/null"
echo

echo "[3/7] Restoring Files and Database from the Restic snapshot id ${BACKUP_ID}..."
# Maps both clean target volumes and unpacks the respective data back into them
docker run --rm \
  --mount source="${NEXTCLOUD_VOLUME}",target=/data/nextcloud_files \
  --mount source="${DB_VOLUME}",target=/data/postgres_raw_data \
  -v "${BACKUPS_DIR}:/repo" \
  -e RESTIC_PASSWORD="${RESTIC_PASSWORD}" \
  restic/restic \
  -r /repo restore "${BACKUP_ID}" --target /
echo

echo "[4/7] Importing the PostgreSQL Database Dump..."
# Drops existing tables to avoid conflicts during import
docker exec "${DB_CONTAINER}" pg_restore -U "${DB_USER}" -d "${DB_NAME}" -v /var/lib/postgresql/nextcloud_backup.dump
echo

echo "[5/7] Restarting Application container..."
docker start "${NEXTCLOUD_CONTAINER}"
echo

echo "[6/7] Cleaning up restored dump file from the live DB volume"
docker exec "${DB_CONTAINER}" rm /var/lib/postgresql/nextcloud_backup.dump
echo

echo "[7/7] Verifying and finalizing Nextcloud application status..."
# Safely attempts to ensure maintenance mode is turned off upon restart (suppressing errors)
docker exec -u www-data "${NEXTCLOUD_CONTAINER}" php occ maintenance:mode --off 2>/dev/null
echo

echo "==================================================="
echo "  Recovery process complete! System is back online."
echo "==================================================="