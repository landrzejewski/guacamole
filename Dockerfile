FROM debian:bullseye-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    automake \
    autoconf \
    libtool \
    # ... (all the -dev packages from above)

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
FROM debian:bullseye-slim

# Copy built files
COPY --from=builder /usr/local /usr/local

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    # ... (runtime packages without -dev suffix)
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

EXPOSE 4822
ENTRYPOINT ["/usr/local/sbin/guacd"]
CMD ["-b", "0.0.0.0", "-f"]