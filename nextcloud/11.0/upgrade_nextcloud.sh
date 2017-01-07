#!/bin/sh
su -s /bin/sh -c 'php7 /var/www/nextcloud/occ upgrade' nginx
