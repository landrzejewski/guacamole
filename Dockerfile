FROM guacamole/guacd:latest

# Install build tools temporarily
USER root
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    automake \
    autoconf \
    libtool \
    && rm -rf /var/lib/apt/lists/*

# Get the source code that matches the installed version
RUN GUACD_VERSION=$(guacd -v | grep -oP 'guacd version \K[0-9.]+') && \
    cd /tmp && \
    wget -O guacamole-server.tar.gz "https://apache.org/dyn/closer.lua/guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz?action=download" && \
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
RUN apt-get remove -y build-essential git automake autoconf libtool && \
    apt-get autoremove -y && \
    rm -rf /tmp/guacamole-server* && \
    ldconfig

USER guacd