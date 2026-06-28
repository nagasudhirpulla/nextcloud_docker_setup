@echo off
:: Navigate to the script's directory
cd /d "%~dp0"

CALL config.bat

echo [1/6] Enabling Nextcloud Maintenance Mode...
docker exec -u www-data %NEXTCLOUD_CONTAINER% php occ maintenance:mode --on

echo [2/6] Create a clean Database Dump directly into the DB storage volume
docker exec %DB_CONTAINER% pg_dump -U %DB_USER% -d %DB_NAME% -F c -f /var/lib/postgresql/nextcloud_backup.dump

echo [3/6] Running the daily deduplicated backup (Files + Database logical backup file)...
:: This maps both volumes into a single /data directory inside the Restic container
docker run --rm ^
  --mount source=%NEXTCLOUD_VOLUME%,target=/data/nextcloud_files ^
  --mount source=%DB_VOLUME%,target=/data/postgres_raw_data ^
  -v "%BACKUPS_DIR%:/repo" ^
  -e RESTIC_PASSWORD=%RESTIC_PASSWORD% ^
  restic/restic ^
  -r /repo backup ^
  /data/nextcloud_files ^
  /data/postgres_raw_data/nextcloud_backup.dump

echo [4/6] Disabling Nextcloud Maintenance Mode...
docker exec -u www-data %NEXTCLOUD_CONTAINER% php occ maintenance:mode --off

echo [5/6] Pruning old data (Keeping last 365 days)...
docker run --rm ^
  -v "%BACKUPS_DIR%:/repo" ^
  -e RESTIC_PASSWORD=%RESTIC_PASSWORD% ^
  restic/restic ^
  -r /repo forget ^
  --keep-within 365d --prune

echo [6/6] Cleaning up temporary dump file from the live DB volume
docker exec %DB_CONTAINER% rm /var/lib/postgresql/nextcloud_backup.dump

echo Backup process complete! Both volumes are securely stored on your Windows host.
