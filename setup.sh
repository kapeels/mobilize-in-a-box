#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Script needs to be run as root"
  exit 1
fi

#need to add a few ppas for mariadb and nginx
echo "################## Installing: python-software-properties  ##################" 
apt-get install -y python-software-properties  < "/dev/null" &>> /opt/mobilize-in-a-box/run.log
echo "################## Installing: mariadb 10.0 ppa  ##################" 
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db &> /opt/mobilize-in-a-box/run.log
add-apt-repository 'deb http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.0/ubuntu trusty main' &> /opt/mobilize-in-a-box/run.log
echo "################## Installing: opencpu ppa  ##################" 
add-apt-repository -y ppa:opencpu/opencpu-1.4 &> /opt/mobilize-in-a-box/run.log
echo "################## Installing: nginx ppa  ##################" 
add-apt-repository -y ppa:nginx/stable &> /opt/mobilize-in-a-box/run.log
echo "################## Updating apt packages  ##################" 
apt-get update &> /opt/mobilize-in-a-box/run.log

#let's install the rest of the dependencies we need from apt
#TODO: right now we need to actually install x11 in order to get javac to compile the server/frontend..
echo "################## Installing: openjdk-7-jdk  ##################" 
apt-get -y install openjdk-7-jdk --no-install-recommends < "/dev/null" &> /opt/mobilize-in-a-box/run.log
export DEBIAN_FRONTEND=noninteractive
echo "################## Installing: $(cat required_packages)  ##################" 
apt-get -y install $(cat required_packages) < "/dev/null" &> /opt/mobilize-in-a-box/run.log

#let's install the rest of the dependencies we need from apt
mkdir -p /opt/mobilize-in-a-box/git && cd /opt/mobilize-in-a-box/git
while read line
do
  repo=$line
  echo "################## Git clone: $repo  ##################"
  git clone $repo &> /opt/mobilize-in-a-box/run.log &> /opt/mobilize-in-a-box/run.log
done < /opt/mobilize-in-a-box/required_git_repos

#misc other packages we need. dokuwiki for a lightweight wiki
echo "################## Installing: dokuwiki  ##################"
wget -P /opt/mobilize-in-a-box/ http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz &> /opt/mobilize-in-a-box/run.log
tar zxf /opt/mobilize-in-a-box/dokuwiki-stable.tgz -C /opt/mobilize-in-a-box/ &> /opt/mobilize-in-a-box/run.log
rm /opt/mobilize-in-a-box/dokuwiki-stable.tgz

#######compile the server#######
echo "################## Compiling: ohmageServer  ##################"
cd /opt/mobilize-in-a-box/git/ohmageServer
git checkout ohmage-2.16-user_setup_password &> /opt/mobilize-in-a-box/run.log
ant clean dist &> /opt/mobilize-in-a-box/run.log
service tomcat7 stop &> /opt/mobilize-in-a-box/run.log
cp dist/webapp-ohmage-2.16.1-no_ssl.war /var/lib/tomcat7/webapps/app.war

#we also need some directories for ohmage to store data
echo "################## Preparing: /var/lib/ohmage/{audio,audits,documents,images,videos}  ##################"
mkdir -p /var/log/ohmage
mkdir -p /var/lib/ohmage/{audio,audits,documents,images,videos}
chown -R tomcat7.tomcat7 /var/log/ohmage
chown -R tomcat7.tomcat7 /var/lib/ohmage

#######prepare the db.########
echo "################## Preparing: ohmage db  ##################"
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
echo "################## Compiling: ohmage gwt-frontend  ##################"
cd /opt/mobilize-in-a-box/git/gwt-front-end
git checkout mobilize &> /opt/mobilize-in-a-box/run.log
ant clean build buildwar &> /opt/mobilize-in-a-box/run.log
rm -rf /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
mkdir /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
cd /opt/mobilize-in-a-box/git/gwt-front-end/extracted/
jar xvf ../MobilizeWeb.war &> /opt/mobilize-in-a-box/run.log
mkdir -p /var/www/webapps/web
cp -r * /var/www/webapps/web

#compile the generalized dashboard
echo "################## Compiling: generlized dashboard  ##################"
cd /opt/mobilize-in-a-box/git/dashboard
#installing nodejs from debian is kinda crap
ln -s /usr/bin/nodejs /usr/bin/node
export PATH=$PATH:/usr/local/share/npm/bin/
#why make a package.json, let's just install them all separately.
npm -g install jade &> /opt/mobilize-in-a-box/run.log
npm -g install recess &> /opt/mobilize-in-a-box/run.log
npm -g install uglify-js &> /opt/mobilize-in-a-box/run.log
make CAMPAIGN=snack OUT=/var/www/webapps/publicdashboard &> /opt/mobilize-in-a-box/run.log
make CAMPAIGN=snack OUT=/var/www/webapps/dashboard &> /opt/mobilize-in-a-box/run.log

#move the other www code to it's rightful location
echo "################## Preparing: copying www projects to /var/www  ##################"
cp -r /opt/mobilize-in-a-box/git/campaignAuthoringTool /var/www/webapps/; mv /var/www/webapps/campaignAuthoringTool /var/www/webapps/authoring
cp -r /opt/mobilize-in-a-box/git/campaign_monitor /var/www/webapps/; mv /var/www/webapps/campaign_monitor /var/www/webapps/monitor
cp -r /opt/mobilize-in-a-box/git/teacher /var/www/webapps/
cp -r /opt/mobilize-in-a-box/git/navbar/* /var/www
cp -r /opt/mobilize-in-a-box/dokuwiki* /var/www; mv /var/www/dokuwiki*/ /var/www/wiki
cp -ur /opt/mobilize-in-a-box/git/wiki/* /var/www/wiki/data/
chown -R www-data.www-data /var/www

#copy our config files into place
echo "################## Preparing: copying ohmage and nginx conf files  ##################"
cp /opt/mobilize-in-a-box/files/ohmage /etc/ohmage.conf
cp /opt/mobilize-in-a-box/files/nginx /etc/nginx/sites-available/ohmage
ln -s /etc/nginx/sites-available/ohmage /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

#we installed ocpu, which needs to use apache
rm /etc/apache2/sites-enabled/000-default.conf
rm /etc/apache2/sites-enabled/default-ssl.conf
rm /etc/apache2/ports.conf

#install plotbuilder and dependencies
echo "################## Compiling: R package dependencies for plotapp  ##################"
cd /opt/mobilize-in-a-box/git/
/usr/bin/R -e 'install.packages(c("Ohmage","ggplot2"), repos="http://cran.rstudio.com/")' &> /opt/mobilize-in-a-box/run.log
echo "################## Installing: plotapp  ##################"
/usr/bin/R CMD INSTALL plotbuilder --library=/usr/local/lib/R/site-library &> /opt/mobilize-in-a-box/run.log


#replace config based on our known items!
sed -i "s/db.password={DB_PASSWORD_HERE}/db.password=$dbpw/g" /etc/ohmage.conf
#set tomcat to use ipv4 on startup
echo 'JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv4Addresses"' >> /usr/share/tomcat7/bin/setenv.sh

#we're done!
echo "################## Finished! ##################"
echo \n\n"Looks like everything is set up. For your records: "
echo "mysql user ohmage has a password now set to: "$dbpw

######## start up some stuff ########
service nginx restart &> /opt/mobilize-in-a-box/run.log
service tomcat7 start &> /opt/mobilize-in-a-box/run.log
service apache2 restart &> /opt/mobilize-in-a-box/run.log
