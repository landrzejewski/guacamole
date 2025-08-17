# Multi-stage build to add custom keymap to guacd
FROM guacamole/guacd:1.6.0 as guacd-base

FROM debian:bullseye-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    autoconf \
    automake \
    libtool \
    wget \
    libcairo2-dev \
    libpng-dev \
    libjpeg-dev \
    libossp-uuid-dev \
    libfreerdp-dev \
    libpango1.0-dev \
    libssh2-1-dev \
    libtelnet-dev \
    libvncserver-dev \
    libwebsockets-dev \
    libpulse-dev \
    libssl-dev \
    libvorbis-dev \
    libwebp-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    && rm -rf /var/lib/apt/lists/*

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
    && ./configure --disable-guacenc --disable-guaclog \
    && make \
    && make install

# Final stage - use the official base and replace only the RDP plugin
FROM guacamole/guacd:1.6.0

# Copy the newly built RDP plugin with custom keymap
COPY --from=builder /usr/local/lib/libguac-client-rdp.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/freerdp2/*.so /usr/local/lib/freerdp2/

# Update library cache
RUN ldconfig