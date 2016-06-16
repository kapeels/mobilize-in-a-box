#!/bin/bash

# how frequently to sync.
SYNC=${SYNC:-0}
SYNC_SECONDS=${SYNC_SECONDS:-120}
DB_HOST=${DB_HOST:-db}

sync() {
while true
do
  # wait for mysql to start
  echo -n "ensuring mysql is available before syncing..."
  while ! nc -w 1 $DB_HOST 3306 &> /dev/null
  do
    sleep 1
  done
  echo "done."
  rm -f /tmp/account_sync.db
  /usr/bin/ruby /sync.rb
  sleep $SYNC_SECONDS
done
}

rstudio() {
  echo "Starting rstudio server..."
  /usr/lib/rstudio-server/bin/rserver --server-daemonize 0
}

# only starts sync if sync is enabled
if [ $SYNC == 1 ]
then
  sync & sync_pid=${!}
fi
rstudio & rstudio_pid=${!}

trap "{ kill $sync_pid; kill $rstudio_pid; exit 0; }" SIGTERM

while true
do
  tail -f /dev/null & wait ${!}
done
