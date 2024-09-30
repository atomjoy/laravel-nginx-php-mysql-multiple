# docker compose up --build -d
# docker build -t demo/app:latest -f atomjot/app/Dockerfile demo/app
# docker build --no-cache -t demo/app:0.1 .
# docker run -p 8000:80 demo/app:0.1

FROM debian:bookworm AS php

LABEL maintainer="Atomjoy"

# Mysql init
COPY ./mysql/init.sql /docker-entrypoint-initdb.d/init.sql

# Env php.ini
ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMP=1
ENV PHP_OPCACHE_REVALIDATE_FREQ=1

# Install
RUN apt-get update -y
RUN apt-get install apt-transport-https -y

RUN apt-get install -y gnupg tzdata \
    && echo "UTC" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update \
    && apt-get install -y curl zip unzip git supervisor sqlite3 openssl ssl-cert \
       nginx php8.2-fpm php8.2-cli php-opcache \
       php8.2-mysql php8.2-sqlite3 php8.2-pgsql \
       php8.2-curl php8.2-redis php8.2-memcached \
       php8.2-gd php8.2-imap php8.2-mbstring php8.2-tokenizer \
       php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap \
       php8.2-intl php8.2-readline php8.2-xdebug \
       php-msgpack php-igbinary \    
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*    

WORKDIR /var/www/html

COPY --chown=www-data:www-data --chmod=2775 ./webapp /var/www/html

RUN rm -rf /etc/nginx/sites-enabled/default

RUN make-ssl-cert generate-default-snakeoil --force-overwrite

COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

COPY ./php/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf

COPY ./php/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY ./php/php.ini /etc/php/8.2/fpm/conf/99-docker-php.ini

RUN nginx -t

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

USER www-data

RUN composer update
RUN composer dump-autoload -o

RUN php artisan cache:clear
RUN php artisan config:clear
RUN php artisan migrate
RUN php artisan storage:link

USER root

# Allow services autostart
# RUN echo "exit 0" > /usr/sbin/policy-rc.d

# Run php-fpm (required don't remove)
CMD /etc/init.d/php8.2-fpm start && nginx -g "daemon off;"