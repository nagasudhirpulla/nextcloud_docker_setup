## Overview
This repository is a docker compose based setup for nextcloud along with 
* Collabora (for web based document editing support) 
* Redis caching
* Nextcloud talk 
* Apache reverse proxy

## Docker instructions
* command to run docker compose - `docker compose -f .\nextcloud.yaml up -d --build`
* command to run container named app inside docker compose - `docker compose -f .\nextcloud.yaml up -d --build app`
* config file location in nextcloud docker container - `/var/www/html/config/config.php`
* access docker container as `www-data` user to run php occ commands - `docker exec -it -u www-data app bash`

## Tips
* Add trusted domains in Nextcloud with occ command
```bash
php occ config:system:set trusted_domains 2 --value=nextcloud.local
php occ config:system:set trusted_domains 3 --value=192.168.0.3
```

## .env file
```bash
REVPROXY_IPADDRESS=172.19.0.2
NEXTCLOUD_FQDN=nextcloud.local
NEXTCLOUD_UNAME=admin
NEXTCLOUD_PWD=learning
COLLABORA_FQDN=collabora.local
COLLABORA_UNAME=admin
COLLABORA_PWD=collaborapwd
SIGNAL_FQDN=signal.local
TURN_SECRET=secretpassword
SIGNALING_SECRET=secretpassword
INTERNAL_SECRET=secretpassword
```

## db.env file
```bash
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=learningsoftware
```

## References
* Nextlcoud `occ` command docs - https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/occ_command.html#using-the-occ-command
* Nextcloud docker setup blog - https://help.nextcloud.com/t/howto-ubuntu-docker-nextcloud-talk-collabora/76430
* Official docker nextcloud GitHub repo - https://github.com/nextcloud/docker
* Run user defined scripts in nextcloud docker image using hook scripts - https://github.com/nextcloud/docker?tab=readme-ov-file#auto-configuration-via-hook-folders
* nextcloud collabora integration guide - https://help.nextcloud.com/t/collabora-integration-guide/151879

## TODO
* High-performance backend section not working in talk settings