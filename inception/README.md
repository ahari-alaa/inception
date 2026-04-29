*This project has been created as part of the 42 curriculum by ahari.*

# Inception

## Table of Contents

- [Description](#description)
- [Project Description](#project-description)
  - [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
- [Architecture](#architecture)
- [Services](#services)
- [Instructions](#instructions)
- [Resources](#resources)

---

## Description

Inception is a system administration project from the 42 curriculum. The goal is to set up a small infrastructure composed of multiple services running inside **Docker containers**, all orchestrated with **Docker Compose** inside a virtual machine.

The infrastructure includes:

- **NGINX** — the sole entry point, serving as a reverse proxy with TLSv1.2/TLSv1.3 encryption on port 443.
- **WordPress** — a CMS powered by PHP-FPM, installed and configured automatically via WP-CLI.
- **MariaDB** — the relational database backend for WordPress.

Every container is built from **Debian Bullseye** — no pre-built images from Docker Hub are used. Sensitive credentials are handled via Docker secrets (never hardcoded), and persistent data is stored on bind-mounted host volumes.

---

## Project Description

### Why Docker?

This project uses **Docker** to containerize each service into its own isolated environment. Docker is an open-source platform for building, shipping, and running applications using containers. We use Docker to package an application and its dependencies inside a container so the program can run the same way on different machines or systems.

A container is a completely isolated environment — it can have its own processes, its own network interfaces, and its own mounts, just like a virtual machine, except all containers share the same OS kernel.

Docker Compose orchestrates the multi-container setup, defining networks, volumes, secrets, and dependencies declaratively in a single `docker-compose.yml` file. Each service has its own `Dockerfile` that builds from `debian:bullseye`, installs only the required packages, and runs a custom entrypoint script.

---

### Virtual Machines vs Docker

A virtual machine runs a complete separate operating system on top of a hypervisor. Its full stack is: Hardware → Host OS → Hypervisor → Guest OS → App. Each VM carries its own kernel, which makes it heavy, slow to start, and expensive in resources — each VM reserves CPU, RAM, and disk for a full OS.

A Docker container shares the host OS kernel and isolates only at the process level using namespaces and cgroups. Its stack is: Hardware → Host OS → Docker Engine → Container → App. Containers start in seconds and only consume what the process needs.

The key difference is that VMs run a separate operating system and require a hypervisor to manage them, while containers share the same OS kernel and are isolated only through Linux namespaces and cgroups. Docker was chosen for this project because the goal is to run multiple lightweight Linux services that share the same kernel — a full VM per service would be wasteful.

---

### Secrets vs Environment Variables

Environment variables are passed directly into a container at runtime. They are convenient but visible through `docker inspect` or `/proc/<pid>/environ`, which makes them a risk for sensitive data like passwords. They are suited for non-sensitive configuration such as database names, usernames, and domain names.

Secrets are stored as files mounted at `/run/secrets/` inside the container. They are not exposed through `docker inspect` or process listings and are only accessible inside the containers that explicitly declare them. They are designed specifically for sensitive data like passwords.

In this project all passwords (database, WordPress admin, WordPress user) are stored as text files in the `secrets/` directory and injected via Docker Compose secrets. Entrypoint scripts read them from `/run/secrets/` at startup. Non-sensitive configuration (database name, domain, usernames, emails) is passed via `.env` environment variables.

---

### Docker Network vs Host Network

With the host network mode a container shares the host machine's network stack directly — no port mapping is needed but there is no network isolation at all. A container using host networking can bind to any port on the host, which is a security risk.

With a Docker bridge network each container gets its own virtual network namespace. Ports must be declared explicitly but containers are isolated from the host and from each other unless connected deliberately. Docker's built-in DNS lets containers resolve each other by service name — for example WordPress connects to MariaDB simply via `mariadb:3306`.

This project uses a custom bridge network (`inception_network`). This allows containers to communicate by name, keeps services isolated from the host, and only exposes port 443 through NGINX to the outside.

---

### Docker Volumes vs Bind Mounts

A bind mount links a specific path on the host filesystem directly into a container. It is useful for development and live code reloading, but it is tied to a particular host path, which makes it fragile and non-portable.

A Docker volume is managed entirely by Docker and stored under `/var/lib/docker/volumes/`. Volumes survive container deletion, are portable, and are the recommended way to persist data. Containers like WordPress and MariaDB contain data that would vanish if the container is destroyed — this is why volumes are used, to prevent data loss on container deletion or rebuild.

In this project named volumes with bind driver options are used — effectively bind mounts declared as named volumes in Compose. WordPress data is persisted at `/home/ahari/data/wordpress` and MariaDB data at `/home/ahari/data/mariadb`. This gives Docker Compose the lifecycle management of named volumes while storing data at predictable host paths.

---

## Architecture

```
                   ┌─────────────────────────────────────┐
      Port 443     │        inception_network (bridge)   │
  ───────────────► │                                     │
                   │  ┌───────┐   ┌───────────┐  ┌─────────┐
                   │  │ NGINX ├──►│ WordPress ├─►│ MariaDB │
                   │  │ :443  │   │ PHP-FPM   │  │  :3306  │
                   │  └───────┘   │  :9000    │  └─────────┘
                   │              └───────────┘           │
                   └─────────────────────────────────────-┘

                   Volumes:
                   ─────────
                   WordPress ──► /home/ahari/data/wordpress
                   MariaDB   ──► /home/ahari/data/mariadb
```

---

## Services

### Mandatory

| Service   | Base Image        | Internal Port | Exposed Port | Role                   |
|-----------|-------------------|---------------|--------------|------------------------|
| NGINX     | debian:bullseye   | 443           | 443          | TLS reverse proxy      |
| WordPress | debian:bullseye   | 9000          | —            | CMS via PHP-FPM        |
| MariaDB   | debian:bullseye   | 3306          | —            | Relational database    |

### Volumes

| Volume    | Host Path                    | Container Path      | Used By             |
|-----------|------------------------------|---------------------|---------------------|
| WordPress | `/home/ahari/data/wordpress` | `/var/www/wordpress`| NGINX, WordPress    |
| MariaDB   | `/home/ahari/data/mariadb`   | `/var/lib/mysql`    | MariaDB             |

### Secrets

| Secret               | File                            | Used By             |
|----------------------|---------------------------------|---------------------|
| `db_password`        | `secrets/db_password.txt`       | MariaDB, WordPress  |
| `db_root_password`   | `secrets/db_root_password.txt`  | MariaDB             |
| `wp_admin_password`  | `secrets/wp_admin_password.txt` | WordPress           |
| `wp_user_password`   | `secrets/wp_user_password.txt`  | WordPress           |

---

## Instructions

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Make** installed
- A Linux host or VM (containers bind-mount to `/home/ahari/data/`)
- Add the domain to your `/etc/hosts`:
  ```
  127.0.0.1  ahari.42.fr
  ```

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ahari/Inception42.git
   cd Inception42
   ```

2. **Set your secret passwords** in the `secrets/` directory:
   ```bash
   echo "your_db_password"       > secrets/db_password.txt
   echo "your_db_root_password"  > secrets/db_root_password.txt
   echo "your_wp_admin_password" > secrets/wp_admin_password.txt
   echo "your_wp_user_password"  > secrets/wp_user_password.txt
   ```

3. **Create the `.env` file** with your configuration:
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

4. **Create the data directories** on the host:
   ```bash
   mkdir -p /home/ahari/data/wordpress /home/ahari/data/mariadb
   ```

### Build & Run

```bash
make        # Build images and start all services
make down   # Stop all services
make clean  # Stop, remove containers and volumes
make re     # Rebuild everything from scratch
```

### Access

| Service   | URL                      |
|-----------|--------------------------|
| WordPress | `https://ahari.42.fr`    |

---

## Resources

- [docs.docker.com](https://docs.docker.com) — Official Docker documentation. Used as the main reference for Docker concepts, CLI commands, Dockerfile syntax, Docker Compose, volumes, networks, and secrets
- [coursera.org](https://www.coursera.org) — Used to understand and reinforce Docker core concepts including containers, images, and how Docker works as a platform
- [medium.com](https://medium.com) — Used for research on dockerd (the Docker Daemon) and gRPC. gRPC is a modern high-performance framework that evolved the age-old remote procedure call protocol and allows communication between different applications as if they were local objects
- [mariadb.org](https://mariadb.org) — Official MariaDB documentation. MariaDB is a general-purpose open-source relational database management system that can be used for high-availability transaction data and analytics as an embedded server
- [youtube.com](https://www.youtube.com) — Used to understand SSL/TLS, how HTTPS works, the difference between TLSv1.2 and TLSv1.3, and why NGINX is configured as the sole TLS entry point in this infrastructure

### AI Usage

Two AI tools were used during this project: Claude (claude.ai) and ChatGPT.

Both were used for grammar correction throughout the research notes and written content, for asking questions to get clearer explanations on topics such as Docker internals, container isolation, and networking concepts, and for writing comments inside the Dockerfiles to explain what each instruction does.

---

## Project Structure

```
Inception42/
├── Makefile
├── README.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```