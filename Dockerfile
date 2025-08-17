# syntax=docker/dockerfile:1.7

############################
#  Build stage
############################
FROM alpine:3.20 AS build

ARG VER=1.6.0
WORKDIR /src

# Speedy apk + compiler caching
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      build-base autoconf automake libtool pkgconfig wget tar \
      ccache \
      cairo-dev libpng-dev jpeg-dev libwebp-dev util-linux-dev \
      freerdp-dev libvncserver-dev libssh2-dev \
      libwebsockets-dev pango-dev \
      ffmpeg-dev

# Fetch sources (cached layer)
RUN --mount=type=cache,target=/var/cache/apk \
    wget -q https://downloads.apache.org/guacamole/${VER}/source/guacamole-server-${VER}.tar.gz \
 && tar -xzf guacamole-server-${VER}.tar.gz \
 && rm -f guacamole-server-${VER}.tar.gz

# Drop in your custom keymap BEFORE configure
# (Make sure this file sits next to your Dockerfile)
COPY pl_pl_qwerty.keymap guacamole-server-${VER}/src/protocols/rdp/keymaps/pl_pl_qwerty.keymap

# Build with ccache + optimizations, disable Telnet (Alpine lacks libtelnet-dev)
# Use cache mount for compiler outputs to speed up rebuilds
RUN --mount=type=cache,target=/root/.cache/ccache \
    cd guacamole-server-${VER} \
 && export CC="ccache gcc" CXX="ccache g++" \
 && export CFLAGS="-O2 -pipe" CXXFLAGS="-O2 -pipe" LDFLAGS="-Wl,--as-needed" \
 && ./configure --prefix=/usr --sysconfdir=/etc --disable-telnet \
 && make -j"$(nproc)" \
 && make DESTDIR=/stage install

# Minify stage tree: strip binaries/libs; remove headers/pkgconfig/manpages
RUN cd /stage \
 && find . -type f -name "*.a" -delete \
 && find . -type f -name "*.la" -delete \
 && find usr -type f -executable -exec strip --strip-unneeded '{}' + || true \
 && rm -rf usr/include usr/lib/pkgconfig usr/share/{doc,man,info}

############################
#  Runtime stage
############################
FROM alpine:3.20

# Minimal runtime (no telnet). util-linux is correct on Alpine 3.20.
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      cairo libpng libjpeg-turbo libwebp util-linux \
      freerdp libvncserver libssh2 \
      libwebsockets pango ffmpeg-libs \
      busybox-extras tini

# Non-root user
RUN adduser -D -H -s /sbin/nologin guacd

# Copy only what we installed (already stripped/minified)
COPY --from=build /stage/ /

# Optional logs directory
RUN mkdir -p /var/log/guacd && chown -R guacd:guacd /var/log/guacd

EXPOSE 4822
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD nc -z 127.0.0.1 4822 || exit 1

USER guacd
ENTRYPOINT ["/sbin/tini","--"]
CMD ["guacd","-f","-b","0.0.0.0","-l","4822"]





## ---------- Build stage ----------
#FROM alpine:3.20 AS build
#
#ARG VER=1.6.0
#WORKDIR /tmp
#
#RUN apk add --no-cache \
#    build-base autoconf automake libtool pkgconfig wget tar \
#    cairo-dev libpng-dev jpeg-dev libwebp-dev util-linux-dev \
#    freerdp-dev libvncserver-dev libssh2-dev \
#    libwebsockets-dev pango-dev \
#    ffmpeg-dev
#
## Download sources
#RUN wget -q https://downloads.apache.org/guacamole/${VER}/source/guacamole-server-${VER}.tar.gz \
# && tar -xzf guacamole-server-${VER}.tar.gz
#
## Copy in your custom keymap
#COPY pl_pl_qwerty.keymap guacamole-server-${VER}/src/protocols/rdp/keymaps/pl_pl_qwerty.keymap
#
## Build with your keymap included
#RUN cd guacamole-server-${VER} \
# && ./configure --prefix=/usr --sysconfdir=/etc --disable-telnet \
# && make -j"$(nproc)" \
# && make DESTDIR=/tmp/install install
