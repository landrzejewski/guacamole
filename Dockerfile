# Simpler approach - build from source in Alpine
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    cairo \
    freerdp \
    freerdp-libs \
    libjpeg-turbo \
    libpng \
    libssh2 \
    libtelnet \
    libvncserver \
    libvorbis \
    libwebp \
    libwebsockets \
    nettle \
    openssl \
    pango \
    pulseaudio-libs \
    terminus-font \
    ttf-dejavu \
    ttf-liberation \
    util-linux \
    ffmpeg-libs

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    automake \
    build-base \
    cairo-dev \
    cmake \
    freerdp-dev \
    git \
    jpeg-dev \
    libtool \
    libpng-dev \
    libssh2-dev \
    libtelnet-dev \
    libvncserver-dev \
    libvorbis-dev \
    libwebp-dev \
    libwebsockets-dev \
    openssl-dev \
    pango-dev \
    pulseaudio-dev \
    util-linux-dev \
    ffmpeg-dev \
    wget

# Download and build guacamole-server
WORKDIR /tmp
RUN wget https://downloads.apache.org/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz \
    && tar -xzf guacamole-server-1.6.0.tar.gz

# Add custom keymap
COPY pl_pl_qwerty.keymap /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps/

# Modify Makefile.am to include the new keymap
WORKDIR /tmp/guacamole-server-1.6.0/src/protocols/rdp
RUN sed -i '/rdp_keymaps =/,/^[[:space:]]*$/{/en_us_qwerty.keymap/a\\\tkeymaps/pl_pl_qwerty.keymap \\' Makefile.am

# Build and install
WORKDIR /tmp/guacamole-server-1.6.0
RUN autoreconf -fi \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --disable-guaclog \
    && make -j$(nproc) \
    && make install

# Cleanup
RUN apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Create guacd user
RUN addgroup -S guacd && adduser -S -G guacd guacd

# Expose guacd port
EXPOSE 4822

# Set user and start guacd
USER guacd
CMD ["guacd", "-b", "0.0.0.0", "-f"]