# Developer Documentation — Inception

This document explains how to set up, build, and manage the Inception infrastructure from a developer perspective.

---

## Prerequisites

Make sure the following tools are installed on your machine before starting:

- **Docker** — engine version 24.x or higher
- **Docker Compose** — the Compose plugin (`docker compose`, not the legacy `docker-compose`)
- **Make** — to use the Makefile shortcuts
- **Git** — to clone the repository

Check your versions:
```bash
docker --version
docker compose version
make --version
```

---

## Set Up the Environment from Scratch

### 1. Clone the repository

```bash
git clone https://github.com/ahari/Inception42.git
cd Inception42
```

### 2. Create the secrets files

Passwords are never stored in the repository. You must create the `secrets/` files manually before building:

```bash
echo "your_db_password"       > secrets/db_password.txt
echo "your_db_root_password"  > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password"  > secrets/wp_user_password.txt
```

Each file must contain only the password value — no extra spaces or newlines.

Docker Compose mounts these files into the containers at `/run/secrets/<secret_name>`. The entrypoint scripts read them with:
```bash
PASSWORD=$(cat /run/secrets/secret_name)
```

### 3. Create the .env file

The `.env` file holds all non-sensitive configuration. Create it at the root of the repository:

```env
DOMAIN_NAME=ahari.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_HOST=mariadb
WP_URL=https://ahari.42.fr
WP_TITLE=Inception
WP_ADMIN_USER=ahari
WP_ADMIN_EMAIL=ahari@gmail.com
WP_USER=user1
WP_USER_EMAIL=user@gmail.com
```

Docker Compose reads this file automatically and injects the values as environment variables into the containers.

### 4. Create the data directories on the host

The volumes bind-mount to specific paths on the host machine. Create them before the first run:

```bash
mkdir -p /home/ahari/data/wordpress
mkdir -p /home/ahari/data/mariadb
```

If these directories do not exist, Docker will create them as root and the containers may fail to write to them.

### 5. Add the domain to /etc/hosts

```bash
echo "127.0.0.1 ahari.42.fr" | sudo tee -a /etc/hosts
```

---

## Build and Launch the Project

The Makefile wraps all Docker Compose commands. From the root of the repository:

```bash
make        # Build all images and start all containers in detached mode
make down   # Stop all running containers
make clean  # Stop containers and remove volumes (deletes all persisted data)
make re     # Full rebuild — equivalent to clean then make
```

What `make` runs internally:
```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

To build a single service image without starting it:
```bash
docker compose -f srcs/docker-compose.yml build mariadb
```

---

## Manage Containers and Volumes

### Container status and logs

```bash
docker ps                          # List all running containers
docker ps -a                       # List all containers including stopped ones
docker compose logs -f             # Follow logs from all services
docker compose logs -f wordpress   # Follow logs from a specific service
```

### Execute commands inside a container

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Connect to MariaDB from inside its container

```bash
docker exec -it mariadb mariadb -u root -p
# enter the password from secrets/db_root_password.txt
```

### Restart a single service without rebuilding

```bash
docker compose -f srcs/docker-compose.yml restart wordpress
```

### Rebuild and restart a single service

```bash
docker compose -f srcs/docker-compose.yml up --build -d wordpress
```

### Inspect a container (environment, mounts, network)

```bash
docker inspect mariadb
docker inspect wordpress
```

Note: secrets are not visible through `docker inspect` — only environment variables are shown, which is why passwords are passed as secrets and not env vars.

### List all Docker volumes

```bash
docker volume ls
```

### Remove a specific volume manually

```bash
docker volume rm srcs_mariadb_data
docker volume rm srcs_wordpress_data
```

---

## Where Data Is Stored and How It Persists

### Volume configuration

The project uses named volumes with the `bind` driver, declared in `docker-compose.yml`:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mariadb

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress
```

This means Docker treats them as named volumes (with lifecycle managed by Compose) while the actual files are stored at predictable paths on the host filesystem.

### Where the files are on disk

| Data        | Host path                    | Container path       |
|-------------|------------------------------|----------------------|
| MariaDB     | `/home/ahari/data/mariadb`   | `/var/lib/mysql`     |
| WordPress   | `/home/ahari/data/wordpress` | `/var/www/wordpress` |

### How persistence works

When a container is stopped or removed, the data on the host path remains untouched. The next time the container starts, it finds the existing data and continues from where it left off.

The only way to lose data is to run `make clean`, which removes the Docker volumes, or to manually delete the host directories:
```bash
sudo rm -rf /home/ahari/data/mariadb
sudo rm -rf /home/ahari/data/wordpress
```

### First-run initialization

Each entrypoint script checks whether the service has already been initialized before running the setup commands. For example the MariaDB script checks if `/var/lib/mysql/wordpress_db` already exists before creating the database. This prevents re-initialization on every container restart and makes the containers safe to stop and start freely.

---

## Project Structure Reference

```
Inception42/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                        # Password files — never committed to Git
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                        # Non-sensitive configuration
    ├── docker-compose.yml          # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile          # Builds from debian:bullseye
        │   ├── conf/               # MariaDB configuration file
        │   └── tools/              # Entrypoint script
        ├── nginx/
        │   ├── Dockerfile          # Builds from debian:bullseye
        │   ├── conf/               # NGINX config + self-signed TLS cert
        │   └── tools/              # Entrypoint script
        └── wordpress/
            ├── Dockerfile          # Builds from debian:bullseye
            ├── conf/               # PHP-FPM pool configuration
            └── tools/              # Entrypoint script (uses WP-CLI)
```