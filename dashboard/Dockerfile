FROM alpine:3.2  
MAINTAINER technolengy@gmail.com

RUN apk --update add --virtual build-deps make nodejs git \
  && git clone https://github.com/mobilizingcs/dashboard /tmp/dashboard \
  && cd /tmp/dashboard \
  && npm install -g jade recess uglify-js \
  && mkdir -p /var/www/webapps/dashboard \
  && make CAMPAIGN=snack OUT=/tmp/output \
  && mv /tmp/output/* /var/www/webapps/dashboard \
  && apk del build-deps && rm -rf /tmp/*

VOLUME /var/www/webapps/dashboard
