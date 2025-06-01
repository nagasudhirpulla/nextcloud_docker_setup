set -ex
bash /entrypoint.sh
# TODO comment out exec "$@" in entrypoint using sed
su -www-data -c "php occ config:system:set overwriteprotocol --value=https"
exec "$@"