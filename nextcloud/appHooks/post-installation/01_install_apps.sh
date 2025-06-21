# install nextcloud office app
php occ app:install richdocuments

# install nextcloud talk app
php occ app:install spreed

# install nextcloud drawio app
php occ app:install drawio

# install nextcloud built in code server
# php -d memory_limit=512M occ app:install richdocumentscode

# set collabora online server URL
php occ config:app:get richdocuments wopi_url --value="https://collabora.local"