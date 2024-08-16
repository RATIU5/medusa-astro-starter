# This file is only suitable to be used during development, not production.
# It only sets up and installs the packages. 
# The source will be mounted as a volume by Docker compose.

FROM node:20-alpine

WORKDIR /app

COPY package*.json .

RUN npm i --audit=false --fund=false

EXPOSE 4321

CMD ["npm", "run", "dev"]