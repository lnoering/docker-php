#!/bin/sh -e

echo "Starting the php-fpm"

/usr/sbin/php-fpm --daemonize --fpm-config /usr/local/php7/etc/php-fpm.conf

if [ -z "$1" ]
then
    /bin/bash
fi

exec "$@"