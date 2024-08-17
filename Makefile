# Conditionally include .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Default values for environment variables
COMPOSE_PROJECT_NAME ?= changeme

# Define the script name
SCRIPT_NAME := make-scripts.sh

# Check if the script exists and is executable
SCRIPT_CHECK := $(shell if [ -f "./$(SCRIPT_NAME)" ] && [ -x "./$(SCRIPT_NAME)" ]; then echo "OK"; elif [ -f "./$(SCRIPT_NAME)" ]; then echo "NOT_EXECUTABLE"; else echo "NOT_FOUND"; fi)

# Function to check script status before running
define check_script
	@if [ "$(SCRIPT_CHECK)" = "OK" ]; then \
		./$(SCRIPT_NAME) $(1); \
	elif [ "$(SCRIPT_CHECK)" = "NOT_EXECUTABLE" ]; then \
		echo "Error: $(SCRIPT_NAME) is not executable. Run 'chmod +x $(SCRIPT_NAME)' to fix this."; \
		exit 1; \
	else \
		echo "Error: $(SCRIPT_NAME) not found. Please ensure the file exists in the project directory."; \
		exit 1; \
	fi
endef

# Setup environment files
setup-env:
	$(call check_script,setup-env)

# Build and start all services (development)
up:
	@if [ -f .env ]; then \
		echo "Loading environment variables from .env file"; \
		set -a; \
		. ./.env; \
		set +a; \
		docker compose up --build -d; \
	else \
		echo ".env file not found. Please run 'make setup-env' first."; \
		exit 1; \
	fi

# Build and start all services (production)
up-prod:
	@if [ -f .env.production ]; then \
		echo "Loading environment variables from .env.production file"; \
		set -a; \
		. ./.env.production; \
		set +a; \
		docker compose -f docker-compose.prod.yml up --build -d; \
	else \
		echo ".env.production file not found. Please run 'make setup-env' first."; \
		exit 1; \
	fi

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

# Clean up containers, volumes, and images (works for both dev and prod)
clean:
	@if [ "$(SCRIPT_CHECK)" = "OK" ]; then \
		./$(SCRIPT_NAME) clean; \
	else \
		echo "Error: $(SCRIPT_NAME) not found or not executable. Please check the file and its permissions."; \
		exit 1; \
	fi

# Clean up everything
clean-all:
	@if [ "$(SCRIPT_CHECK)" = "OK" ]; then \
		./$(SCRIPT_NAME) clean-all; \
	else \
		echo "Error: $(SCRIPT_NAME) not found or not executable. Please check the file and its permissions."; \
		exit 1; \
	fi

# Create initial admin user (works for both dev and prod)
create-admin:
	@if [ "$(SCRIPT_CHECK)" = "OK" ]; then \
		./$(SCRIPT_NAME) create-admin; \
	else \
		echo "Error: $(SCRIPT_NAME) not found or not executable. Please check the file and its permissions."; \
		exit 1; \
	fi

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
	@if [ "$(SCRIPT_CHECK)" = "OK" ]; then \
		read -p "Enter the new project name (no spaces allowed): " project_name; \
		if echo "$$project_name" | grep -q " "; then \
			echo "Error: Project name cannot contain spaces. Please try again."; \
			exit 1; \
		else \
			./$(SCRIPT_NAME) rename "$$project_name"; \
		fi \
	elif [ "$(SCRIPT_CHECK)" = "NOT_EXECUTABLE" ]; then \
		echo "Error: $(SCRIPT_NAME) is not executable. Run 'chmod +x $(SCRIPT_NAME)' to fix this."; \
		exit 1; \
	else \
		echo "Error: $(SCRIPT_NAME) not found. Please ensure the file exists in the project directory."; \
		exit 1; \
	fi

.PHONY: setup-env up up-prod down down-prod logs logs-prod restart restart-prod clean clean-all create-admin status status-prod list-resources list-volumes rename-project