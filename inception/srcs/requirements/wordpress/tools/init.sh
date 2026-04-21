#!/bin/bash

# Ensure runtime directory exists (fix PID error)
mkdir -p /run/php

# Configure php-fpm
sed -i 's|listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf

# Go to correct directory
cd /var/www/wordpress || exit 1

# Debug (you can remove later)
ls -la

# Setup config only if missing
if [ ! -f "wp-config.php" ]; then
    echo "Configuring WordPress..."

    cp wp-config-sample.php wp-config.php

    sed -i "s/database_name_here/${MYSQL_DATABASE}/" wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/" wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/" wp-config.php
    sed -i "s/localhost/mariadb/" wp-config.php
fi

exec php-fpm7.4 -F
