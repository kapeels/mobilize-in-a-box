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
apt-get -y install openjdk-7-jdk --no-install-recommends < "/dev/null"
export DEBIAN_FRONTEND=noninteractive
apt-get -y install $(cat required_packages) < "/dev/null"

#let's install the rest of the dependencies we need from apt
mkdir -p /opt/mobilize-in-a-box/git && cd /opt/mobilize-in-a-box/git
while read line
do
  repo=$line
  git clone $repo
done < /opt/mobilize-in-a-box/required_git_repos

#misc other packages we need. dokuwiki for a lightweight wiki
wget -P /opt/mobilize-in-a-box/ http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
tar zxf /opt/mobilize-in-a-box/dokuwiki-stable.tgz -C /opt/mobilize-in-a-box/
rm /opt/mobilize-in-a-box/dokuwiki-stable.tgz

#######compile the server#######
cd /opt/mobilize-in-a-box/git/ohmageServer
git checkout ohmage-2.16-user_setup_password
ant clean dist
service tomcat7 stop
cp dist/webapp-ohmage-2.16.1-no_ssl.war /var/lib/tomcat7/webapps/app.war

#######prepare the db.########
dbpw=`date | md5sum | head -c20`
mysql -uroot -e 'create database ohmage; grant all on ohmage.* to "ohmage"@"localhost" identified by "'$dbpw'"; flush privileges;'
#remove the create database lines in the first file. who put these there?!
sed -i '1,5d' /opt/mobilize-in-a-box/git/ohmageServer/db/sql/base/ohmage-ddl.sql
mysql -uohmage --password="$dbpw" ohmage < /opt/mobilize-in-a-box/git/ohmageServer/db/sql/base/ohmage-ddl.sql
mysql -uohmage --password="$dbpw" ohmage < /opt/mobilize-in-a-box/git/ohmageServer/db/sql/preferences/default_preferences.sql
for i in `ls -1d /opt/mobilize-in-a-box/git/ohmageServer/db/sql/settings/*`
 do
 mysql -uohmage --password="$dbpw" ohmage < $i
done

#compile the gwt frontend
cd /opt/mobilize-in-a-box/git/gwt-front-end
git checkout mobilize
ant clean build buildwar
rm -rf /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
mkdir /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
cd /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
jar xvf ../MobilizeWeb.war
mkdir -p /var/www/webapps/web
cp -r * /var/www/webapps/web

#move the other www code to it's rightful location
cp -r /opt/mobilize-in-a-box/git/campaignAuthoringTool /var/www/webapps/; mv /var/www/webapps/campaignAuthoringTool /var/www/webapps/authoring
cp -r /opt/mobilize-in-a-box/git/campaign_monitor /var/www/webapps/; mv /var/www/webapps/campaign_monitor /var/www/webapps/monitor
cp -r /opt/mobilize-in-a-box/git/teacher /var/www/webapps/
cp -r /opt/mobilize-in-a-box/git/navbar/ /var/www
#cp -r /opt/mobilize-in-a-box/dokuwiki*; mv /var/www/dokuwiki*/ /var/www/wiki
#cp -ur /opt/mobilize-in-a-box/git/wiki/* /var/www/wiki/data/
chown -R www-data.www-data /var/www

#we're done!
echo "Looks like everything is set up. For your records: "
echo "mysql user ohmage has a password now set to: "$dbpw
