#!/bin/bash
echo  "[INFO] HOSTNAME:$HOSTNAME, PUID:$PUID, PGID:$PGID, TZ:$TZ"
echo " bash version: "
bash --version | head -n 1
echo " dpkg version: "
dpkg -s dash | grep ^Version | awk '{print $2}'
echo " curl version: "
curl --version
echo " nvm version: "
bash -i -c 'nvm -v'
echo " node version: "
bash -i -c 'node --version'
echo " npm version: "
bash -i -c 'npm --version'
echo " "
git --version
echo " php version: "
php -v
echo " composer version: "
composer --version

exec "$@"