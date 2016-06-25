FROM php:5.6-apache

RUN a2enmod rewrite

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bzip2 \
      sudo \
      git \
      libpng12-dev \
      libjpeg-dev \
      libmemcached-dev \
      libmcrypt-dev \
      mysql-client \
      patch \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
 && docker-php-ext-install \
      gd \
      zip \
      mysql \
      pdo_mysql \
      mcrypt \
      mbstring \
      json \
      gettext \
 && pecl install memcache \
 && docker-php-ext-enable memcache \
 && echo "date.timezone = 'UTC'" > /usr/local/etc/php/php.ini \
 && echo "short_open_tag = 0" >> /usr/local/etc/php/php.ini \
 && curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin

ENV INSTALL_PATH=/usr/share/vimbadmin \
    VIMBADMIN_VERSION=3.0.15 \
    DOCKERIZE_VERSION=0.2.0

RUN cd /tmp \
 && curl -o dockerize.tar.gz -fSL https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
 && tar -C /usr/local/sbin -xf dockerize.tar.gz \
 && rm dockerize.tar.gz \
 && rm -rf $INSTALL_PATH \
 && curl -o VIMBADMIN.tar.gz -fSL https://github.com/opensolutions/ViMbAdmin/archive/${VIMBADMIN_VERSION}.tar.gz \
 && tar zxf VIMBADMIN.tar.gz \
 && rm VIMBADMIN.tar.gz \
 && mv ViMbAdmin-${VIMBADMIN_VERSION} $INSTALL_PATH \
 && cd $INSTALL_PATH \
 && cp public/.htaccess.dist public/.htaccess \
 && chown -R www-data.www-data . \
 && su -c "composer install" -s /bin/bash www-data

WORKDIR /usr/share/vimbadmin
COPY apache.conf /etc/apache2/conf-enabled/vimbadmin.conf
COPY docker-entrypoint.sh /entrypoint.sh
COPY application.ini /usr/share/vimbadmin/application/configs/application.ini

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dockerize", "-stderr", "/usr/share/vimbadmin/var/log/vimbadmin.log", "apache2-foreground"]
