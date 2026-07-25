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


# Initialize the Restic repository
docker run --rm \
  -v "$backups_dir:/repo" \
  -e RESTIC_PASSWORD="$restic_password" \
  restic/restic \
  init -r /repo
