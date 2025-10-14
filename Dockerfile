FROM php:8.4-cli
# ---------- System dependencies ----------
RUN apt-get update -y && apt-get upgrade -y && \
apt-get install -y \
nano \
ca-certificates \
curl \
gnupg \
libicu-dev \
default-mysql-client \
libzip-dev \
unzip \
libfreetype6-dev \
libonig-dev \
libjpeg62-turbo-dev \
libpng-dev \
supervisor \
# --- Imagick + HEIC support ---
libmagickwand-dev \
libheif-dev \
pkg-config && \
rm -rf /var/lib/apt/lists/*
# ---------- PHP Extensions ----------
# Configure GD first (before install)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
docker-php-ext-install \
gd \
zip \
exif \
sockets \
bcmath \
ctype \
pdo \
pdo_mysql \
intl \
pcntl \
mbstring
# ---------- Redis ----------
RUN pecl install -o -f redis && docker-php-ext-enable redis && rm -rf /tmp/pear
# ---------- Swoole ----------
RUN pecl install swoole && docker-php-ext-enable swoole
# ---------- Imagick (compiled with HEIC support) ----------
RUN pecl install imagick && docker-php-ext-enable imagick
# ---------- Composer ----------
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer
# ---------- Node.js 20 ----------
ENV NODE_PATH="/home/www-data/.npm-global/lib/node_modules"
ENV NODE_MAJOR=20
RUN mkdir -p /etc/apt/keyrings && \
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
| gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
| tee /etc/apt/sources.list.d/nodesource.list && \
apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*
# ---------- NPM global setup ----------
RUN mkdir -p /home/www-data/.npm-global && \
npm config set prefix "/home/www-data/.npm-global/"
# ---------- PHP Configuration ----------
RUN { \
echo 'opcache.enable_cli=1'; \
echo 'opcache.enable=1'; \
echo 'opcache.jit_buffer_size=256M'; \
echo 'opcache.jit=tracing'; \
echo 'file_uploads = On'; \
echo 'memory_limit = 2048M'; \
echo 'upload_max_filesize = 200M'; \
echo 'post_max_size = 200M'; \
echo 'max_execution_time = 600'; \
echo 'max_input_time = 0'; 
} > /usr/local/etc/php/conf.d/99-uploads.ini
# ---------- Default working directory ----------
WORKDIR /var/www/html
# ---------- Verify installation ----------
RUN php -v && \
php -m | grep -E "gd|pdo_mysql|redis|swoole|imagick" && \
node -v && \
composer -V