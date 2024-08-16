# test-medusa

## Developer Installation

### Requirements
- [OrbStack](https://orbstack.dev/) (recommended) or [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Make](https://www.gnu.org/software/make/)

### Installation
1. Clone this repository with the following command:
    ```bash
    git clone https://github.com/RATIU5/test-medusa.git
    ```
2. Navigate to the project directory:
    ```bash
    cd test-medusa
    ```
3. Start the OrbStack development environment (skip this step if using Docker Desktop):
    ```bash
    orb start
    ```
4. Create a `.env` file in the project root and add necessary environment variables.
5. Build and start the development environment:
   ```
   make build
   make deploy
   ```
6. Create an initial admin user:
   ```
   make initial_user
   ```
7. Access the application:
   - Backend: http://localhost:9000
   - Storefront: http://localhost:4321

## Production Setup
1. Ensure you have a `docker-compose.prod.yml` file configured for production.
2. Set up production environment variables in `.env`.
3. Build and start the production environment:
   ```
   make build
   make deploy ENV=prod
   ```
4. Access the production application (URLs will depend on your deployment configuration).

## Common Commands
- Build and start services (waits for healthy state): `make up`
- Build Docker images: `make build`
- Deploy the application:
  - Development: `make deploy`
  - Production: `make deploy ENV=prod`
  - With options: `make deploy ENV=dev OPTIONS="additional options"`
- View service status: `make ps`
- View logs: `make logs`
- Restart services: `make restart`
- Stop and remove all services (including volumes): `make clean`

## Troubleshooting
If you encounter issues:
1. Ensure all required environment variables are set.
2. Check logs with `make logs`.
3. Try rebuilding with `make build` followed by `make deploy` or `make deploy ENV=prod`.

For more detailed information, refer to the project documentation.