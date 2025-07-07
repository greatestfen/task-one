FROM php:8.0.28-fpm

# Установка системных зависимостей и alien
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
    odbcinst \
    zlib1g-dev \
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
    && echo /usr/lib/oracle/21/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Установка переменных окружения для Oracle
ENV ORACLE_HOME=/usr/lib/oracle/21/client64
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib:$LD_LIBRARY_PATH

# Создание символических ссылок для ODBC заголовков и библиотек
RUN mkdir -p /usr/local/incl && ln -s /usr/include/odbcinst.h /usr/local/incl/odbcinst.h \
    && ln -s /usr/include/sqlext.h /usr/local/incl/sqlext.h \
    && ln -s /usr/include/sql.h /usr/local/incl/sql.h \
    && ln -s /usr/include/sqltypes.h /usr/local/incl/sqltypes.h \
    && mkdir -p /usr/local/lib && ln -s /usr/lib/x86_64-linux-gnu/libodbc.so /usr/local/lib/libodbc.so

# Конфигурация и установка расширений PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure od
