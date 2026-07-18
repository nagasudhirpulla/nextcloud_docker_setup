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

echo "Listing all available Restic snapshots..."
echo "==================================================="

docker run --rm \
  -v "${BACKUPS_DIR}:/repo" \
  -e RESTIC_PASSWORD="${RESTIC_PASSWORD}" \
  restic/restic \
  -r /repo snapshots