FROM node:20-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json* ./

RUN npm install -g npm@latest

RUN if [ -f package-lock.json ]; then \
    npm ci || npm install; \
  else \
    npm install; \
  fi

FROM node:20-alpine AS build

WORKDIR /app

# Copy cached node_modules from deps
COPY --from=deps /app/node_modules /app/node_modules

RUN npm install -g @medusajs/medusa-cli@preview

COPY . /app

ENTRYPOINT ["/bin/sh", "./develop.sh", "develop"]