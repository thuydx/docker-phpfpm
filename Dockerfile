FROM ubuntu:22.04

MAINTAINER Thuy Dinh <thuydx@zendgroup.vn>
LABEL Author="Thuy Dinh" Description="A comprehensive docker image to run PHP-8.1.7 applications like Wordpress, Laravel, etc"

# Stop dpkg-reconfigure tzdata from prompting for input
ARG PHP_VERSION=8.1
ENV DATE_TIMEZONE=UTC \
  DEBIAN_FRONTEND=noninteractive \
  PHP_VERSION=8.1

# docker-php-ext-*
RUN sed -i 's|http://|http://vn.|g' /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php
RUN apt-get update && apt-get -y install && \
    apt-get -y install build-essential \
        libpng-dev \
        libfreetype6-dev \
        locales \
        zip \
        libzip-dev \
        jpegoptim optipng pngquant gifsicle \
        vim \
        unzip \
        git \
        curl \
        openssl \
        bash \
        make \
        strace \
        sudo
RUN apt-get -y install php${PHP_VERSION} \
    php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath php${PHP_VERSION}-intl php${PHP_VERSION}-maxminddb php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-redis php${PHP_VERSION}-yaml php${PHP_VERSION}-mcrypt php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-swoole php${PHP_VERSION}-xsl php${PHP_VERSION}-memcached php${PHP_VERSION}-uuid \
    php${PHP_VERSION}-iconv php${PHP_VERSION}-psr php${PHP_VERSION}-soap php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-apcu php${PHP_VERSION}-ast php${PHP_VERSION}-bz2 php${PHP_VERSION}-ds \
    php${PHP_VERSION}-gmp php${PHP_VERSION}-grpc php${PHP_VERSION}-imap php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-oauth php${PHP_VERSION}-pcov php${PHP_VERSION}-pspell \
# composer
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
# cleanup
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*
RUN apt-get clean && rm -rf /var/lib/apt/lists/*


# Add user for application
RUN groupadd -g 1000 dev
RUN useradd -u 1000 -ms /bin/bash -g dev -p $(openssl passwd -1 dev) dev
RUN echo 'root:Docker!' | chpasswd

# overwriding php.ini
COPY ./conf.d/app-fpm.ini /etc/php/8.1/fpm/conf.d/
# config fpm overwriding www.conf
COPY ./php-fpm.d/ /etc/php/8.1/fpm/pool.d/
#COPY ./conf.d/${ENV}/* /etc/php8.1/conf.d/

RUN mkdir -p /run/php-fpm /var/tmp/php-fpm
RUN chown dev:dev -R /run/php-fpm /var/tmp/php-fpm/
RUN chmod 777 -R /run/php-fpm /var/tmp/php-fpm/



COPY ext.php /ext.php
COPY docker-php-ext-disable.sh /usr/local/bin/docker-php-ext-disable
RUN php -e /ext.php


EXPOSE 9000
CMD ["php"]
CMD ["php8.1"]

