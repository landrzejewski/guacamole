FROM debian:bookworm-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    automake \
    autoconf \
    libtool \
    libcairo2-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libtool-bin \
    libossp-uuid-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    freerdp2-dev \
    libpango1.0-dev \
    libssh2-1-dev \
    libtelnet-dev \
    libvncserver-dev \
    libwebsockets-dev \
    libpulse-dev \
    libssl-dev \
    libvorbis-dev \
    libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build guacamole-server
RUN git clone https://github.com/apache/guacamole-server.git /guacamole-server
WORKDIR /guacamole-server

# Copy your custom keymap BEFORE building
COPY pl_pl_qwerty.keymap /guacamole-server/src/protocols/rdp/keymaps/

# You might also need to add it to Makefile.am
RUN echo "pl_pl_qwerty.keymap" >> /guacamole-server/src/protocols/rdp/keymaps/Makefile.am

RUN autoreconf -fi \
    && ./configure \
    && make \
    && make install

# Final stage
FROM debian:bookworm-slim

# Copy built files
COPY --from=builder /usr/local /usr/local

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    netcat-openbsd \
    ca-certificates \
    ghostscript \
    fonts-liberation \
    fonts-dejavu \
    xfonts-terminus \
    libcairo2 \
    libjpeg62-turbo \
    libpng16-16 \
    libossp-uuid16 \
    libavcodec59 \
    libavformat59 \
    libavutil57 \
    libswscale6 \
    freerdp2-x11 \
    libpango-1.0-0 \
    libssh2-1 \
    libtelnet2 \
    libvncclient1 \
    libwebsockets17 \
    libpulse0 \
    libssl3 \
    libvorbis0a \
    libwebp7 \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

EXPOSE 4822
ENTRYPOINT ["/usr/local/sbin/guacd"]
CMD ["-b", "0.0.0.0", "-f"]