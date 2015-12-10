FROM debian:latest
MAINTAINER Steve Nolen <technolengy@gmail.com>
 
ENV RSTUDIO_VERSION 0.99.489


RUN set -x \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y r-base gdebi \
    && curl -fSL http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -o /tmp/rstudio-server.deb \
    && gdebi -n /tmp/rstudio-server.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
 
EXPOSE 80

CMD ["/bin/bash"]