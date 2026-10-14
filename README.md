# moodle-docker

A Docker image with the latest **Moodle 5.0** release (PHP 8.2 + Apache) and everything it needs,
rebuilt automatically by GitHub Actions to pick up the latest minor version.

The image is published as `ghcr.io/calaxo/moodle-docker:latest`.

The goal is to make it ready for load balancing (Kubernetes or Docker Swarm): the shared
directories (`temp`, `cache`, `backuptemp`) are moved to a separate volume that can be replicated
between nodes. Ideas and improvements are welcome via Issues.

## What's inside

- `php:8.2-apache` with the PHP extensions Moodle requires (`gd`, `mysqli`, `zip`, `intl`, `opcache`, `soap`)
- Moodle `stable500` downloaded from download.moodle.org at build time
- PHP settings tuned for Moodle (`max_input_vars = 5000`, `memory_limit = 512M`, 100 MB uploads)
- The Moodle cron (`admin/cli/cron.php`) installed for `www-data`
- An entrypoint that generates `config.php` from environment variables on first start

## Quick start

```bash
git clone https://github.com/calaxo/moodle-docker.git
cd moodle-docker
cp .env.example .env      # then change the passwords
docker compose up -d
```

Moodle is then available at <http://localhost:8080>. The Compose file serves plain HTTP;
put a reverse proxy in front of it for HTTPS.

### Optional backup service

`docker-compose.yml` also declares a `backexp` service (`ghcr.io/calaxo/moodle-backup:latest`).
It mounts the `moodledata` volume and writes Moodle backups to `/var/www/moodledata/backups`
(`BACKUP_DIR`). Its image is private and not part of this repository, so the service sits behind
the `backup` Compose profile: a plain `docker compose up -d` starts only Moodle and MariaDB.

If you have access to that image (or replace it with your own), start it with:

```bash
docker compose --profile backup up -d
# or set it once, e.g. in .env or in your deployment tool:
COMPOSE_PROFILES=backup
```

## Configuration

Environment variables read by the image (`docker-entrypoint.sh`):

| Variable | Default | Description |
|---|---|---|
| `DB_TYPE` | — | `mysqli`, `mariadb`, `pgsql`, `auroramysql` or `sqlsrv` |
| `DB_HOST` | — | Database host |
| `DB_NAME` | — | Database name |
| `DB_USER` | — | Database user |
| `DB_PASS` | — | Database password |
| `MOODLE_URL` | — | Public URL of the site (`$CFG->wwwroot`) |
| `MOODLE_DATA_DIR` | `/var/www/moodledata` | Moodle data directory (`$CFG->dataroot`) |
| `MOODLE_CLUSTER_DIR` | `/var/www/toreplicate` | Shared directory for `temp`, `cache` and `backuptemp` |
| `START_MOODLE_SERVER` | `true` | `false` keeps the container idle (useful to run migrations first) |
| `MOODLE_REVERSE_PROXY` | — | Informative only for now: the entrypoint always enables `reverseproxy` and `sslproxy` |

`config.php` is generated only if it does not exist yet.

In `docker-compose.yml`, the database values come from `.env` (see [`.env.example`](.env.example)),
with an extra `DB_ROOT_PASS` for the MariaDB root account. Never commit your `.env` file.

## Automatic builds

The workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) rebuilds and pushes the
image every two weeks, and can also be started manually (`workflow_dispatch`).

## License

The files in this repository (Dockerfile, entrypoint, Compose file, workflow) are released under the
[MIT](LICENSE) license © calaxo: you can reuse, modify and redistribute them, including
commercially, as long as you keep the copyright and license notice. A link back to this repository
is appreciated.

Moodle itself is not part of this repository: it is downloaded at build time and is distributed
under the [GNU GPL v3 or later](https://moodledev.io/general/license). The published Docker image therefore
contains GPL software and its redistribution must follow the GPL.
