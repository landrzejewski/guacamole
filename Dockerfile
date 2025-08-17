FROM guacamole/guacd:latest

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool

RUN apt-get install -y git && \
    git clone https://github.com/apache/guacamole-server.git /tmp/guacamole-server

RUN sed -i '19s/parent "base"/parent "base_altgr"/' \
    /tmp/guacamole-server/src/protocols/rdp/keymaps/pl_pl_qwerty.keymap

RUN cd /tmp/guacamole-server && \
    autoreconf -fi && \
    ./configure --with-init-dir=/etc/init.d && \
    make && \
    make install && \
    ldconfig

RUN apt-get remove -y build-essential autoconf automake libtool git && \
    apt-get autoremove -y && \
    rm -rf /tmp/guacamole-server