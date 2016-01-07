# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessi"
  config.vm.provider "virtualbox", memory: "1024"
  config.vm.network "private_network", ip: "192.168.33.100"
  config.vm.synced_folder ".", "/box", type: "rsync", rsync__exclude: [".git/", ".data/", "package.box"]
  config.vm.provision :docker
  config.vm.provision :docker_compose, yml: "/box/docker-compose.yml", run: "always", project_name: "box"
  config.vm.provision :shell, inline: 'apt-get clean'
end
