FROM alpine:3.8

LABEL maintainer="Rune Chan <rune.meowmeow@gmail.com>"

ENV KONG_VERSION 1.0.2
ENV USER root

RUN apk add --no-cache --virtual .build-deps linux-headers \
    libgcc libc-dev pcre perl tzdata libcap su-exec bsd-compat-headers \
    m4 git luarocks curl lua5.1-dev gcc make pcre pcre-dev zlib-dev

WORKDIR /tmp
RUN wget https://openresty.org/download/openresty-1.13.6.2.tar.gz \
    && wget https://github.com/Kong/openresty-patches/archive/master.tar.gz \
    && wget https://www.openssl.org/source/openssl-1.1.0j.tar.gz \
    && tar -xvf openresty-1.13.6.2.tar.gz \
    && tar -xvf master.tar.gz \
    && tar -xvf openssl-1.1.0j.tar.gz

WORKDIR /tmp/openssl-1.1.0j
RUN ./config \
    && make -j8 \
    && make install

WORKDIR /tmp/openresty-1.13.6.2/bundle
RUN for i in ../../openresty-patches-master/patches/1.13.6.2/*.patch; do patch -p1 < $i; done

WORKDIR /tmp/openresty-1.13.6.2
RUN ./configure --with-pcre-jit \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_stub_status_module \
                --with-http_v2_module -j8 \
    && make -j8 \
    && make install

RUN rm -rf /tmp/*

WORKDIR /
RUN wget https://raw.githubusercontent.com/Kong/docker-kong/c3448c49bfe775fec5182a1c6a21f7e44d1d8d4d/alpine/docker-entrypoint.sh \
    && git clone https://github.com/Kong/kong \
    && cd kong/ \
    && git checkout tags/1.0.2 \
    && luarocks-5.1 make \
    && sed -i -e 's/luarocks/luarocks-5.1/g' Makefile \
    && make dev

ENV PATH="/usr/local/openresty/nginx/sbin:/kong/bin:/usr/local/openresty/bin:${PATH}"

WORKDIR /kong

RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGTERM

CMD ["kong", "start"]


ADD kong_tests.conf /kong/spec/kong_tests.conf