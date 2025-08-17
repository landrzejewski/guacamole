# Multi-stage build to add custom keymap to guacd
FROM alpine:3.18 as builder

# Install build dependencies
RUN apk add --no-cache \
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

# Download guacamole-server source
WORKDIR /tmp
RUN wget https://downloads.apache.org/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz \
    && tar -xzf guacamole-server-1.6.0.tar.gz

# Add custom keymap
COPY pl_pl_qwerty.keymap /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps/

# Modify Makefile.am to include the new keymap
WORKDIR /tmp/guacamole-server-1.6.0/src/protocols/rdp
RUN sed -i '/rdp_keymaps =/,/^[[:space:]]*$/{/en_us_qwerty.keymap/a\\\tkeymaps/pl_pl_qwerty.keymap \\' Makefile.am

# Build guacamole-server
WORKDIR /tmp/guacamole-server-1.6.0
RUN autoreconf -fi \
    && ./configure \
        --prefix=/opt/guacamole \
        --disable-guacenc \
        --disable-guaclog \
    && make \
    && make install

# Final stage - use the official base
FROM guacamole/guacd:1.6.0

# Copy the newly built RDP plugin with custom keymap
COPY --from=builder /opt/guacamole/lib/libguac-client-rdp.so* /opt/guacamole/lib/
COPY --from=builder /opt/guacamole/lib/freerdp2/*.so /opt/guacamole/lib/freerdp2/

# Note: The official guacd image already has the library paths configured