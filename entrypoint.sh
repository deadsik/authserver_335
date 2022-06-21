#!/bin/bash
set -e

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo "Both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# Loads various settings that are used elsewhere in the script
docker_setup_env() {
    # Initialize values that might be stored in a file
    file_env 'AUTHSERVER_REALMSERVERPORT' $DEFAULT_AUTHSERVER_REALMSERVERPORT
    file_env 'AUTHSERVER_BINDIP' $DEFAULT_AUTHSERVER_BINDIP
    file_env 'AUTHSERVER_MYSQL_AUTOCONF' $DEFAULT_AUTHSERVER_MYSQL_AUTOCONF
    file_env 'AUTHSERVER_MYSQL_HOST' $DEFAULT_AUTHSERVER_MYSQL_HOST
    file_env 'AUTHSERVER_MYSQL_PORT' $DEFAULT_AUTHSERVER_MYSQL_PORT
    file_env 'AUTHSERVER_MYSQL_USER' $DEFAULT_AUTHSERVER_MYSQL_USER
    file_env 'AUTHSERVER_MYSQL_PASSWORD' $DEFAULT_AUTHSERVER_MYSQL_PASSWORD
    file_env 'AUTHSERVER_MYSQL_DB' $DEFAULT_AUTHSERVER_MYSQL_DB
}

docker_setup_env

if $AUTHSERVER_MYSQL_AUTOCONF ; then
# Set MYSQL Credentials in authserver.conf
  sed -r -i 's/^LoginDatabaseInfo = .*$/LoginDatabaseInfo = "'${AUTHSERVER_MYSQL_HOST}';'${AUTHSERVER_MYSQL_PORT}';'${AUTHSERVER_MYSQL_USER}';'${AUTHSERVER_MYSQL_PASSWORD}';'${AUTHSERVER_MYSQL_DB}'"/' /home/server/wow/etc/authserver.conf
  unset -v AUTHSERVER_MYSQL_PASSWORD
fi

sed -r -i 's/^RealmServerPort = .*$/RealmServerPort = '${AUTHSERVER_REALMSERVERPORT}'/' /home/server/wow/etc/authserver.conf
sed -r -i 's/^BindIP = .*$/BindIP = '${AUTHSERVER_BINDIP}'/' /home/server/wow/etc/authserver.conf

# Run authserver
sudo -H -u server bash -c "cd /home/server/wow/bin/ && ./authserver"
exec "$@"
