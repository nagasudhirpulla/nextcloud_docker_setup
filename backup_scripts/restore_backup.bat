@echo off
:: Navigate to the script's directory
cd /d "%~dp0"

CALL config.bat

echo ===================================================
echo   NEXTCLOUD and POSTGRESQL COMPLETE RECOVERY SCRIPT
echo ===================================================
echo.

:: 1. Check if a Backup ID was provided; otherwise, fallback to latest
if "%~1" == "" (
    set "BACKUP_ID=latest"
    echo [INFO] No Backup ID provided. Falling back to the LATEST snapshot...
) else (
    set "BACKUP_ID=%~1"
    echo [INFO] Target Backup ID selected: %BACKUP_ID%
)
echo.

echo [1/7] Stopping active Nextcloud container...
docker stop %NEXTCLOUD_CONTAINER%

echo.
echo [2/7] Wiping existing Docker volumes clean to prevent data corruption...
:: Clears out the app data volume completely
docker run --rm --mount source=%NEXTCLOUD_VOLUME%,target=/data busybox sh -c "rm -rf /data/*"

echo.
echo [3/7] Restoring Files and Database from the Restic snapshot id %BACKUP_ID%...
:: Maps both clean target volumes and unpacks the respective data back into them
docker run --rm ^
  --mount source=%NEXTCLOUD_VOLUME%,target=/data/nextcloud_files ^
  --mount source=%DB_VOLUME%,target=/data/postgres_raw_data ^
  -v "%BACKUPS_DIR%:/repo" ^
  -e RESTIC_PASSWORD=%RESTIC_PASSWORD% ^
  restic/restic ^
  -r /repo restore %BACKUP_ID% --target /

echo.
echo [4/7] Importing the PostgreSQL Database Dump...
:: Terminate all active connections to the target database 
docker exec -i %db_container% psql -U %DB_USER% -d template1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_NAME%' AND pid <> pg_backend_pid();"

:: Drop and recreate the database inside the container
docker exec -i %DB_CONTAINER% psql -U %DB_USER% -d template1 -c "DROP DATABASE IF EXISTS \"%DB_NAME%\";"
docker exec -i %DB_CONTAINER% psql -U %DB_USER% -d template1 -c "CREATE DATABASE \"%DB_NAME%\";"

:: restore the database dump into the newly created database
docker exec %DB_CONTAINER% pg_restore -U %DB_USER% -d %DB_NAME% /var/lib/postgresql/nextcloud_backup.dump

echo.
echo [5/7] Restarting Application container...
docker start %NEXTCLOUD_CONTAINER%

echo.
echo [6/7] Cleaning up restored dump file from the live DB volume
docker exec %DB_CONTAINER% rm /var/lib/postgresql/nextcloud_backup.dump

echo.
echo [7/7] Verifying and finalizing Nextcloud application status...
:: Safely attempts to ensure maintenance mode is turned off upon restart
docker exec -u www-data %NEXTCLOUD_CONTAINER% php occ maintenance:mode --off 2>nul

echo.
echo ===================================================
echo   Recovery process complete! System is back online.
echo ===================================================
