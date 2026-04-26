FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y \
        php7.4 \
        php7.4-fpm \
        php7.4-mysql \
        php7.4-curl \
        php7.4-gd \
        php7.4-mbstring \
        wget \
        mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Create required directories
RUN mkdir -p /run/php /var/www

# Download WordPress
RUN wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /var/www && \
    rm /tmp/wordpress.tar.gz

# Fix ownership
RUN chown -R www-data:www-data /var/www/wordpress

# Copy script
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 9000
ENTRYPOINT ["/init.sh"]

