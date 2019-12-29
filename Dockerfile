# ##################################################################
# FlightTracker ADS-B all in one docker including the following:
#   DUMP1090
#   PIAWARE 
#   FR24FEED
# ##################################################################

# VARIABLES ########################################################
ARG DUMP1090_VERSION=v3.7.1
ARG DUMP1090_GIT_HASH=40614778bc97a322c671c609f17a41f3eee3b194
ARG DUMP1090_TAR_HASH=b63df996c5ffc6c30e8d4d0d70272794b70a044cb1aa4179108d283c14464e6b

# BASE #############################################################
FROM alpine as base

RUN cat /etc/apk/repositories && \
    echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories && \
    echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    cat /etc/apk/repositories && \
    apk add --no-cache tini librtlsdr@testing libusb ncurses-libs

# BUILDER ##########################################################
FROM base as builder

RUN apk add --no-cache \
        curl ca-certificates \
        coreutils make gcc pkgconf \
        libc-dev librtlsdr-dev@testing libusb-dev ncurses-dev

# DUMP1090 (ADS-B RADIO) INSTALL
WORKDIR /tmp
RUN apt-get update && \
    apt-get install sudo build-essential debhelper librtlsdr-dev pkg-config dh-systemd libncurses5-dev libbladerf-dev -y 
RUN git clone https://github.com/flightaware/dump1090 && \
    cd dump1090 && \
    make && mkdir /usr/lib/fr24 && cp dump1090 /usr/lib/fr24/ && cp -r public_html /usr/lib/fr24/
COPY config.js /usr/lib/fr24/public_html/
RUN mkdir /usr/lib/fr24/public_html/data

# PIAWARE (FLIGHTAWARE) INSTALL
WORKDIR /tmp
RUN apt-get update && \
    apt-get install sudo build-essential debhelper tcl8.6-dev autoconf python3-dev python-virtualenv libz-dev dh-systemd net-tools tclx8.4 tcllib tcl-tls itcl3 python3-venv dh-systemd init-system-helpers  libboost-system-dev libboost-program-options-dev libboost-regex-dev libboost-filesystem-dev -y 
RUN git clone https://github.com/flightaware/piaware_builder.git piaware_builder
WORKDIR /tmp/piaware_builder
RUN ./sensible-build.sh stretch && cd package-stretch && dpkg-buildpackage -b && cd .. && dpkg -i piaware_*_*.deb
COPY piaware.conf /etc/

# FR24FEED (FLIGHTRADAR24) INSTALL
WORKDIR /fr24feed
RUN wget https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_1.0.18-5_amd64.tgz \
    && tar -xvzf *amd64.tgz
COPY fr24feed.ini /etc/

EXPOSE 8754 8080 30001 30002 30003 30004 30005 30104 
