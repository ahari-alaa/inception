FROM debian:bullseye

RUN apt-get update && apt-get install -y php-fpm php-mysql \ 
	   wget php-curl php-gd php-mbstring \
	&& wget https://wordpress.org/latest.tar.gz \
	&& tar -xzf latest.tar.gz \
	&& mkdir -p /var/www/html \
	&& mv wordpress /var/www/html/


COPY conf/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 9000

CMD ["bash", "/setup.sh"]
