# Build only the keymap file
FROM alpine:3.18 as builder

# Install only essential build tools
RUN apk add --no-cache \
    build-base \
    perl \
    wget

# Download guacamole-server source
WORKDIR /tmp
RUN wget https://downloads.apache.org/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz \
    && tar -xzf guacamole-server-1.6.0.tar.gz

# Copy your custom keymap
COPY pl_pl_qwerty.keymap /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps/

# Go to the keymaps directory
WORKDIR /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps

# Generate the compiled keymap file
RUN perl generate.pl pl_pl_qwerty.keymap > pl_pl_qwerty.compiled

# Final stage - use official guacd and add the compiled keymap
FROM guacamole/guacd:1.6.0

# Copy the compiled keymap to where guacd expects it
COPY --from=builder /tmp/guacamole-server-1.6.0/src/protocols/rdp/keymaps/pl_pl_qwerty.compiled /opt/guacamole/share/guacamole-server/keymaps/pl_pl_qwerty