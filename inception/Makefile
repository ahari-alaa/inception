all:
	sudo mkdir -p /home/ahari/data/mariadb
	sudo mkdir -p /home/ahari/data/wordpress
	docker-compose  -f srcs/docker-compose.yml up --build

down:
	docker-compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down -v
	sudo rm -rf /home/ahari/data
