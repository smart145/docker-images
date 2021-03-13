# PHP & Nginx Image
- PHP-FPM 7.4
- Nginx 1.16
- Alpine Linux
- Node v14.15.4 (npm 6.14.10)

# How to use
```dockerfile
FROM smart145org/nginx-phpfm:latest

WORKDIR /var/www/php
COPY . /var/www/php
RUN cd /var/www/php

RUN composer install --no-dev
RUN npm ci
RUN npm run prod

RUN php artisan config:cache \
    && php artisan route:cache \
    && chown -hR nobody:nobody /var/www/php

# Cron for Laravel scheduler
RUN mkdir /etc/cron.d
RUN touch /etc/cron.d/task-scheduler
RUN echo "* * * * * php /var/www/php/artisan schedule:run >> /proc/1/fd/1 2>>/proc/1/fd/2" >> /etc/cron.d/task-scheduler
RUN chmod 0644 /etc/cron.d/task-scheduler
RUN crontab /etc/cron.d/task-scheduler
RUN crond restart

EXPOSE 80
```
