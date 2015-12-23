#!/bin/bash

# account in cron
SYNC_MIN=${SYNC_MIN:-5}
echo "*/$SYNC_MIN * * * * /usr/bin/ruby /sync.rb" > /etc/cron.d/account_sync
/etc/init.d/cron start

# start rstudio as PS 1
exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0