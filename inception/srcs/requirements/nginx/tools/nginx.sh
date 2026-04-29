#!/bin/bash

# Generate SSL certificate with the real domain name
openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=MA/ST=BG/L=Khouribga/O=42/OU=1337/CN=${DOMAIN_NAME}"

# Replace ${DOMAIN_NAME} in the config template with the actual value
envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/nginx.conf.template \
    > /etc/nginx/conf.d/default.conf

# Test nginx config is valid
nginx -t

# Start nginx in foreground
exec nginx -g "daemon off;"