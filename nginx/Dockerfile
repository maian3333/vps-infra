FROM openresty/openresty:bullseye

# Install required system dependencies
RUN apt update && apt install -y \
    curl \
    lua5.1 \
    liblua5.1-0-dev \
    unzip \
    git \
    build-essential

# Install the latest LuaRocks manually
WORKDIR /tmp
RUN curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-3.11.0.tar.gz && \
    tar -xzf luarocks-3.11.0.tar.gz && \
    cd luarocks-3.11.0 && \
    ./configure --with-lua-include=/usr/include/lua5.1 && \
    make && \
    make install && \
    cd .. && \
    rm -rf luarocks-3.11.0 luarocks-3.11.0.tar.gz

# Install OpenID Connect Lua module
RUN luarocks install lua-resty-openidc
RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-jwt
RUN luarocks install lua-resty-session

# Ensure OpenResty can find the installed Lua modules
ENV LUA_PATH "/usr/local/share/lua/5.1/?.lua;;"
ENV LUA_CPATH "/usr/local/lib/lua/5.1/?.so;;"

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]