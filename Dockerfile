FROM php:8.0.28-fpm

# Установка системных зависимостей и исправление GPG ключей
RUN apt-get clean && rm -rf /var/lib/apt/lists/* \
    && echo "deb http://localhost.localhost/repository/debian-bullseye-proxy bullseye main" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y debian-archive-keyring gnupg gnupg2 \
    && apt-get clean \
    && apt-key add /usr/share/keyrings/debian-archive-bullseye-stable.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    unixodbc-dev \
    libtool \
    autoconf \
    make \
    gcc \
    g++ \
    git \
    pkg-config \
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

RUN mkdir -p /usr/src/php/ext/odbc && \
    curl --insecure -sSL https://github.com/php/php-src/raw/PHP-8.2.0/ext/odbc/config.m4 -o /usr/src/php/ext/odbc/config.m4 && \
    curl --insecure -sSL https://github.com/php/php-src/raw/PHP-8.2.0/ext/odbc/odbc.c -o /usr/src/php/ext/odbc/odbc.c && \
    curl --insecure -sSL https://github.com/php/php-src/raw/PHP-8.2.0/ext/odbc/php_odbc.h -o /usr/src/php/ext/odbc/php_odbc.h

#RUN cd /usr/src/php/ext/odbc && \
#    sed -i '/AC_MSG_CHECKING(\[for Adabas support\])/,+10d' config.m4 && \
#    phpize && \
#    autoreconf -fi && \
#    ./configure --with-unixODBC=/usr && \
#    make -j$(nproc) && \
#    make install && \
#    echo "extension=odbc.so" > /usr/local/etc/php/conf.d/20-odbc.ini

# Скачивание и установка Oracle Instant Client 21.12 через RPM
# Если wget не работает, замените на COPY после ручной загрузки RPM
RUN mkdir -p /opt/oracle && cd /opt/oracle \
    && wget -q --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2112000/oracle-instantclient-basic-21.12.0.0.0-1.x86_64.rpm \
    && wget -q --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2112000/oracle-instantclient-devel-21.12.0.0.0-1.x86_64.rpm \
    && ls -l *.rpm || { echo "Failed to download RPM files"; exit 1; } \
    && alien -i oracle-instantclient-basic-21.12.0.0.0-1.x86_64.rpm \
    && alien -i oracle-instantclient-devel-21.12.0.0.0-1.x86_64.rpm \
    && rm oracle-instantclient-*.rpm \
    && ln -s /usr/lib/oracle/21/client64 /opt/oracle/instantclient \
    && echo /usr/lib/oracle/21/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Установка переменных окружения для Oracle
ENV ORACLE_HOME=/usr/lib/oracle/21/client64
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib:$LD_LIBRARY_PATH
ENV PHP_OCI8_DIR=/usr/lib/oracle/21/client64/lib
ENV CFLAGS="-I/usr/include"
ENV LDFLAGS="-L/usr/lib"

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
    pdo_odbc \
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
    xsl \
    zip \
    && docker-php-ext-enable opcache

# pdo_odbc
RUN docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
    && docker-php-ext-install pdo_odbc

# pdo_oci
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,${PHP_OCI8_DIR},21.1 \
    && docker-php-ext-install pdo_oci

# oci8
RUN docker-php-ext-configure oci8 --with-oci8=instantclient,${PHP_OCI8_DIR} \
    && docker-php-ext-install oci8

# Настройка PHP
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini
