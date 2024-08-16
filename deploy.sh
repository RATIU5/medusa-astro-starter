#!/bin/bash

# Check if we're running in production mode
if [ "$1" == "prod" ]; then
    ENV="prod"
    COMPOSE_FILE="docker-compose.prod.yml"
else
    ENV="dev"
    COMPOSE_FILE="docker-compose.yml"
fi

# Define service groups
BACKEND_SERVICE="backend"
STOREFRONT_SERVICE="storefront"
OTHER_SERVICES="postgres"
BACKEND_PORT=9000
STOREFRONT_PORT=4321
TIMEOUT=60
SLEEP_INTERVAL=5
MAX_RETRIES=$((TIMEOUT / SLEEP_INTERVAL))

# Include ADMIN_SERVICE only in production
if [ "$ENV" == "prod" ]; then
    ADMIN_SERVICE="admin"
else
    ADMIN_SERVICE=""
fi

# Build docker images
echo "Build docker images"
docker compose -f $COMPOSE_FILE build --no-cache $BACKEND_SERVICE $ADMIN_SERVICE

# Remove current backend group
docker compose -f $COMPOSE_FILE down $BACKEND_SERVICE $ADMIN_SERVICE

# Start all services in the backend group
echo "Run backend groups"
docker compose -f $COMPOSE_FILE up -d $2 $BACKEND_SERVICE $ADMIN_SERVICE $OTHER_SERVICES

# Wait for the backend to become healthy
echo "Waiting for [$BACKEND_SERVICE] to become healthy..."
sleep 15
i=0
REGION_COUNT=0
while [ "$i" -le $MAX_RETRIES ]; do
  HEALTH_CHECK_URL="http://localhost:$BACKEND_PORT/store/regions"
  response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)
  if [ $response -eq 200 ]; then
      echo "[$BACKEND_SERVICE] is healthy"
      response=$(curl -X GET $HEALTH_CHECK_URL -H "Content-Type: application/json")
      REGION_COUNT=$(echo $response | grep -oP '"count":\s*\K[0-9]+')
      break
  else
      echo "Health check failed. API returned HTTP status code: $response"
  fi
  i=$(( i + 1 ))
  sleep "$SLEEP_INTERVAL"
done

# Initialize sample data for Backend if needed
if [ "$REGION_COUNT" -gt 0 ]; then
  echo "The application already has data"
else
  echo "Initialize seed data"
  docker compose -f $COMPOSE_FILE exec $BACKEND_SERVICE npx medusa seed
fi

# Build and start storefront
echo "Build storefront docker image"
docker compose -f $COMPOSE_FILE build --no-cache $STOREFRONT_SERVICE

# Remove current storefront group
docker compose -f $COMPOSE_FILE down $STOREFRONT_SERVICE

# Start storefront service
docker compose -f $COMPOSE_FILE up -d $2 $STOREFRONT_SERVICE

# Wait for the storefront to become healthy
echo "Waiting for [$STOREFRONT_SERVICE] to become healthy..."
sleep 30
i=0
while [ "$i" -le $MAX_RETRIES ]; do
  HEALTH_CHECK_URL="http://localhost:$STOREFRONT_PORT/"
  response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)
  if [ $response -eq 200 ]; then
      echo "[$STOREFRONT_SERVICE] is healthy"
      break
  else
      echo "Health check failed. API returned HTTP status code: $response"
  fi
  i=$(( i + 1 ))
  sleep "$SLEEP_INTERVAL"
done

# Remove unused images
(docker images -q --filter 'dangling=true' -q | xargs docker rmi) || true

echo "Deployment completed for $ENV environment"