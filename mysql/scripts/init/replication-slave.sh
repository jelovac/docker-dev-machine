#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ -z "$REPLICATION_MASTER_HOST" ]; then
    echo "REPLICATION_MASTER_HOST env variable is not set!"
    exit 1
fi

REPLICATION_USER=${MYSQL_REPLICATION_USER:-replication}
REPLICATION_PASSWORD=${MYSQL_REPLICATION_PASSWORD:-replication_pass}

mysql -u root -p$MYSQL_ROOT_PASSWORD -e "\
RESET MASTER; \
CHANGE MASTER TO \
  MASTER_HOST='$REPLICATION_MASTER_HOST', \
  MASTER_PORT=3306, \
  MASTER_USER='$REPLICATION_USER', \
  MASTER_PASSWORD='$REPLICATION_PASSWORD';"

echo "Dumping MySQL data from $REPLICATION_MASTER_HOST"

mysqldump \
  --protocol=tcp \
  --user=$REPLICATION_USER \
  --password=$REPLICATION_PASSWORD \
  --host=$REPLICATION_MASTER_HOST \
  --port=3306 \
  --hex-blob \
  --all-databases \
  --add-drop-database \
  --master-data \
  --flush-logs \
  --flush-privileges \
| mysql -u root

echo "Starting slave"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "START SLAVE;"

check_slave_health () {
  echo Checking replication health:
  status=$(mysql -u root -e "SHOW SLAVE STATUS\G")
  echo "$status" | egrep 'Slave_(IO|SQL)_Running:|Seconds_Behind_Master:|Last_.*_Error:' | grep -v "Error: $"
  if ! echo "$status" | grep -qs "Slave_IO_Running: Yes"    ||
     ! echo "$status" | grep -qs "Slave_SQL_Running: Yes"   ||
     ! echo "$status" | grep -qs "Seconds_Behind_Master: 0" ; then
	echo WARNING: Replication is not healthy.
    return 1
  fi
  return 0
}

echo "Checking inital slave health"
check_slave_health

echo Waiting for health grace period and slave to be still healthy:
sleep $REPLICATION_HEALTH_GRACE_PERIOD

counter=0
while ! check_slave_health; do
  if (( counter >= $REPLICATION_HEALTH_TIMEOUT )); then
    echo ERROR: Replication not healthy, health timeout reached, failing.
	break
    exit 1
  fi
  let counter=counter+1
  sleep 1
done