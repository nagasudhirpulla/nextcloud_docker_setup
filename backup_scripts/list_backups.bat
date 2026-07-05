@echo off
:: Navigate to the script's directory
cd /d "%~dp0"

CALL config.bat

docker run --rm ^
-v "%BACKUPS_DIR%:/repo" ^
-e RESTIC_PASSWORD=%RESTIC_PASSWORD% ^
restic/restic ^
-r /repo snapshots