#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Script needs to be run as root"
  exit 1
fi

#need to add a few ppas for mariadb and nginx
apt-get install -y python-software-properties
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository -y 'deb http://mirror.jmu.edu/pub/mariadb/repo/5.5/ubuntu precise main'
add-apt-repository -y ppa:nginx/stable
apt-get update

#let's install the rest of the dependencies we need from apt
#TODO: right now we need to actually install x11 in order to get javac to compile the server/frontend..
xargs -a required_packages apt-get install -y

#let's install the rest of the dependencies we need from apt
mkdir -p /root/mobilize-in-a-box/git && cd /root/mobilize-in-a-box/git
while read line
do
  repo=$line
  git clone $repo
done < ../required_git_repos

#######compile the server#######
cd /root/mobilize-in-a-box/git/ohmageServer
git checkout ohmage-2.16-user_setup_password
ant clean dist
service tomcat7 stop
cp dist/webapp-ohmage-2.16.1-no_ssl.war /var/lib/tomcat7/webapps/app.war

#######prepare the db.########
echo "======= MySQL Root PW required to create 'ohmage' user ======"
mysql -uroot -p -e 'create database ohmage; grant all on ohmage.* to "ohmage"@"locahost" identified by "\&\!sickly";'
#remove the create database lines in the first file. who put these there?!
sed -i '1,5d' ./db/sql/base/ohmage-ddl.sql
mysql -uohmage -p\&\!sickly ohmage < ./db/sql/base/ohmage-ddl
mysql -uohmage -p\&\!sickly ohmage < ./db/sql/preferences/default_preferences.sql
for i in `ls -1 ./db/sql/settings/`
 do
 echo "mysql -uohmage -p\&\!sickly ohmage < $i"
done

#compile the gwt frontend
cd /root/mobilize-in-a-box/git/gwt-front-end
git checkout mobilize
ant clean build buildwar
rm -rf /root/mobilize-in-a-box/git/gwt-front-end/extracted/
mkdir /root/mobilize-in-a-box/git/gwt-front-end/extracted/
cd /root/mobilize-in-a-box/git/gwt-front-end/extracted/
jar xvf ../MobilizeWeb.war
mkdir -p /var/www/webapps/
cp -r * /var/www/webapps/web

#move the other www code to it's rightful location
cp -r /root/mobilize-in-a-box/git/campaignAuthoringTool /var/www/webapps/; mv /var/www/webapps/campaignAuthoringTool /var/www/webapps/authoring
cp -r /root/mobilize-in-a-box/git/campaign_monitor /var/www/webapps/; mv /var/www/webapps/campaign_monitor /var/www/webapps/monitor
cp -r /root/mobilize-in-a-box/git/teacher /var/www/webapps/
cp -r /root/mobilize-in-a-box/git/navbar /var/www
chown -R www-data.www-data /var/www

