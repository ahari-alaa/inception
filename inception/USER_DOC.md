# User Documentation — Inception

This document explains how to use and manage the Inception infrastructure as an end user or administrator.

---

## What Services Are Provided

The stack runs three services, each in its own container:

**NGINX** is the only entry point to the infrastructure. It acts as a reverse proxy and handles all HTTPS traffic on port 443 using TLSv1.2/TLSv1.3. You never interact with WordPress or MariaDB directly from the outside — all traffic goes through NGINX.

**WordPress** is the content management system. It runs behind NGINX using PHP-FPM. This is where the website lives — you can read it as a visitor or manage it as an admin through the WordPress dashboard.

**MariaDB** is the database that stores all WordPress content (posts, users, settings). It runs internally and is not accessible from outside the Docker network.

---

## Start and Stop the Project

To start all services:
```bash
make
```

This builds the Docker images if they do not exist yet and starts all three containers in the background.

To stop all services without removing anything:
```bash
make down
```

To stop and remove containers, networks, and volumes (this will delete your data):
```bash
make clean
```

To rebuild everything from scratch:
```bash
make re
```

---

## Access the Website and Administration Panel

Before accessing the site, make sure your `/etc/hosts` file contains this line:
```
127.0.0.1  ahari.42.fr
```

If it is not there, add it:
```bash
echo "127.0.0.1 ahari.42.fr" | sudo tee -a /etc/hosts
```

| What              | URL                                  |
|-------------------|--------------------------------------|
| WordPress website | `https://ahari.42.fr`                |
| WordPress admin   | `https://ahari.42.fr/wp-admin`       |

Your browser will show a certificate warning because the TLS certificate is self-signed. This is expected — click "Advanced" and proceed to the site.

To log into the WordPress admin panel, use the admin credentials defined during setup (see the Credentials section below).

---

## Locate and Manage Credentials

Credentials are split into two places intentionally — passwords are kept separate from general configuration for security reasons.

**Passwords** are stored as plain text files inside the `secrets/` folder at the root of the repository:

| File                            | What it contains              |
|---------------------------------|-------------------------------|
| `secrets/db_password.txt`       | WordPress database user password |
| `secrets/db_root_password.txt`  | MariaDB root password         |
| `secrets/wp_admin_password.txt` | WordPress admin account password |
| `secrets/wp_user_password.txt`  | WordPress regular user password  |

To read a password:
```bash
cat secrets/wp_admin_password.txt
```

To change a password, edit the file and then rebuild the affected container:
```bash
echo "new_password" > secrets/wp_admin_password.txt
make re
```

**Non-sensitive configuration** (usernames, emails, domain, database name) is stored in the `.env` file at the root of the repository. Open it with any text editor to read or update these values.

> Never commit the `secrets/` folder or the `.env` file to Git. Both are listed in `.gitignore`.

---

## Check That the Services Are Running Correctly

To see the status of all running containers:
```bash
docker ps
```

You should see three containers running: `nginx`, `wordpress`, and `mariadb`. The status column should show `Up`.

To follow the live logs of all services at once:
```bash
docker compose logs -f
```

To check the logs of a specific service:
```bash
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

To check that NGINX is reachable and returning a valid response:
```bash
curl -k https://ahari.42.fr
```

The `-k` flag skips the self-signed certificate warning. If NGINX is running correctly you will see the HTML of the WordPress homepage.

To check that MariaDB is running inside its container:
```bash
docker exec -it mariadb mariadb -u root -p
```

Enter the root password from `secrets/db_root_password.txt` when prompted.