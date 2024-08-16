include .env

# Start services and wait for them to be healthy
up:
	docker compose up -d
	@echo "Waiting for all services to be healthy..."
	@until docker compose ps --services | xargs -I {} docker compose exec {} /bin/sh -c "exit 0" > /dev/null 2>&1; do \
		echo "Waiting for services to be ready..."; \
		sleep 5; \
	done
	@echo "All services are healthy!"

build:
	docker compose build

# Combined deploy command with optional environment and additional options
deploy:
	./deploy.sh $(ENV) $(OPTIONS)

initial_user:
	docker exec -it medusa medusa user --email ${ADMIN_EMAIL} --password ${ADMIN_PASSWORD}

logs:
	docker compose logs -f

ps:
	docker compose ps

restart:
	docker compose restart

# Enhanced clean command that also brings services down
clean:
	docker compose down -v --remove-orphans

.PHONY: up build deploy initial_user logs ps restart clean