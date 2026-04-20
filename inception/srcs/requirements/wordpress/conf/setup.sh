#!/bin/bash


PATH_WP=/var/www/html/wordpress/wp-config.php

cp /var/www/html/wordpress/wp-config-sample.php $PATH_WP

sed -i "s/database_name_here/$MYSQL_DATABASE/" $PATH_WP

sed -i "s/username_here/$MYSQL_USER/" $PATH_WP

sed -i "s/password_here/$MYSQL_PASSWORD/" $PATH_WP

sed -i "s/localhost/$MYSQL_HOST/" $PATH_WP
sed -i "s|listen = /run/php/php7.4-fpm.sock|listen = 9000|" /etc/php/7.4/fpm/pool.d/www.conf

mkdir -p /run/php

php-fpm7.4 -F
