FROM alpine:3.8

LABEL maintainer="Rune Chan <renee@runechan.dev>"

ENV KONG_VERSION 1.1.0
ENV USER root

RUN apk add --no-cache --virtual .build-deps linux-headers \
    libgcc libc-dev pcre perl tzdata libcap su-exec bsd-compat-headers \
    m4 git luarocks curl gcc make pcre pcre-dev zlib-dev yaml yaml-dev

WORKDIR /tmp
RUN wget https://openresty.org/download/openresty-1.13.6.2.tar.gz \
    && wget https://github.com/Kong/openresty-patches/archive/master.tar.gz \
    && wget https://www.openssl.org/source/openssl-1.1.0j.tar.gz \
    && wget http://luarocks.github.io/luarocks/releases/luarocks-2.4.3.tar.gz \
    && tar -xvf openresty-1.13.6.2.tar.gz \
    && tar -xvf master.tar.gz \
    && tar -xvf openssl-1.1.0j.tar.gz \
    && tar -xvf luarocks-2.4.3.tar.gz

WORKDIR /tmp/openssl-1.1.0j
RUN ./config \
    && make -j8 \
    && make install

WORKDIR /tmp/openresty-1.13.6.2/bundle
RUN for i in ../../openresty-patches-master/patches/1.13.6.2/*.patch; do patch -p1 < $i; done

WORKDIR /tmp/openresty-1.13.6.2
RUN ./configure --with-pcre-jit \
                --with-ipv6 \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_stub_status_module \
                --with-stream_ssl_preread_module \
                --with-stream_realip_module \
                --with-http_v2_module -j8 \
    && make -j8 \
    && make install

WORKDIR /tmp/luarocks-2.4.3
RUN ./configure \
       --lua-suffix=jit \
       --with-lua=/usr/local/openresty/luajit \
       --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install

RUN rm -rf /tmp/*

WORKDIR /
RUN wget https://raw.githubusercontent.com/Kong/docker-kong/c3448c49bfe775fec5182a1c6a21f7e44d1d8d4d/alpine/docker-entrypoint.sh \
    && git clone https://github.com/Kong/kong \
    && cd kong/ \
    && git checkout tags/${KONG_VERSION} \
    && luarocks make \
    && make dev

ENV PATH="/usr/local/openresty/luajit/bin/luajit:/usr/local/openresty/nginx/sbin:/kong/bin:/usr/local/openresty/bin:${PATH}"

WORKDIR /kong

RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGTERM

CMD ["kong", "start"]