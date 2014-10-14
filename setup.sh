#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Script needs to be run as root"
  exit 1
fi

#we'll use git alot, so we need that, certainly
apt-get -y install git < "/dev/null"

#now that that's done, clone the mobilize-in-a-box repo
git clone https://github.com/stevenolen/mobilize-in-a-box /opt/mobilize-in-a-box
cd /opt/mobilize-in-a-box

#need to add a few ppas for mariadb and nginx
apt-get install -y python-software-properties  < "/dev/null"
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.0/ubuntu trusty main'
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

#we also need some directories for ohmage to store data
mkdir -p /var/log/ohmage
mkdir -p /var/lib/ohmage/{audio,audits,documents,images,videos}
chown -R tomcat7.tomcat7 /var/log/ohmage
chown -R tomcat7.tomcat7 /var/lib/ohmage

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
mysql -uohmage --password="$dbpw" ohmage -e 'update preference set p_value = replace(p_value, "/opt/ohmage/userdata", "/var/lib/ohmage") where p_value like "%userdata%"; update preference set p_value = replace(p_value, "/opt/ohmage/logs", "/var/lib/ohmage") where p_value like "%audit%";'

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
cp -r /opt/mobilize-in-a-box/git/navbar/* /var/www
cp -r /opt/mobilize-in-a-box/dokuwiki* /var/www; mv /var/www/dokuwiki*/ /var/www/wiki
cp -ur /opt/mobilize-in-a-box/git/wiki/* /var/www/wiki/data/
chown -R www-data.www-data /var/www

#copy our config files into place
cp /opt/mobilize-in-a-box/files/ohmage /etc/ohmage.conf
cp /opt/mobilize-in-a-box/files/nginx /etc/nginx/sites-available/ohmage
ln -s /etc/nginx/sites-available/ohmage /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

#replace config based on our known items!
sed -i "s/db.password={DB_PASSWORD_HERE}/db.password=$dbpw/g" /etc/ohmage.conf
#set tomcat to use ipv4 on startup
echo 'JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv4Addresses"' >> /usr/share/tomcat7/bin/setenv.sh

#we're done!
echo "Looks like everything is set up. For your records: "
echo "mysql user ohmage has a password now set to: "$dbpw

######## start up some stuff ########
service nginx restart
service tomcat7 start
