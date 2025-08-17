# Build just the RDP protocol plugin with custom keymap
FROM alpine:3.18 as builder

# Install build dependencies
RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    cairo-dev \
    freerdp-dev \
    libtool \
    openssl-dev \
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

# Configure only with RDP support
RUN autoreconf -fi && \
    ./configure \
        --disable-guacenc \
        --disable-guaclog \
        --disable-ssh \
        --disable-telnet \
        --disable-vnc \
        --disable-kubernetes \
        --prefix=/opt/guacamole

# Build only the RDP protocol
RUN cd src/protocols/rdp && make && make install

# Final stage - use official guacd and replace RDP plugin
FROM guacamole/guacd:1.6.0

# Copy only the RDP protocol plugin
COPY --from=builder /opt/guacamole/lib/libguac-client-rdp.so* /opt/guacamole/lib/

# The official image already handles library paths