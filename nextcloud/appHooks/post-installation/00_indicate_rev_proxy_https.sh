php occ config:system:set overwriteprotocol --value=https
proxy_ip=$(getent hosts proxy | awk '{print $1}')
php occ config:system:set trusted_proxies 0 --value=$proxy_ip/32
# php occ config:system:set trusted_proxies 1 --value=127.0.0.1
php occ config:system:set overwritehost --value="$NEXTCLOUD_FQDN"
php occ config:system:set overwrite.cli.url --value="https://$NEXTCLOUD_FQDN"
php occ config:system:set forwarded_for_headers 0 --value="HTTP_X_FORWARDED_FOR"
# php occ config:system:set overwritewebroot --value="/"