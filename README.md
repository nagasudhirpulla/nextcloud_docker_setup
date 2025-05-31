docker setup for nextcloud

add trusted domains in nextcloud
```bash
./occ config:system:set trusted_domains 2 --value=nextcloud.local
./occ config:system:set trusted_domains 3 --value=192.168.0.3
```

config file location in nextcloud docker container - `/var/www/html/config/config.php`

https://help.nextcloud.com/t/howto-ubuntu-docker-nextcloud-talk-collabora/76430