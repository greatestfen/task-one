FROM php:8.0.28-fpm

# Обновление GPG ключей и настройка репозиториев
RUN apt-get update && apt-get install -y gnupg2 \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 DCC9EFBF77E11517 \
    || { echo "Failed to fetch GPG keys, proceeding without verification"; apt-get update --allow-insecure-repositories; } \
    && echo "deb http://deb.debian.org/debian bullseye main" > /etc/apt/sources.list \
    && echo "deb http://deb.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list \
    && echo "deb http://deb.debian.org/debian bullseye-updates main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y \
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
    libaio1 \
    wget \
    alien \
    rpm \
    && rm -rf /var/lib/apt/lists/*

# Скачивание и установка Oracle Instant Client 21.12 через RPM
# Если wget не работает, замените на COPY после ручной загрузки RPM
RUN mkdir -p /opt/oracle && cd /opt/oracle \
    && wget -q --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2112000/oracle-instantclient-basic-21.12.0.0.0-1.x86_64.rpm \
    && wget -q --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2112000/oracle-instantclient-devel-21.12.0.0.0-1.x86_64.rpm \
    && wget -q --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2112000/oracle-instantclient-odbc-21.12.0.0.0-1.x86_64.rpm \
    && ls -l *.rpm || { echo "Failed to download RPM files"; exit 1; } \
    && alien -i oracle-instantclient-basic-21.12.0.0.0-1.x86_64.rpm \
    && alien -i oracle-instantclient-devel-21.12.0.0.0-1.x86_64.rpm \
    && alien -i oracle-instantclient-odbc-21.12.0.0.0-1.x86_64.rpm \
    && rm oracle-instantclient-*.rpm \
    && ln -s /usr/lib/oracle/21/client64 /opt/oracle/instantclient \
    && echo /usr/lib/oracle/21/client64/lib > /etc

# Установка переменных окружения для Oracle
ENV ORACLE_HOME=/usr/lib/oracle/21/client64
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib:$LD_LIBRARY_PATH

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
    pcntl \
    pdo \
    pdo_mysql \
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
RUN echo "instantclient,/usr/lib/oracle/21/client64/lib" | pecl install oci8-3.2.1 \
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
