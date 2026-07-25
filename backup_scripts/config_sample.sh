#!/bin/bash
export db_container="db"
export nextcloud_container="app"
export nextcloud_volume="nextcloud_nextcloud"
export db_volume="nextcloud_db"
export db_user="nextcloud"
export db_name="nextcloud"
export restic_password="password123"
export restic_retention="365d"

# Gets the directory of the current script and looks one level up
export backups_dir="$(dirname "$(readlink -f "$0")")/../backups"