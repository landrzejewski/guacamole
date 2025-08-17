FROM guacamole/guacd:latest

# Install build tools temporarily
USER root
RUN apk add --no-cache \
    build-base \
    git \
    automake \
    autoconf \
    libtool \
    wget \
    tar

# Get the source code that matches the installed version
RUN GUACD_VERSION=$(guacd -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) && \
    cd /tmp && \
    wget -O guacamole-server.tar.gz "https://archive.apache.org/dist/guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz" && \
    tar -xzf guacamole-server.tar.gz

# Copy your keymap
COPY pl_pl_qwerty.keymap /tmp/guacamole-server-*/src/protocols/rdp/keymaps/

# Rebuild just the RDP protocol module
RUN cd /tmp/guacamole-server-* && \
    autoreconf -fi && \
    ./configure && \
    cd src/protocols/rdp && \
    make && \
    make install

# Clean up
RUN apk del build-base git automake autoconf libtool wget tar && \
    rm -rf /tmp/guacamole-server* && \
    ldconfig || true

# Switch back to the guacd user if it exists
USER guacd