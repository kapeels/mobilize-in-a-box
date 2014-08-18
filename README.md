mobilize-in-a-box
=================

The goal of the mobilize-in-a-box project will be to easily replicate the entire infrastructure in use for the Mobilize deployment on another server at any time.  It will contain config files and scripts which will seek out all sub-project dependencies and set up the server in a more-or-less sane way.  The understanding of the information in this readme is quite important to your success when attempting to run/deploy. All instructions below (for the time being) assume you are installing this server on a linux distribution (namely, ubuntu or debian-alike).

##CONFIG

###ohmage
To be dropped in at /etc/ohmage.conf. Contains some basic information about how to access the db and what to log.  Note the commented section which shows how to enable teeing logs to a log server.  When ready to deploy, ensure you've changed the log levels from `INFO` to `WARN` (opting not to perform this step can degrade the server performance at high load levels).
