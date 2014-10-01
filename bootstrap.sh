#!/bin/bash
#bootstraps the mobilize-in-a-box installer. so the command can easily be executed from the web and then clone the repo from there and get to work

if [ "$EUID" -ne 0 ]
  then echo "Script needs to be run as root" 
  exit 1 
fi

#we'll use git alot, so we need that, certainly
apt-get install git -y

#now that that's done, clone the mobilize-in-a-box repo
git clone https://github.com/stevenolen/mobilize-in-a-box /opt/mobilize-in-a-box
chmod +x /opt/mobilize-in-a-box/setup.sh

#prepared.
echo "Setup is now prepared. Please execute /opt/mobilize-in-a-box/setup.sh as root to set up"
exit 0
