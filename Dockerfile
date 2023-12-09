FROM  php:8.2-cli

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y nano ca-certificates curl gnupg libicu-dev default-mysql-client libzip-dev unzip libfreetype6-dev libonig-dev libjpeg62-turbo-dev libpng-dev supervisor \
    && docker-php-ext-install zip exif sockets bcmath ctype pdo pdo_mysql intl pcntl gd mbstring \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-enable redis

# Get latest Composer
COPY --from=composer:2.5.8 /usr/bin/composer /usr/bin/composer

RUN pecl install swoole
RUN docker-php-ext-enable swoole

ENV NODE_PATH "/home/www-data/.npm-global/lib/node_modules"
ENV NODE_MAJOR=20
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install nodejs -y

RUN mkdir "/home/www-data/" && \
    mkdir "/home/www-data/.npm-global/" && \
    npm config set prefix "/home/www-data/.npm-global/"

#  PHP jit and.
RUN echo 'opcache.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo 'opcache.jit_buffer_size=256M' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo 'opcache.jit=tracing' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo 'file_uploads = On' >> /usr/local/etc/php/conf.d/upload.ini \
    && echo 'memory_limit = 1024M' >> /usr/local/etc/php/conf.d/upload.ini \
    && echo 'upload_max_filesize = 100M' >> /usr/local/etc/php/conf.d/upload.ini \
    && echo 'post_max_size = 150M' >> /usr/local/etc/php/conf.d/upload.ini
