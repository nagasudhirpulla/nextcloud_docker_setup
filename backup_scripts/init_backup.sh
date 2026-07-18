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

# Ensure the backup directory exists before initializing
mkdir -p "${BACKUPS_DIR}"

echo "Initializing Restic repository at: ${BACKUPS_DIR}"
echo "==================================================="

docker run --rm \
  -v "${BACKUPS_DIR}:/repo" \
  -e RESTIC_PASSWORD="${RESTIC_PASSWORD}" \
  restic/restic \
  init -r /repo