#!/bin/sh
su -s /bin/sh -c 'php83 /var/www/nextcloud/occ upgrade' nginx
su -s /bin/sh -c 'php83 /var/www/nextcloud/occ db:add-missing-indices' nginx
su -s /bin/sh -c 'php83 /var/www/nextcloud/occ db:convert-filecache-bigint' nginx
