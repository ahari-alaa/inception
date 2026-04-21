#!/bin/bash

# Start MariaDB temporarily
service mariadb start

# Wait for MariaDB to be ready
sleep 3

# Set root password (first time only, no password yet)
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

# Only initialize if database does not exist
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then

    echo "Initializing MariaDB database..."

    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${MYSQL_DATABASE};"

    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"

    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
fi

# Shutdown temporary server
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

# Start MariaDB in foreground as mysql user (IMPORTANT)
exec mysqld --user=mysql
