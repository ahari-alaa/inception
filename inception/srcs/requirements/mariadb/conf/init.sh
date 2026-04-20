#!/bin/bash

mysqld_safe &

# Wait until MariaDB is actually ready
until mysql -u root -h localhost --protocol=socket -e "SELECT 1;" > /dev/null 2>&1; do
    sleep 1
done

mysql -u root -h localhost --protocol=socket << EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

mysqladmin -u root -h localhost --protocol=socket shutdown
sleep 2
mysqld --bind-address=0.0.0.0
