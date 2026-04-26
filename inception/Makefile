all:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	@grep -q "ahari.42.fr" /etc/hosts || echo "127.0.0.1 ahari.42.fr" | sudo tee -a /etc/hosts
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

clean: down
	sudo rm -rf /home/${USER}/data/mariadb
	sudo rm -rf /home/${USER}/data/wordpress

fclean: clean down
	docker system prune -af

re: fclean all
