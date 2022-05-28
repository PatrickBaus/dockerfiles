#!/bin/sh
su -s /bin/sh -c 'php8 /var/www/nextcloud/occ upgrade' nginx
su -s /bin/sh -c 'php8 /var/www/nextcloud/occ db:add-missing-indices' nginx
