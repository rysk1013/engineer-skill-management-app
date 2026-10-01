FROM php:8.5-fpm-bookworm AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libpq-dev \
    && docker-php-ext-install \
        pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app


FROM base AS development

COPY . .

RUN composer install \
    --no-interaction \
    --no-progress \
    --prefer-dist

CMD ["php-fpm"]


FROM base AS production

COPY . .

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --optimize-autoloader

CMD ["php-fpm"]
