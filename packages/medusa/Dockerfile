FROM node:20-alpine

WORKDIR /app/medusa

COPY package.json .

RUN apk update

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python

RUN npm install -g npm@latest
RUN npm install -g @medusajs/medusa-cli@latest

RUN npm install --loglevel=error

COPY . .
RUN ls -a

RUN chmod 777 ./develop.sh
RUN chmod +x ./develop.sh

ENTRYPOINT ["./develop.sh", "develop"]