# Nginx and Php-fpm with Laravel on Docker

Running nginx and php-fpm processes in the same Debian container with Laravel (mysql, mariadb, sqlite). How to run multiple services in one docker container.

## Laravel project directory

```sh
# Remove webapp dir and create new Laravel app
composer create-project laravel/laravel webapp

# Or copy your Laravel project files to
webapp
```

## Config Mysql in files

```sh
.env
webapp/.env
```

## Build

```sh
# Build up
docker compose up --build -d
docker compose build --no-cache && docker compose up --force-recreate -d

# Show
docker compose ps

# Interactive container terminal
docker exec -it app_host bash
docker exec -it mysql_host bash
```

## Run Php-fpm and nginx in same docker container

How to run multiple services in one docker container.

```sh
# Allow services autostart
RUN echo "exit 0" > /usr/sbin/policy-rc.d

# Run php-fpm (required don't remove)
CMD /etc/init.d/php8.2-fpm start && nginx -g "daemon off;"
```
