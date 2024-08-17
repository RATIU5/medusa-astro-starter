# changeme

## Requirements
- [OrbStack](https://orbstack.dev/) (recommended) or [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Make](https://www.gnu.org/software/make/)

## Getting Started

### Development Environment

1. Clone the repository:
    ```bash
    git clone https://github.com/RATIU5/medusa-astro-starter.git
    cd test-medusa
    ```

2. Set up environment files:
    ```bash
    make setup-env
    ```
   Update the created `.env` file with your development settings.

3. Rename the project (recommended):
    ```bash
    make rename-project
    ```
    When prompted, enter your desired project name. This command will replace all instances of `testproject` in the project with your specified name.

4. Build and start the development environment:
   ```bash
   make up
   ```

5. Create an initial admin user:
   ```bash
   make create-admin
   ```

6. Access the application:
   - Backend: [http://localhost:9000/app](http://localhost:9000/app)
   - Storefront: [http://localhost:4321](http://localhost:4321)

### Production Environment

1. Set up environment files (if not done already):
    ```bash
    make setup-env
    ```
   Update the `.env.production` file with your production settings.

2. Build and start the production environment:
   ```bash
   make up-prod
   ```

3. Create an initial admin user (if needed):
   ```bash
   make create-admin
   ```

4. Access the production application (URLs depend on your deployment configuration).

## Command Reference

### Development Commands
- `make rename-project`: Rename all instances of `testproject` in the project to your specified project name (excluding .env.example).
- `make setup-env`: Create `.env` and `.env.production` files from the template. Does not overwrite existing files.
- `make up`: Build and start all development services.
- `make down`: Stop all development services.
- `make logs`: View logs of all development services.
- `make status`: Show status of development services.
- `make restart`: Restart all development services.
- `make clean`: Remove development containers, images, volumes, and prune unused volumes.

### Production Commands
- `make up-prod`: Build and start all production services.
- `make down-prod`: Stop all production services.
- `make logs-prod`: View logs of all production services.
- `make status-prod`: Show status of production services.
- `make restart-prod`: Restart all production services.

### Common Commands
- `make create-admin`: Create initial admin user (works for both environments).
- `make list-resources`: List all project-related containers, volumes, and networks.
- `make list-volumes`: Display detailed information about all Docker volumes.
- `make clean-all`: Remove ALL Docker containers, images, and volumes (use with caution).

## Troubleshooting

If you encounter issues:

1. Ensure you've run `make setup-env` and updated the created .env files with the correct settings.
2. Check logs with `make logs` (development) or `make logs-prod` (production).
3. Try stopping all services, then rebuild and restart:
   ```bash
   make down && make up  # For development
   make down-prod && make up-prod  # For production
   ```
4. For persistent problems, perform a full cleanup:
   ```bash
   make clean && make up  # For development and production
   ```

**Note**: The `clean` and `clean-prod` commands remove project-related containers, images, and volumes. Use `clean-all` with extreme caution as it removes ALL Docker resources system-wide, **including those from other projects**.

For more detailed information, refer to the project documentation.