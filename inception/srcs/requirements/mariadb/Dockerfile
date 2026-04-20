FROM debian:bullseye

RUN apt-get update && apt-get install -y  mariadb-server

COPY conf/init.sh /init.sh
COPY conf/50-server.cnf /etc/mysql/conf.d/50-server.cnf
RUN chmod +x /init.sh

EXPOSE 3306


CMD ["bash", "/init.sh"]
