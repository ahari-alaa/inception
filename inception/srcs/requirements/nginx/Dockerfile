FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Create SSL folder
RUN mkdir -p /etc/nginx/ssl

# Copy config as a template
COPY conf/nginx.conf /etc/nginx/templates/nginx.conf.template

# Copy entrypoint script
COPY tools/nginx.sh /nginx.sh
RUN chmod +x /nginx.sh

EXPOSE 443

ENTRYPOINT ["/nginx.sh"]