# ---------- Build stage ----------
FROM alpine:3.20 AS build

ARG VER=1.6.0
WORKDIR /tmp

RUN apk add --no-cache \
    build-base autoconf automake libtool pkgconfig wget tar \
    cairo-dev libpng-dev jpeg-dev libwebp-dev util-linux-dev \
    freerdp-dev libvncserver-dev libssh2-dev \
    libwebsockets-dev pango-dev \
    ffmpeg-dev

# Download sources
RUN wget -q https://downloads.apache.org/guacamole/${VER}/source/guacamole-server-${VER}.tar.gz \
 && tar -xzf guacamole-server-${VER}.tar.gz

# Copy in your custom keymap
COPY pl_pl_qwerty.keymap guacamole-server-${VER}/src/protocols/rdp/keymaps/pl_pl_qwerty.keymap

# Build with your keymap included
RUN cd guacamole-server-${VER} \
 && ./configure --prefix=/usr --sysconfdir=/etc --disable-telnet \
 && make -j"$(nproc)" \
 && make DESTDIR=/tmp/install install
