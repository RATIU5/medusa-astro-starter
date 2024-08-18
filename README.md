# changemename

This is a Medusa and Astro starter project. It is set up with the following features:

- Medusa e-commerce platform (backend)
- Astro static/SSR site generator (storefront)
- PostgreSQL database
- Redis cache

## Requirements

Before you begin, ensure you have the following installed:

- **Node.js**: Version 20.16 or higher
- **pnpm**: Version 9.5 or higher
- **Docker**: Version 26.1 or higher
  - We recommend using [OrbStack](https://orbstack.dev/) as a faster, more efficient alternative to Docker Desktop, especially for macOS users.

To install these requirements:

1. Install Node.js from [nodejs.org](https://nodejs.org/)
2. Install pnpm:
   ```
   npm install -g pnpm@latest
   ```
3. Install Docker:
   - For OrbStack (recommended for macOS): Download from [orbstack.dev](https://orbstack.dev/)
   - For Docker Desktop: Download from [docker.com](https://www.docker.com/products/docker-desktop)

## Getting Started

Follow these steps to set up and run the project:

1. **Clone the repository**

   ```
   git clone https://github.com/RATIU5/medusa-astro-starter.git
   cd changemename
   ```

2. **Install dependencies**

   Install the project dependencies:

   ```
   pnpm install
   ```

3. **Set up the project**

   Run the setup script to configure the project:

   ```
   pnpm run:setup your-project-name
   ```

   This will rename instances of "changemename" to your project name and create necessary environment files.

4. **Start the database**

   ```
   pnpm db:start
   ```

5. **Run the database migrations**

   ```
   pnpm db:migrate
   ```

6. **Create the admin user**

   ```
   pnpm db:admin
   ```

7. **Start the development server**

   ```
   pnpm dev
   ```

## Available Scripts

- `pnpm run:check`: Check if the project is set up correctly
- `pnpm db:start`: Start the database containers
- `pnpm db:stop`: Stop the database containers
- `pnpm db:logs`: View database logs
- `pnpm db:clean`: Clean up containers, volumes, and images (development)
- `pnpm db:clean:preserve`: Clean up, preserving the database volume
- `pnpm db:clean:all`: Clean up everything (including all volumes)
- `pnpm format`: Format the codebase
- `pnpm check`: Run checks on the codebase
- `pnpm lint`: Lint the codebase
- `pnpm dev`: Start the development server
- `pnpm build`: Build the project
- `pnpm start`: Start the production server
