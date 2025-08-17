FROM guacamole/guacamole-server:latest

RUN sed -i '19s/parent "base"/parent "base_altgr"/' \
    /src/protocols/rdp/keymaps/pl_pl_qwerty.keymap

RUN cd /src && \
    make clean && \
    make && \
    make install