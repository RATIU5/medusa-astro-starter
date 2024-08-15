FROM node:alpine-20 as deps

WORKDIR /app/medusa

COPY package.json .

RUN npm install -g npm@latest

FROM node:alpine-20 as build

WORKDIR /app/medusa

# Copy cached node_modules from deps
COPY --from=deps /app/node_modules /app/node_modules

RUN npm install -g @medusajs/medusa-cli@preview

COPY . /app