# 1. Enforce HTTPS for all generated Nextcloud absolute URLs
php occ config:system:set overwriteprotocol --value="https"

# 2. Dynamically fetch the "proxy" container IP and append it safely to trusted_proxies
proxy_ip=$(getent hosts proxy | awk '{print $1}')
php occ config:system:set trusted_proxies 0 --value="$proxy_ip"
php occ config:system:set trusted_proxies 1 --value="127.0.0.1"
php occ config:system:set trusted_proxies 2 --value="app"

# 3. Lock down the public-facing domain name
php occ config:system:set overwritehost --value="$NEXTCLOUD_FQDN"

# 4. Ensure background cron jobs generate correct URLs in emails/notifications
php occ config:system:set overwrite.cli.url --value="https://$NEXTCLOUD_FQDN"

# # config.php location in nextcloud container is /var/www/html/config/config.php. Check here if the values are set correctly 