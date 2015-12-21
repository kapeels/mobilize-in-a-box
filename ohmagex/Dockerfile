FROM alpine:3.2  
MAINTAINER technolengy@gmail.com

ENV NODE_PATH /usr/lib/node_modules
ENV STATIC_VOLUME /var/www/survey

RUN apk --update add --virtual build-deps build-base ruby-dev nodejs git \
  && gem install bundler --no-ri --no-rdoc \
  && git clone https://github.com/ucla/ohmageX /tmp/ohmageX \
  && cd /tmp/ohmageX \
  && bundle install \
  && npm install \
  && npm install -g bower \
  && node_modules/grunt-cli/bin/grunt webblocks_build \
  && node_modules/grunt-cli/bin/grunt dev \
  && mkdir -p /var/www/webapps/survey \
  && mv /tmp/ohmageX/www/* /var/www/webapps/survey \
  && apk del build-deps && rm -rf /tmp/* /usr/lib/node*

VOLUME /var/www/webapps/survey
