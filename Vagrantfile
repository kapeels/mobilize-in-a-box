# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  config.push.define "atlas" do |push|
    push.app = "mobilizingcs/box"
  end

  config.vm.provision :shell, inline: "apt-get update && apt-get install -y apt-transport-https"
  config.vm.provision :docker
  config.vm.provision :docker_compose, yml: "/vagrant/docker-compose.yml", run: "always"
end
