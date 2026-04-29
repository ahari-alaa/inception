#!/bin/bash

# Read passwords from Docker secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Start MariaDB temporarily in background (no networking, safe init mode)
mysqld --user=mysql --skip-networking &
MYSQL_PID=$!

# Wait until MariaDB is ready to accept connections
echo "Waiting for MariaDB to start..."
until mysqladmin -u root ping --silent 2>/dev/null; do
    sleep 1
done
echo "MariaDB is ready."

# Set root password and harden root access
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Only initialize database and user if not already done
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing database..."

    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Database initialized."
fi

# Shutdown the temporary background instance
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID

echo "Starting MariaDB in foreground..."
exec mysqld --user=mysql