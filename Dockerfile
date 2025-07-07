FROM php:8.0.28-fpm

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    libbz2-dev \
    libc-client-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libgmp-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libldap2-dev \
    libonig-dev \
    libpng-dev \
    libpq-dev \
    libpspell-dev \
    libreadline-dev \
    libsodium-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    unixodbc-dev \
    zlib1g-dev \
    libaio1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Скачивание и установка Oracle Instant Client 21.12 через ZIP-архивы
RUN mkdir -p /opt/oracle \
    && cd /opt/oracle \
    && wget -q https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-basic-linux.x64-21.12.0.0.0dbru.zip \
    && wget -q https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip \
    && unzip instantclient-basic-linux.x64-21.12.0.0.0dbru.zip \
    && unzip instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip \
    && rm instantclient-basic-linux.x64-21.12.0.0.0dbru.zip instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip \
    && mv instantclient_21_12 /opt/oracle/instantclient \
    && echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Установка переменных окружения для Oracle
ENV ORACLE_HOME=/opt/oracle/instantclient
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH

# Конфигурация и установка расширений PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
    bz2 \
    calendar \
    exif \
    ftp \
    gd \
    gettext \
    gmp \
    iconv \
    intl \
    ldap \
    mbstring \
    odbc \
    pcntl \
    pdo \
    pdo_mysql \
    pdo_odbc \
    pdo_pgsql \
    pdo_sqlite \
    pspell \
    shmop \
    soap \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    xml \
    xmlreader \
    xmlwriter \
    xsl \
    zip \
    && docker-php-ext-enable opcache sodium

# Установка PECL расширения oci8
RUN echo "instantclient,/opt/oracle/instantclient" | pecl install oci8-3.2.1 \
    && docker-php-ext-enable oci8

# Настройка PHP
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Чистка кэша
RUN pecl clear-cache && rm -rf /tmp/pear
