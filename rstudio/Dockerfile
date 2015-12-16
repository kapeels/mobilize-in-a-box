FROM debian:latest
MAINTAINER Steve Nolen <technolengy@gmail.com>
 
ENV RSTUDIO_VERSION 0.99.489


RUN set -x \
    && export DEBIAN_FRONTEND=noninteractive \
    && echo 'deb http://cran.rstudio.com/bin/linux/debian jessie-cran3/' >> /etc/apt/sources.list \
    && apt-key adv --keyserver keys.gnupg.net --recv-key 381BA480 \
    && apt-get update \
    && apt-get install -y r-base gdebi git curl libcurl4-openssl-dev ed \
    && curl -fSL http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -o /tmp/rstudio-server.deb \
    && gdebi -n /tmp/rstudio-server.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone --single-branch https://github.com/mobilizingcs/mobilizr /tmp/MobilizR

RUN /usr/bin/R -e 'install.packages(c("plyr", "dplyr", "mosaic", "ggplot2", "curl", "rstudioapi", "log4r"), repo = "http://cran.rstudio.com")'

WORKDIR /tmp
RUN /usr/bin/R CMD INSTALL MobilizR --library=/usr/local/lib/R/site-library
 
EXPOSE 8787

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize", "0"]