FROM php:7.4-fpm-alpine

LABEL MAINTAINER="eliurkis@gmail.com" \
      DESCRIPTION="PHP-FPM 7.4 & Nginx 1.16 based on Alpine Linux."

ENV stdout /dev/stdout
ENV stderr /dev/stderr

# Install packages
RUN apk add --update \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/community

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk --no-cache add \
  gnu-libiconv \
  php7-cli \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-fpm \
  php7-fileinfo \
  php7-gd \
  php7-gettext \
  php7-iconv \
  php7-intl \
  php7-json \
  php7-mbstring \
  php7-mysqli \
  php7-odbc \
  php7-openssl \
  php7-pdo \
  php7-pdo_dblib \
  php7-pdo_pgsql \
  php7-phar \
  php7-session \
  php7-simplexml \
  php7-sockets \
  php7-tokenizer \
  php7-xmlreader \
  php7-xml \
  php7-zlib \
  php7-xmlwriter \
  php7-zip \
  php7-bcmath \
  nginx \
  supervisor \
  curl \
  git \
  nodejs \
  npm

# Update nginx configuration
COPY configs/nginx/conf.d/vhosts.conf /etc/nginx/conf.d
COPY configs/nginx/* /etc/nginx/

# Remove the default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM settings
COPY configs/php-fpm/php-fpm.conf /etc/php7/php-fpm.conf
COPY configs/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
COPY configs/php-fpm/enviroment.env /etc/php7/php-fpm.d/ecs.env
RUN mkdir -p /var/log/php-fpm && \
  mkdir -p /run/php-fpm && \
  chown -R nobody:nobody /run/php-fpm && \
  chown -R nobody:nobody /var/log/php-fpm

# Configure supervisord
COPY configs/supervisor/conf.d/* /etc/supervisor/conf.d/
COPY configs/supervisor/supervisord.conf /etc/supervisor/
RUN mkdir -p /var/log/supervisor && \
  touch /var/log/supervisor/supervisord.log && \
  chown -R nobody:nobody /var/log/supervisor

# Setup document root
RUN mkdir -p /var/www/php

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/php && \
  chown -R nobody:nobody /run && \
  chown -R nobody:nobody /var/lib/nginx && \
  chown -R nobody:nobody /var/log/nginx

# Make sure that logs are redirected to stderr
RUN ln -sf $stdout /var/log/nginx/access.log && \
      ln -sf $stderr /var/log/nginx/error.log && \
      ln -sf $stderr /var/log/php-fpm/www-error.log

# Change clear_env setting in the php fpm settings in order to be able to read AWS env variables
# Ref issue: https://github.com/docker-library/php/issues/74
RUN sed -i -e 's/;clear_env = no/clear_env = no/' \
    /etc/php7/php-fpm.d/www.conf

# Update child process settings
RUN sed -i -e "s/pm.max_spare_servers = 35/pm.max_spare_servers = 10/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" /etc/php7/php-fpm.d/www.conf

# Increase cookie size
RUN sed -i '13 a large_client_header_buffers 8 64k;' /etc/nginx/nginx.conf
RUN sed -i '14 a client_header_buffer_size 64k;' /etc/nginx/nginx.conf

WORKDIR /var/www/php

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer -V

RUN npm install -g npm@6.14.10
RUN node -v \
  npm -v

# Expose the port nginx is reachable on
EXPOSE 80 443

COPY ./bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh
# Let supervisord start nginx & php-fpm
CMD ["/bin/sh", "-c", "/bootstrap.sh"]

RUN php -v
