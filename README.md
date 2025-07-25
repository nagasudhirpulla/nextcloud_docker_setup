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

## Steps to run
* Create `db.env` and `.env` files

* Add the following dns entries in hosts file (since we are not using a real public domain)
```bash
127.0.0.1 nextcloud.local
127.0.0.1 collabora.local
127.0.0.1 signal.local
```
hosts file in windows is located at `C:\Windows\System32\drivers\etc\hosts`
hosts file in debian is located at `/etc/hosts`

* Run the whole docker compose with `docker compose -f 'nextcloud.yaml' up -d --build`

    * Create self signed SSLs by running `omgwtfssl1`, `omgwtfssl2`, `omgwtfssl3` containers
    ```bash
    docker compose -f 'nextcloud.yaml' up -d --build 'omgwtfssl1'
    docker compose -f 'nextcloud.yaml' up -d --build 'omgwtfssl2'
    docker compose -f 'nextcloud.yaml' up -d --build 'omgwtfssl3'
    ```

    * Run `collabora` container (for nextcloud office online editor)
    ```bash
    docker compose -f 'nextcloud.yaml' up -d --build 'collabora'
    ```

    * Run `nc-talk` container (for nextcloud talk high performance backend)
    ```bash
    docker compose -f 'nextcloud.yaml' up -d --build 'nc-talk'
    ```

    * Run `proxy` container (reverse proxy for nextcloud)
    ```bash
    docker compose -f 'nextcloud.yaml' up -d --build 'proxy'
    ```

## run cron nextcloud cron job
* run `docker exec -u www-data nextcloud php /var/www/html/cron.php` every 5 mins so that cron.php is run the machine running the nextcloud docker container
* Run `sudo crontab -e -u www-data` and add the line `*/5 * * * * docker exec -u www-data nextcloud php /var/www/html/cron.php`

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
* add nextcloud.local certificate to trusted certificates in etc/ssl/certs in nc-talk container
* get nextcloud fqdn from .env file instead of hardcoding in the line `php occ config:app:get richdocuments wopi_url --value="https://collabora.local"`
