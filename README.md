## Overview
This repository is a docker compose based setup for nextcloud along with 
* Collabora (for web based document editing support) 
* Redis caching
* Nextcloud talk 
* Apache reverse proxy

![architecture.svg](./img/architecture.svg)

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

    * Create self signed SSLs by running `omgwtfssl`, `omgwtfssl2`, `omgwtfssl3` containers
    ```bash
    docker compose -f self_signed_certs_gen.yaml up -d --build omgwtfssl
    docker compose -f self_signed_certs_gen.yaml up -d --build omgwtfssl2
    docker compose -f self_signed_certs_gen.yaml up -d --build omgwtfssl3
    ```
    * For a CA-issued certificate, skip the self-signed generators and instead save the valid cert/key/chain into the `certs` folder.
      Also set `SKIP_CERT_VERIFY=false` in `.env` so services require trusted certificate verification.

    * Run `collabora` container (for nextcloud office online editor)
    ```bash
    docker compose -f nextcloud.yaml up -d --build collabora
    ```

    * Run `nc-talk` container (for nextcloud talk high performance backend)
    ```bash
    docker compose -f nextcloud.yaml up -d --build nc-talk
    ```

    * Run `proxy` container (reverse proxy for nextcloud)
    ```bash
    docker compose -f nextcloud.yaml up -d --build proxy
    ```

    * Run `app` container (nextcloud)
    ```bash
    docker compose -f nextcloud.yaml up -d --build app
    ```
* If the post-installation scripts could not run correctly due to some reason, they can be run again using the following scripts

```batch
docker exec -u www-data -i app sh < .\nextcloud\appHooks\post-installation\00_indicate_rev_proxy_https.sh
docker exec -u www-data -i app sh < .\nextcloud\appHooks\post-installation\01_install_apps.sh
```

To run script from Linux based workstations, use the following commands instead
```bash
docker exec -u www-data -i app sh < ./nextcloud/appHooks/post-installation/00_indicate_rev_proxy_https.sh
docker exec -u www-data -i app sh < ./nextcloud/appHooks/post-installation/01_install_apps.sh
```

## Run cron nextcloud cron job
* run `docker exec -u www-data app php /var/www/html/cron.php` every 5 mins so that cron.php is run the machine running the nextcloud docker container
* Run `sudo crontab -e -u www-data` and add the line `*/5 * * * * docker exec -u www-data app php /var/www/html/cron.php`

## Backup
* Nextcloud files and database logical backup file are backed up using `restic` backup
* `run_backup.bat` script runs backup and stores it in the restic backup vault
* All the backup and restore scripts will require a `config.bat` file in the `backup_scripts` directory that contains the following configuration variables

```bat
REM config.bat
set "DB_CONTAINER=db"
set "NEXTCLOUD_CONTAINER=app"
set "NEXTCLOUD_VOLUME=nextcloud_nextcloud"
set "DB_VOLUME=nextcloud_db"
set "DB_USER=nextcloud"
set "DB_NAME=nextcloud"
set "RESTIC_PASSWORD=password123"
set "BACKUPS_DIR=%cd%\..\backups"
```

### Database backup
Database logical backup and restore is done in run_backup.sh using `pg_dump` and `pg_restore` postgres commands

### List all backups
`list_backups.sh` will display restic backup IDs that are present in the backup storage

### Restore latest or specific bcakup using its ID
* when `restore_backup.bat` is run, latest snapshot is restored
* when `restore_backup.bat a1b2c3d4` is run, snapshot id `a1b2c3d4` is restored

## .env file
```bash
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
# set to "true" for local self-signed certificates, or "false" when using a CA-issued valid SSL certificate
SKIP_CERT_VERIFY=true
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
* nextcloud talk occ commands - https://nextcloud-talk.readthedocs.io/en/latest/occ/
