mobilize-in-a-box
=================

The goal of the mobilize-in-a-box project will be to easily replicate the entire infrastructure in use for the Mobilize deployment on another server at any time.  It will contain config files and scripts which will seek out all sub-project dependencies and set up the server in a more-or-less sane way.  The understanding of the information in this readme is quite important to your success when attempting to run/deploy. All instructions below (for the time being) assume you are installing this server on a linux distribution (namely, ubuntu or debian-alike).

##GETTING STARTED
Please read the CONFIG section below..but once you have, feel free to begin bootstrapping by executing this command as root. It will git clone this repo so we can get started!
```
curl -s https://raw.githubusercontent.com/stevenolen/mobilize-in-a-box/master/setup.sh | bash
```

##CONFIG

###ohmage
To be dropped in at /etc/ohmage.conf. Contains some basic information about how to access the db and what to log.  Note the commented section which shows how to enable teeing logs to a log server.  When ready to deploy, ensure you've changed the log levels from `INFO` to `WARN` (opting not to perform this step can degrade the server performance at high load levels).

###nginx
####main config file
The main nginx config file. to be placed in /etc/nginx/sites-available/ and symlinked to /etc/nginx/sites-enabled in order to actual make active.  Here's what it's doing:
  * upstream directive denotes 'ohmage' upstream server connects to the localhost on port 8080.
  * the main server directive listens on HTTPS
   * configure the cert (full chain required in one file as per standard nginx config) and key location
   * read-only ohmage line commented as per info below.
   * requests to the root redirect to the landing page, the main page for app with navbar
   * some of our different clients link to various locations under the root, when we use the navbar we must visit these pages in the navbar context, so redirect as needed. 
   * actually handles the proxying of /app traffic to the upstream ohmage server.
   * `location /password;` is used by our class setup tool to help easily create readable passwords (thanks to makeagoodpassword.com for providing a public API of this type)
   * the next directives deny access to git and java servlet files (our web frontend, while static content, was originally served via tomcat.
   * `location /ocpu;` and `location /navbar/plotapp;` proxy traffic handled by opencpu for visualizations to an opencpu server. [TODO: change these in the config when in-a-box supports a local opencpu server]
   * Finally, the HTTP server directive redirects all traffic, as we should never allow non-encrypted traffic between our server and clients.

####no-navbar file
A copy of the same file, but without the expectation that you'll use the unified navbar setup.  in this case, your local html content can be served from /var/www directly, instead of from /var/www/navbar).
####read-only
There may come a time when you would like to set the ohmage server to a 'read-only' like mode.  Perhaps if you're recovering from a backup and would like old data to be at least readable. This config file is to be added to an nginx include directory (/etc/nginx/includes/ro-ohmage is where we'll assume) and then a single line uncommented in the main nginx conf file (along with a `service nginx reload`) will make your server read-only if needed.  Here's the line to uncomment: `include includes/ro-ohmage;` in the main config file. 
