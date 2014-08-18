mobilize-in-a-box
=================

The goal of the mobilize-in-a-box project will be to easily replicate the entire infrastructure in use for the Mobilize deployment on another server at any time.  It will contain config files and scripts which will seek out all sub-project dependencies and set up the server in a more-or-less sane way.  The understanding of the information in this readme is quite important to your success when attempting to run/deploy. All instructions below (for the time being) assume you are installing this server on a linux distribution (namely, ubuntu or debian-alike).

##CONFIG

###ohmage
To be dropped in at /etc/ohmage.conf. Contains some basic information about how to access the db and what to log.  Note the commented section which shows how to enable teeing logs to a log server.  When ready to deploy, ensure you've changed the log levels from `INFO` to `WARN` (opting not to perform this step can degrade the server performance at high load levels).

###nginx
####main config file
####non-navbar file
A copy of the same file, but without the expectation that you'll use the unified navbar setup.  in this case, your local html content can be served from /var/www directly, instead of from /var/www/navbar).
####read-only
There may come a time when you would like to set the ohmage server to a 'read-only' like mode.  Perhaps if you're recovering from a backup and would like old data to be at least readable. This config file is to be added to an nginx include directory (/etc/nginx/includes/ro-ohmage is where we'll assume) and then a single line uncommented in the main nginx conf file (along with a `service nginx reload`) will make your server read-only if needed.  Here's the line to uncomment: `include includes/ro-ohmage;` in the main config file. 
