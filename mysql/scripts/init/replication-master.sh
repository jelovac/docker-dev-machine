#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Create replication user
REPLICATION_USER=${MYSQL_REPLICATION_USER:-replication}
REPLICATION_PASSWORD=${MYSQL_REPLICATION_PASSWORD:-replication_pass}

mysql -u root -p$MYSQL_ROOT_PASSWORD -e "\
GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%' \
  IDENTIFIED BY '$REPLICATION_PASSWORD'; \
  FLUSH PRIVILEGES; \
"