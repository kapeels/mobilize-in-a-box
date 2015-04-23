mobilize-in-a-box
=================

The goal of the mobilize-in-a-box project is to easily replicate the entire infrastructure in use for the Mobilize deployment on another server at any time.  It will contain config files and scripts which will seek out all sub-project dependencies and set up the server in a more-or-less sane way.  The understanding of the information in this readme is quite important to your success when attempting to run/deploy.

##INSTALL METHODS
The sections below offer advice on getting started. We suggest you use the vagrant install method as it is by far the quickest way to run and test these tools yourself, but is not really the suggested method if you plan to deploy this in your school district. The text installation method will instead allow your school systems administrator to pick and choose the necessary pieces to go on each server you plan to deploy (for example, during the Mobilize deployment it was quite necessary to deploy RStudio to a separate server because of load requirements).

###VAGRANT
The mobilize-in-a-box vagrant box is based on the [vagrant-ohmage](https://github.com/ohmage/vagrant-ohmage) box. Follow the steps below to get started!

  * Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
  * Install [Vagrant](https://vagrantup.com)
  * Install [git](http://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  * Clone this repository, `cd` to it.
  * type `vagrant up`
  * Access your installation from your system at `192.168.33.100`.

#### Installed Packages
The vagrant-ohmage box comes installed with the ohmage platform (java, tomcat7, mysql and nginx to serve the frontend code). The additional tools installed which are required for mobilize are:

  * [opencpu](https://opencpu.org)
  * [RStudio](http://rstudio.org)
  * [dokuwiki](http://dokuwiki.org)

Please see the references to these projects in the Manual instructions below if you have questions about how they are set up. 

#### Notes/TODOs
The vagrant install method is still in flux, so some portions may change.  At the time of this writing, here are a few items you may want to note:

  * RStudio requires system accounts, of which the only currently usable is `vagrant`. 
  * The dokuwiki install contains the latest public content from wiki.mobilizingcs.org. The permissions are currently set so that **anyone** may make edits
  * This method is currently missing the [Class Setup tool](https://github.com/mobilizingcs/teacher) to faciliate allowing teachers to create their own classes.

###Manual
The full mobilize stack involves a number of moving parts and pieces.  This manual install method will be broken into the steps required to get all user-facing tools running.  Any command suggestions are provided only as reference and with the expectation that you are running them on an Ubuntu 14.04 install. If you feel any piece of this needs more detail you are encouraged to a) submit an issue to this repo with your request or b) look through the first draft of this repo which had a [bash script to "automate" each step](https://github.com/stevenolen/mobilize-in-a-box/blob/221838aa5e1418ea2d7c70096851fd36e5e8d3b5/setup.sh)

####ohmage
ohmage requires the installation of mysql, tomcat and java, at the very least. You can grab the latest stable version of ohmage from [here](https://web.ohmage.org/ohmage/packages/latest/server/app.war) (which you'll need to place in /var/lib/tomcat7/webapps to get running). The ohmage database needs to be set up and and `/etc/ohmage.conf/` file used to direct ohmage to that database.

  * `apt-get install tomcat7 mysql-server`
  * `cd /var/lib/tomcat7/webapps/; wget https://web.ohmage.org/ohmage/packages/latest/server/app.war`
  * at `/etc/ohmage.conf` should be [ohmage.conf from this repo](https://github.com/stevenolen/manual-install-files/ohmage.conf)
  * create directories based on the ohmage.conf file (if default `mkdir -p /var/lib/ohmage/{audio,audits,documents,images,videos}; mkdir -p /var/log/ohmage`) and make sure they are owned by the `tomcat7` user (`chown -R tomcat7.tomcat7 /var/log/ohmage; chown -R tomcat7.tomcat7 /var/lib/ohmage`)
  * execute/pipe the `.sql` files from the [ohmage server repo](https://github.com/ohmage/server/tree/master/db/sql) to your created database
  * `service tomcat7 restart` and view /var/log/ohmage/ohmage.log for errors

Once the server component is available, you may serve frontends from nginx.  some of these frontends require compiling and some do not, so best to start out with the packaged files suggested below (additionally, you can find the source and installation instructions for each frontend at the [mobilize github organization](https://github.com/mobilizingcs)). The install method includes a navbar, which requires that all frontends be placed under `/var/www/navbar` (or `/var/www/webapps`). They are served via an iframe on the navbar page.

  * `apt-get install nginx`
  * remove default nginx conf: `rm /etc/nginx/sites-enabled/default`
  * at `/etc/nginx/sites-enabled/ohmage` should be [nginx-ohmage.conf from this repo](https://github.com/stevenolen/manual-install-files/nginx-ohmage.conf)
  * copy the [navbar](https://github.com/mobilizingcs/navbar) code to the root of `/var/www/`
  * for each of the files [here](https://web.ohmage.org/ohmage/packages/latest/), `wget $X; tar xvzf $X` and copy to `/var/www/navbar/` (the gwt-frontend dir should be named `web`)



####opencpu
opencpu installation is quite easy (though you'll notice it requires apache which clashes with nginx out of the box). Add the opencpu ppa, install it and remove the apache default configs. opencpu will be served from apache on port 8004.

  * `apt-get install software-properties-common`
  * `add-apt-repository -y ppa:opencpu/opencpu-1.4; apt-get update`
  * `apt-get install opencpu-server`
  * `rm /etc/apache2/sites-enabled/000-default.conf; rm /etc/apache2/sites-enabled/default-ssl.conf`
  * comment out ports in `/etc/apache2/ports.conf`
  * `service apache2 restart`
  * install the [plotbuilder](https://github.com/mobilizingcs/plotbuilder) package to R (`/usr/bin/R CMD INSTALL plotbuilder --library=/usr/local/lib/R/site-library`) and dependencies (`Ohmage` and `ggplot` R packages located in the standard CRAN repos.)
  * note the relevant lines in the nginx conf file under the ohmage section

####RStudio
Rstudio is a tool used by the IDS curriculum.  It does not authenticate through ohmage, so you'll need to sync your users manually for now. Install by executing:

  * `apt-get install rstudio-server`
  * note the relevant lines in the nginx conf file under the ohmage section

####Wiki
Much of the help for teachers and students comes from our wiki. You need only [dokuwiki](http://dokuwiki.org) and php to get this running:

  * latest stable version of dokuwiki from [here](http://download.dokuwiki.org/) (extracted and copied to /var/www/navbar/wiki or wherever you'd liked to deploy)
  * `apt-get install php5-fpm`
  * note the relevant lines in the nginx conf file under the ohmage section

####Notes

  * You'll likely need to change some of the links in the navbar based on where you end up hosting each individual piece. 
  * For a small deployment (<1000 students) the packages would require hardware similar to:
    * ohmage: 2 cores, 2-4GB ram
    * RStudio: 2-4 cores, 2-4GB ram
    * opencpu: negligible for mobilize needs
    * wiki: negligible for mobilize needs