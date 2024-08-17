#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to set up environment files and dependencies
setup_env() {
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            echo ".env file created from .env.example. Please update it with your specific settings."
        else
            echo "Error: .env.example file not found. Cannot create .env file."
            exit 1
        fi
    else
        echo ".env file already exists. Skipping creation."
    fi

    if [[ ! -f .env.production ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env.production
            echo ".env.production file created from .env.example. Please update it with your production settings."
        else
            echo "Error: .env.example file not found. Cannot create .env.production file."
            exit 1
        fi
    else
        echo ".env.production file already exists. Skipping creation."
    fi

    # Check for Node.js
    if ! command_exists node; then
        echo "Error: Node.js is not installed. Please install Node.js before continuing."
        exit 1
    fi

    # Check for pnpm
    if ! command_exists pnpm; then
        echo "pnpm not found. Installing pnpm globally..."
        if ! npm install -g pnpm; then
            echo "Error: Failed to install pnpm. Please install it manually and run this script again."
            exit 1
        fi
    fi

    # Run pnpm install
    echo "Running pnpm install..."
    if ! pnpm install; then
        echo "Error: pnpm install failed. Please check your package.json and try again."
        exit 1
    fi

    echo "Environment setup complete."
}

# Function to rename the project
rename_project() {
    local old_name="changeme"
    local new_name="$1"
    local script_name=$(basename "$0")
    if [[ -z "$new_name" ]]; then
        echo "Error: New project name not provided."
        echo "Usage: $0 rename <new_project_name>"
        exit 1
    fi
    if [[ "$new_name" == *" "* ]]; then
        echo "Error: Project name cannot contain spaces."
        exit 1
    fi
    # Perform the renaming
    find . -type f \( -not -path '*/\.*' -o -name '.env' \) \
           -not -path '*/node_modules/*' \
           -not -path '*/dist/*' \
           -not -path '*/build/*' \
           -not -name '.env.example' \
           -not -name "$script_name" \
           -not -name '.gitignore' | while read -r file; do
        if [[ "$file" == "./.env" && ! -f "./.env" ]]; then
            continue
        fi
        if grep -q "$old_name" "$file"; then
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s/$old_name/$new_name/g" "$file"
            else
                sed -i "s/$old_name/$new_name/g" "$file"
            fi
            echo "Updated: $file"
        fi
    done
    echo "Project renamed from '$old_name' to '$new_name' in all relevant files."
    echo "Note: The directory name itself was not changed. You may want to rename it manually if desired."
}

# Function to clean up containers, volumes, and images (development)
clean() {
    local preserve_db=${1:-false}
    echo "Are you sure you want to remove project-related containers, images, and volumes? [y/N]"
    read -r ans
    if [[ "${ans:-N}" = y ]]; then
        # Stop and remove containers
        docker compose down --remove-orphans

        # Identify the postgres volume
        postgres_volume="${COMPOSE_PROJECT_NAME}_postgres_data"

        # Remove volumes
        if [ "$preserve_db" = true ]; then
            # Preserve the PostgreSQL volume and remove others
            echo "Preserving PostgreSQL volume ($postgres_volume) and removing other volumes."
            docker volume ls -q | grep -v "^$postgres_volume$" | xargs -r docker volume rm
        else
            # Remove all volumes including PostgreSQL
            echo "Removing all volumes."
            docker volume rm $(docker volume ls -q)
        fi

        # Remove all project-specific images
        echo "Removing all project-specific images."
        docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${COMPOSE_PROJECT_NAME}" | xargs -r docker rmi

        echo "Cleanup completed."
    fi
}

# Function to clean up everything (including all volumes)
clean_all() {
    echo "This will remove ALL containers, images, and volumes. Are you really sure? [y/N]"
    read -r ans
    if [[ "${ans:-N}" = y ]]; then
        docker compose down -v --rmi all
        docker container prune -f
        docker volume rm $(docker volume ls -q -f name="${COMPOSE_PROJECT_NAME}_") 2>/dev/null || true
        docker volume ls -q | xargs -r docker volume rm
        docker system prune -af --volumes
    fi
}

# Function to create initial admin user
create_admin() {
    if [[ -z "$(docker ps -q -f name=medusa)" ]]; then
        echo "Medusa container is not running. Please start it first."
        exit 1
    fi
    if [[ -z "$ADMIN_EMAIL" || -z "$ADMIN_PASSWORD" ]]; then
        echo "ADMIN_EMAIL and ADMIN_PASSWORD must be set in the .env file."
        exit 1
    fi
    echo "Creating admin user..."
    docker exec -i medusa /bin/sh -c "medusa user --email '${ADMIN_EMAIL}' --password '${ADMIN_PASSWORD}'"
    echo "Admin user creation attempt completed."
}

# Main execution
case "$1" in
    setup-env)
        setup_env
        ;;
    rename)
        rename_project "$2"
        ;;
    clean)
        clean false
        ;;
    clean-preserve-db)
        clean true
        ;;
    clean-all)
        clean_all
        ;;
    create-admin)
        create_admin
        ;;
    *)
        echo "Usage: $0 {setup-env|rename|clean|clean-preserve-db|clean-all|create-admin} [args]"
        echo "  setup-env                  : Set up environment files"
        echo "  rename <new_project_name>  : Rename the project"
        echo "  clean                      : Clean up development resources"
        echo "  clean-preserve-db          : Clean up resources but preserve the PostgreSQL volume"
        echo "  clean-all                  : Clean up all Docker resources (including PostgreSQL data)"
        echo "  create-admin               : Create initial admin user"
        exit 1
        ;;
esac