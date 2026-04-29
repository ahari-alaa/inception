#!/bin/bash
set -e

# Read passwords from Docker secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

mkdir -p /run/php
sed -i 's|listen = .*|listen = 9000|' /etc/php/7.4/fpm/pool.d/www.conf
cd /var/www/wordpress || exit 1

# Wait for MariaDB
echo "Waiting for database..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    echo "Still waiting for database..."
    sleep 2
done
echo "Database is ready!"

# Create wp-config.php if it does not exist
if [ ! -f "wp-config.php" ]; then
    echo "Configuring WordPress..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    echo "WordPress installed successfully!"

    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
    echo "WordPress user created!"
else
    echo "WordPress already installed, skipping."
fi

exec php-fpm7.4 -F