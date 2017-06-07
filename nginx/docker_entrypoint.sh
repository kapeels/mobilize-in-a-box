#!/usr/bin/env bash

NEOADMIN_URL_REWRITE=${NEOADMIN_URL_REWRITE:-disabled}

ln -s /ohmage-frontends /var/www/webapps
ln -s /var/www/webapps /var/www/navbar
chown -R www-data.www-data /var/www/

# generate nginx conf on start
## the first echo block here uses the "ohmage" and "ocpu" dependencies.
echo 'server {
  listen       80;

  location / {
    root   /var/www;
    index  index.html index.htm;' > /etc/nginx/conf.d/default.conf

# neo-admin rewrite rule
if [ "$NEOADMIN_URL_REWRITE" == "enabled" ]
then
  echo '    location /navbar/neo-admin/ {
      try_files $uri $uri/ /navbar/neo-admin/index.html;
    }
    location = /navbar/neo-admin/index.html { }' >> /etc/nginx/conf.d/default.conf
fi

echo '  }

  location /app/ {
    proxy_pass http://ohmage:8080/app/;
    proxy_read_timeout  600s;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        Host $http_host;
  }

  location /ocpu {
    proxy_pass http://ocpu/ocpu;
    proxy_redirect http://ocpu/ /;

  }

  location /navbar/plotapp/ {
    proxy_pass http://ocpu:80/ocpu/library/plotbuilder/www/;
  }
  rewrite /navbar/plotapp$ /navbar/plotapp/ permanent;' >> /etc/nginx/conf.d/default.conf

# now we case out the additions of other backends depending on if they are available on the network
# this is important because nginx dies if it can't find an upstream

# wiki
if ping -c 1 wiki > /dev/null 2>&1; then
  echo '  location /navbar/wiki {
    proxy_pass http://wiki:80/;
    proxy_read_timeout  600s;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        Host $http_host;
  }' >> /etc/nginx/conf.d/default.conf
fi

# rstudio
if ping -c 1 rstudio > /dev/null 2>&1; then
  echo '      location /navbar/rstudio/ {
      rewrite ^/navbar/rstudio/(.*)$ /$1 break;
      proxy_pass http://rstudio:8787;
      proxy_redirect http://rstudio:8787/ $scheme://$host/navbar/rstudio/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_read_timeout 20d;
    }' >> /etc/nginx/conf.d/default.conf
fi

# pw generator
if ping -c 1 pw > /dev/null 2>&1; then
  echo '  location /password/simple/ {
    proxy_pass http://pw:5000/password;
  }' >> /etc/nginx/conf.d/default.conf
fi


# properly end the server block.
echo '}' >> /etc/nginx/conf.d/default.conf

exec /usr/sbin/nginx -g "daemon off;"