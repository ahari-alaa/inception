all:
	mkdir -p /home/ahari/data/mariadb
	mkdir -p /home/ahari/data/wordpress
	@grep -q "ahari.42.fr" /etc/hosts || echo "127.0.0.1 ahari.42.fr" | sudo tee -a /etc/hosts
	docker compose  -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	sudo rm -rf /home/ahari/data/mariadb
	sudo rm -rf /home/ahari/data/wordpress

fclean: clean
	docker system prune -af

re: fclean all
