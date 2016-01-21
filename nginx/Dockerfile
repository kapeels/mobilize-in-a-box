FROM nginx:latest
MAINTAINER Steve Nolen <technolengy@gmail.com>
 
RUN set -x \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# nginx container contains all of the static frontends ohmage uses.
RUN git clone -b master --single-branch https://github.com/mobilizingcs/navbar /var/www \
    && sed -i 's/config = ohmageConfig.initialize();/config = mobilizeInABoxConfig/g' /var/www/config.js
RUN ln -s /ohmage-frontends /var/www/webapps \
  && ln -s /var/www/webapps /var/www/navbar
 
EXPOSE 80

ADD nginx.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx.nginx /var/www

CMD ["nginx", "-g", "daemon off;"]