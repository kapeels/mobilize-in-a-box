#!/usr/bin/env bash

set -e


/usr/sbin/php5-fpm --fpm-config /etc/php5/fpm/php-fpm.conf --pid /var/run/php5-fpm.pid
exec /usr/sbin/nginx -g "daemon off;"