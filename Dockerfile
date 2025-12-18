FROM alpine:3.23.2 AS base

ARG FREESWITCH_VERSION="v1.10.12"
ARG SOFIA_VERSION="v1.13.17"

FROM base AS deps

RUN \
  apk --no-cache upgrade \
  && apk --no-cache add \
    git

RUN \
  git clone --depth 1 --branch "${FREESWITCH_VERSION}" https://github.com/signalwire/freeswitch /freeswitch \
  && rm -rf /freeswitch/.git \
  && git clone --depth 1 --branch "${SOFIA_VERSION}" https://github.com/freeswitch/sofia-sip /libdeps/sofia-sip \
  && rm -rf /sofia-sip/.git


FROM base AS builder-sofia

COPY --from=deps /libdeps/sofia-sip ./libdeps/sofia-sip
COPY patches/sofia-sip/. ./patches

RUN \
  apk --no-cache upgrade \
  && apk add --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    openssl-dev \
    glib-dev \
    lksctp-tools-dev

RUN \
  cd ./libdeps/sofia-sip \
  && for i in /patches/*.patch; do patch -p1 < $i; done \
  && ./bootstrap.sh \
  && ./configure --prefix=/usr --enable-sctp --with-openssl --without-doxygen --enable-static=no \
  && make -j$(nproc --all) \
  && make DESTDIR=/build install


FROM base AS builder-freeswitch

COPY --from=deps /freeswitch/ ./app
#COPY modules.conf ./app
COPY --from=builder-sofia /build/. .
COPY patches/freeswitch/. ./patches

RUN \
  apk --no-cache upgrade \
  && apk add --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    libjpeg-turbo-dev \
    spandsp3-dev \
    zlib-dev \
    sqlite-dev \
    curl-dev \
    pcre-dev \
    speex-dev \
    speexdsp-dev \
# mod_enum
    ldns-dev \
    libks-dev \
    libedit-dev \
    diffutils \
    nasm \
    python3-dev \
    py3-setuptools \
    linux-headers \
    util-linux-dev \
    unixodbc-dev \
    libpq-dev \
    mariadb-dev \
    mpg123-dev \
    tiff-dev \
    flite-dev \
    lua5.3-dev \
    perl-dev \
    opus-dev \
    portaudio-dev \
# mod_sangoma_codec
    sngtc_client-dev \
# mod_shout
    libshout-dev\
    lame-dev \
# mod_snmp
    net-snmp-dev\
# mod_sndfile
    libsndfile-dev

RUN \
  cd /app \
  && for i in /patches/*.patch; do patch -p1 < $i; done \
  && ./bootstrap.sh -j \
  && ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    # follow Redhat/SUSE package layout
    --enable-fhs \
    --with-scriptdir=/etc/freeswitch/scripts \
    --with-rundir=/run/freeswitch \
    --with-logfiledir=/var/log/freeswitch \
    --with-dbdir=/var/spool/freeswitch/db \
    --with-certsdir=/etc/freeswitch/certs \
    --with-python3 \
    --enable-core-odbc-support \
    --enable-core-pgsql-support \
    --enable-zrtp \
    --enable-system-lua \
  && make -j$(nproc) \
  && make install \
  && make DESTDIR=/build install \
  && make DESTDIR=/build samples-conf \
  && make DESTDIR=/build cd-moh-install \
  && make DESTDIR=/build cd-sounds-install \
  && ldd $(which freeswitch) | cut -d" " -f3 | xargs tar --dereference -cf /build/libs.tar


FROM base AS runner

ARG WORKER_USER_ID=499

COPY --from=builder-freeswitch /build/. .

RUN \
  addgroup -g ${WORKER_USER_ID} freeswitch \
  && adduser -D -u ${WORKER_USER_ID} -G freeswitch freeswitch \
  && apk --no-cache upgrade \
  && apk add --no-cache \
    opus \
    libsndfile \
    lua5.3-libs \
    libpq \
    libks \
    ldns \
  && tar -xf libs.tar \
  && rm libs.tar

EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 5066/tcp
EXPOSE 7443/tcp
EXPOSE 8081/tcp 8082/tcp
EXPOSE 64535-65535/udp
EXPOSE 16384-32768/udp

HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

# USER freeswitch
CMD ["/usr/bin/freeswitch"]
