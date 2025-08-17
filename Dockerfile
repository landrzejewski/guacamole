# syntax=docker/dockerfile:1.7

############################
#  Build stage
############################
FROM alpine:3.20 AS build

ARG VER=1.6.0
WORKDIR /src

# Build dependencies (no libtelnet on Alpine 3.20)
RUN apk add --no-cache \
  build-base autoconf automake libtool pkgconfig wget tar \
  ccache \
  cairo-dev libpng-dev jpeg-dev libwebp-dev util-linux-dev \
  freerdp-dev libvncserver-dev libssh2-dev \
  libwebsockets-dev pango-dev \
  ffmpeg-dev

# Fetch sources
RUN wget -q https://downloads.apache.org/guacamole/${VER}/source/guacamole-server-${VER}.tar.gz \
 && tar -xzf guacamole-server-${VER}.tar.gz \
 && rm -f guacamole-server-${VER}.tar.gz

# Replace Polish QWERTY keymap before configure
COPY pl_pl_qwerty.keymap guacamole-server-${VER}/src/protocols/rdp/keymaps/pl_pl_qwerty.keymap

# Configure & build (disable Telnet), stage install into /stage
RUN cd guacamole-server-${VER} \
 && export CC="ccache gcc" CXX="ccache g++" \
 && export CFLAGS="-O2 -pipe" CXXFLAGS="-O2 -pipe" LDFLAGS="-Wl,--as-needed" \
 && ./configure --prefix=/usr --sysconfdir=/etc --disable-telnet \
 && make -j"$(nproc)" \
 && make DESTDIR=/stage install

# Strip and prune unneeded files from the staged tree
RUN cd /stage \
 && find . -type f -name "*.a" -delete \
 && find . -type f -name "*.la" -delete \
 && find usr -type f -executable -exec strip --strip-unneeded '{}' + || true \
 && rm -rf usr/include usr/lib/pkgconfig usr/share/{doc,man,info}

############################
#  Runtime stage
############################
FROM alpine:3.20

# Minimal runtime libs (no Telnet)
RUN apk add --no-cache \
  cairo libpng libjpeg-turbo libwebp util-linux \
  freerdp libvncserver libssh2 \
  libwebsockets pango ffmpeg-libs \
  busybox-extras tini

# Non-root user
RUN adduser -D -H -s /sbin/nologin guacd

# Copy the installed files from the build stage
COPY --from=build /stage/ /

# Runtime dirs (avoid clean exit due to missing /run/guacd)
RUN mkdir -p /run/guacd /var/log/guacd \
 && chown -R guacd:guacd /run/guacd /var/log/guacd

EXPOSE 4822
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD nc -z 127.0.0.1 4822 || exit 1

USER guacd
ENTRYPOINT ["/sbin/tini","--"]
CMD ["/usr/sbin/guacd","-f","-b","0.0.0.0","-l","4822","-L","info"]
