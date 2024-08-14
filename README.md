# test-medusa

## Developer Installation

### Requirements

- OrbStack (recommended) or Docker Desktop

### Installation

Clone this repository with the following command:

```bash
git clone https://github.com/RATIU5/test-medusa.git
```

Navigate to the project directory:

```bash
cd test-medusa
```

Start the OrbStack development environment (skip this step if using Docker Desktop):

```bash
orb start
```

Activate the containers:
  
```bash
docker compose up
```

Install the project dependencies:

```bash
pnpm install
```

Sync VCS hooks (recommended):

```bash
pnpm sync:hooks
```
