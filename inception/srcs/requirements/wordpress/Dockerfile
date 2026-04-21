FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y \
        php \
        php-fpm \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Create required directories
RUN mkdir -p /run/php /var/www

# Download WordPress correctly
RUN wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /var/www && \
    rm /tmp/wordpress.tar.gz

# Copy script
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 9000

ENTRYPOINT ["/init.sh"]
