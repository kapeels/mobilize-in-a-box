#!/bin/bash
set -e

# hack to ensure that ohmage is accessible without leaving the docker network
if ping -c 1 ohmage > /dev/null 2>&1; then
  sed -i 's|var serverurl = location.protocol + "//" + location.host + "/app";|var serverurl = "http://ohmage:8080/app";|g' /usr/local/lib/R/site-library/plotbuilder/www/js/app.js
fi

exec "$@"