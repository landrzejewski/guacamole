# Build complete guacamole-server with custom keymap
FROM alpine:3.18 as builder

# Install all build dependencies
RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    cairo-dev \
    freerdp-dev \
    libjpeg-turbo-dev \
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
    ossp-uuid-dev \
    ffmpeg-dev \
    perl \
    wget

# Download guacamole-server source
WORKDIR /tmp
RUN wget https://downloads.apache.org/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz \
    && tar -xzf guacamole-server-1.6.0.tar.gz

# Copy your custom keymap
COPY pl_pl_qwerty.keymap /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps/

# Add the keymap to Makefile.am
WORKDIR /tmp/guacamole-server-1.6.0
RUN cd src/protocols/rdp && \
    sed -i '/en_us_qwerty.keymap/a\\\tkeymaps/pl_pl_qwerty.keymap \\' Makefile.am

# Configure with all features
RUN autoreconf -fi && \
    ./configure --prefix=/opt/guacamole

# Build everything
RUN make && make install

# Final stage - use official guacd and replace the binaries
FROM guacamole/guacd:1.6.0

# Copy all the built files
COPY --from=builder /opt/guacamole /opt/guacamole

# The official image already has all runtime dependencies