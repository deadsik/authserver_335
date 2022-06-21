FROM ubuntu:20.04 
MAINTAINER admin <evgeniy@kolesnyk.ru> 

ENV AUTHSERVER_TZ="Etc/UTC" \
    AUTHSERVER_SYSTEM_CORES="8" \
    AUTHSERVER_SYSTEM_USER="server" \
    DEFAULT_AUTHSERVER_REALMSERVERPORT="3724" \
    DEFAULT_AUTHSERVER_BINDIP="0.0.0.0" \
    DEFAULT_AUTHSERVER_MYSQL_AUTOCONF=true \
    DEFAULT_AUTHSERVER_MYSQL_HOST="127.0.0.1" \
    DEFAULT_AUTHSERVER_MYSQL_PORT="3306" \
    DEFAULT_AUTHSERVER_MYSQL_USER="trinity" \
    DEFAULT_AUTHSERVER_MYSQL_PASSWORD="trinity" \
    DEFAULT_AUTHSERVER_MYSQL_DB="auth"

ARG DEBIAN_FRONTEND=noninteractive

RUN ln -snf /usr/share/zoneinfo/$AUTHSERVER_TZ /etc/localtime && echo $AUTHSERVER_TZ > /etc/timezone && \
    apt-get update && apt-get install -y apt-utils && \
    apt-get upgrade -y && \
    apt-get install build-essential autoconf libtool gcc g++ make git-core wget p7zip-full libncurses5-dev zlib1g-dev libbz2-dev openssl libssl-dev libreadline6-dev libboost-dev libboost-thread-dev libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-iostreams-dev libzmq3-dev libmysqlclient-dev libmysql++-dev curl mysql-client sudo -y

RUN curl -o /root/cmake-3.23.0-rc2.tar.gz https://cmake.org/files/v3.23/cmake-3.23.0-rc2.tar.gz && \
    cd /root && tar xzf cmake-3.23.0-rc2.tar.gz && \
    cd cmake-3.23.0-rc2 && \
    ./configure && \
    make -j $AUTHSERVER_SYSTEM_CORES && \
    make install && \
    rm -rf /root/cmake-3.23.0-rc2 && \
    rm -f /root/cmake-3.23.0-rc2.tar.gz

RUN useradd -ms /bin/bash $AUTHSERVER_SYSTEM_USER && \
    mkdir -p /home/$AUTHSERVER_SYSTEM_USER/wow && \
    mkdir -p /home/$AUTHSERVER_SYSTEM_USER/source && \
    cd /home/$AUTHSERVER_SYSTEM_USER/source && \
    git clone https://github.com/TrinityCore/TrinityCore.git && \
    mkdir -p /home/$AUTHSERVER_SYSTEM_USER/source/TrinityCore/build && \
    cd /home/$AUTHSERVER_SYSTEM_USER/source/TrinityCore && \
    git checkout -b 3.3.5 origin/3.3.5 && \
    cd /home/$AUTHSERVER_SYSTEM_USER/source/TrinityCore/build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=/home/$AUTHSERVER_SYSTEM_USER/wow && \
    make -j $AUTHSERVER_SYSTEM_CORES && \
    make install && \
    chown -R $AUTHSERVER_SYSTEM_USER:$AUTHSERVER_SYSTEM_USER /home/$AUTHSERVER_SYSTEM_USER/ && \
    mv /home/$AUTHSERVER_SYSTEM_USER/wow/etc/authserver.conf.dist /home/$AUTHSERVER_SYSTEM_USER/wow/etc/authserver.conf

RUN cd /home/$AUTHSERVER_SYSTEM_USER/wow/bin/ && rm -f mapextractor mmaps_generator vmap4assembler vmap4extractor worldserver && \
    rm -f /home/$AUTHSERVER_SYSTEM_USER/wow/etc/worldserver.conf.dist

ADD entrypoint.sh /

EXPOSE 3724

ENTRYPOINT ["/entrypoint.sh"]
