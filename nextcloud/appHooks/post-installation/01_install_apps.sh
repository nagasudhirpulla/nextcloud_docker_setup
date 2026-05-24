# # set default app to dashboard
# php occ config:system:set defaultapp --value=dashboard

# install nextcloud office app
php occ app:install richdocuments

# install nextcloud talk app
php occ app:install spreed

# install nextcloud drawio app
php occ app:install drawio

# # install nextcloud built in code server instead of a separate collabora online server
# php -d memory_limit=512M occ app:install richdocumentscode

# occ commands for collabora/code server configurations in nextcloud - https://github.com/nextcloud/richdocuments/blob/main/docs/install.md#configure-the-app-from-the-commandline

# set collabora online server URL
php occ config:app:set richdocuments wopi_url --value="https://$COLLABORA_FQDN"

# Disable SSL certificate verification (use only for testing!)
php occ config:app:set richdocuments disable_certificate_verification --value="yes"

# occ commands for nextcloud talk server configuration in nextcloud - https://nextcloud-talk.readthedocs.io/en/latest/occ/#talksignalingadd
# add high performance backend (signaling server) for nextcloud talk
php occ talk:signaling:add "https://${SIGNAL_FQDN}" "${SIGNALING_SECRET}"

# add stun server for nextcloud talk
php occ talk:stun:add "${SIGNAL_FQDN}:3478"
# remove default stun server
php occ talk:stun:delete "stun.nextcloud.com:443"

# configure turn server for nextcloud talk
php occ talk:turn:add "turn" "${SIGNAL_FQDN}:3478" "udp,tcp" --secret="${TURN_SECRET}"
