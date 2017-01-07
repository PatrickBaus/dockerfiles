#!/bin/sh
su -s /bin/sh -c 'php /var/www/nextcloud/occ upgrade' nginx
