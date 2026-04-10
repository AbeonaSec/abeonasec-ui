# stage 1: build quasar project
# use node base image and set working directory
FROM node:24-alpine AS builder
RUN apk add --no-cache curl

RUN npm install -g @quasar/cli

WORKDIR /app
# copy Quasar project into container and build
COPY . .
RUN npm install

# find localhost url for api specified in quasar config and change to container dns name
RUN find quasar.config.js -type f -exec sed -i 's/localhost/abeonasec-api/g' {} +
RUN quasar build


# stage 2: start nginx and serve built project
# copy the built Quasar project to the default site location
FROM docker.io/library/nginx:alpine

# copy default configuration file
COPY ./container/nginx-default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/spa /usr/share/nginx/html

# expose port 80 and start nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
