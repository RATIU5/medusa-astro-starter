include .env

# Setup environment files
setup-env:
	cp .env.example .env
	cp .env.example .env.production
	@echo "Environment files created. Please update .env and .env.production with your specific settings."

# Build and start all services (development)
up:
	docker compose up --build -d
	@echo "All services are starting. Use 'make logs' to view logs."

# Build and start all services (production)
up-prod:
	docker compose -f docker-compose.prod.yml up --build -d
	@echo "Production services are starting. Use 'make logs-prod' to view logs."

# Stop all services (development)
down:
	docker compose down

# Stop all services (production)
down-prod:
	docker compose -f docker-compose.prod.yml down

# View logs of all services (development)
logs:
	docker compose logs -f

# View logs of all services (production)
logs-prod:
	docker compose -f docker-compose.prod.yml logs -f

# Restart all services (development)
restart:
	docker compose restart

# Restart all services (production)
restart-prod:
	docker compose -f docker-compose.prod.yml restart

# Clean up containers, volumes, and images (development)
clean:
	@echo "Are you sure you want to remove all project-related containers, images, and volumes? [y/N] " && read ans && [ $${ans:-N} = y ]
	docker compose down -v --rmi all
	docker volume ls -q -f name=$(COMPOSE_PROJECT_NAME)_ | xargs -r docker volume rm
	docker volume prune -f

clean-all:
	@echo "This will remove ALL containers, images, and volumes. Are you really sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	docker compose down -v --rmi all
	docker container prune -f
	docker volume rm $$(docker volume ls -q -f name=$(COMPOSE_PROJECT_NAME)_) 2>/dev/null || true
	docker volume ls -q | xargs -r docker volume rm
	docker system prune -af --volumes

# Clean up containers, volumes, and images (production)
clean-prod:
	@echo "Are you sure you want to remove all project-related containers, images, and volumes? [y/N] " && read ans && [ $${ans:-N} = y ]
	docker compose -f docker-compose.prod.yml down -v --rmi all
	docker volume ls -q -f name=$(COMPOSE_PROJECT_NAME)_ | xargs -r docker volume rm
	docker volume prune -f

# Create initial admin user (works for both dev and prod)
create-admin:
	@if [ -z "$$(docker ps -q -f name=medusa)" ]; then \
		echo "Medusa container is not running. Please start it first."; \
		exit 1; \
	fi
	docker exec -it $$(docker ps -qf "name=medusa") medusa user --email ${ADMIN_EMAIL} --password ${ADMIN_PASSWORD}

# Show status of services (development)
status:
	docker compose ps

# Show status of services (production)
status-prod:
	docker compose -f docker-compose.prod.yml ps

# List all project-related container resources
list-resources:
	@echo "Containers:"
	@docker ps -a --filter name=$(COMPOSE_PROJECT_NAME)
	@echo "\nVolumes:"
	@docker volume ls -f name=$(COMPOSE_PROJECT_NAME)
	@echo "\nNetworks:"
	@docker network ls -f name=$(COMPOSE_PROJECT_NAME)

list-volumes:
	@echo "All Volumes:"
	@docker volume ls
	@echo "\nDetailed Volume Information:"
	@for vol in $$(docker volume ls -q); do \
		echo "\nVolume: $$vol"; \
		docker volume inspect $$vol; \
	done

rename-project:
	@if grep -q "changeme" $$(find . -type f -not -path '*/\.*' -not -name '.env.example'); then \
		echo "Enter the new project name: " && read project_name; \
		find . -type f -not -path '*/\.*' -not -name '.env.example' -exec sed -i'' -e "s/changeme/$$project_name/g" {} +; \
		echo "Project renamed from 'changeme' to '$$project_name'. Note: .env.example was not modified."; \
	else \
		echo "No instances of 'changeme' found (excluding .env.example). The project may have already been renamed."; \
	fi

.PHONY: setup-env up up-prod down down-prod logs logs-prod restart restart-prod clean clean-all clean-prod create-admin status status-prod list-resources list-volumes rename-project