# Build complete guacamole-server with custom keymap
FROM alpine:3.18 AS builder

# Install all build dependencies
# Split into multiple RUN commands to identify which package fails
RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    cairo-dev \
    libjpeg-turbo-dev \
    libtool \
    libpng-dev \
    openssl-dev \
    perl \
    wget

# Install protocol-specific dependencies
RUN apk add --no-cache \
    freerdp-dev || true

RUN apk add --no-cache \
    libssh2-dev \
    pango-dev || true

RUN apk add --no-cache \
    libvncserver-dev || true

RUN apk add --no-cache \
    libwebsockets-dev \
    libvorbis-dev \
    libwebp-dev || true

# Try to install optional dependencies
RUN apk add --no-cache \
    pulseaudio-dev \
    ffmpeg-dev \
    libtelnet-dev \
    ossp-uuid-dev || true

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

# Configure with all features (it will auto-detect what's available)
RUN autoreconf -fi && \
    ./configure --prefix=/opt/guacamole

# Build everything
RUN make && make install

# Final stage - use official guacd and replace the binaries
FROM guacamole/guacd:1.6.0

# Copy all the built files
COPY --from=builder /opt/guacamole /opt/guacamole

# The official image already has all runtime dependencies