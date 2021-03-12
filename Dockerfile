FROM alpine:3.11
LABEL Maintainer="eliurkis@gmail.com" \
      Description="Container with Nginx 1.16 & PHP-FPM 7.x based on Alpine Linux."
ENV stdout /dev/stdout
ENV stderr /dev/stderr

# Install packages
RUN apk add --update \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/community

RUN apk add gnu-libiconv --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk --no-cache add \
  php7 \
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
  nginx \
  supervisor \
  curl \
  git \
  nodejs \
  npm \
  php-xmlwriter \
  php-zip \
  php-bcmath

# Configure nginx
COPY nginx/conf.d/vhosts.conf /etc/nginx/conf.d
COPY nginx/* /etc/nginx/
# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY php-fpm/php-fpm.conf /etc/php7/php-fpm.conf
COPY php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
COPY php-fpm/ecs.env /etc/php7/php-fpm.d/ecs.env
RUN mkdir -p /var/log/php-fpm && \
  mkdir -p /run/php-fpm && \
  chown -R nobody:nobody /run/php-fpm && \
  chown -R nobody:nobody /var/log/php-fpm

# Configure supervisord
COPY supervisor/conf.d/* /etc/supervisor/conf.d/
COPY supervisor/supervisord.conf /etc/supervisor/
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

# Install Required glibc library for New Relic
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
  apk add glibc-2.31-r0.apk

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

# Expose the port nginx is reachable on
EXPOSE 80 443

COPY ./start.sh /start.sh
RUN chmod +x /start.sh
# Let supervisord start nginx & php-fpm
CMD ["/bin/sh", "-c", "/start.sh"]
