#!/bin/sh
chown -hR nobody:nobody /var/www/php
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
