# -*- mode: ruby -*-
# vi: set ft=ruby :
# Configuración Vagrantfile
# Edward Trejos
# Microproyecto - Cloud
# 25/02/2024

Vagrant.configure("2") do |config|
  # Configuración para el plugin vagrant-vbguest si está instalado
  if Vagrant.has_plugin? "vagrant-vbguest"
    config.vbguest.no_install  = true
    config.vbguest.auto_update = false
    config.vbguest.no_remote   = true
  end
  # Configuración para aumentar el tiempo de espera de arranque
  config.vm.boot_timeout = 1800 # Aumenta el tiempo de espera a 600 segundos

  # Configuración para la máquina Web1
  config.vm.define :clientWeb1 do |clientWeb1|
    clientWeb1.vm.box = "bento/ubuntu-22.04"
    clientWeb1.vm.network :private_network, ip: "192.168.100.11"
    clientWeb1.vm.hostname = "clientWeb1"
    # Aprovisionamiento tipo Shell
    clientWeb1.vm.provision "shell", path: "scripts/script_clientWeb1.sh"
    clientWeb1.vm.provision "shell", path: "scripts/script_clientWeb1-Consul.sh"
    # Aprovisionando recursos para la maquina clientWeb1
    clientWeb1.vm.provider "clientWeb1" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
    end
    # Directorio sincronizado para la máquina clientWeb1
    clientWeb1.vm.synced_folder "c:/temp", "/vagrant/tmp"
  end

  # Configuración para la máquina clientWeb2
  config.vm.define :clientWeb2 do |clientWeb2|
    clientWeb2.vm.box = "bento/ubuntu-22.04"
    clientWeb2.vm.network :private_network, ip: "192.168.100.12"
    clientWeb2.vm.hostname = "clientWeb2"
    # Aprovisionamiento tipo Shell
    clientWeb2.vm.provision "shell", path: "scripts/script_clientWeb2.sh"
    clientWeb2.vm.provision "shell", path: "scripts/script_clientWeb2-Consul.sh"
    # Aprovisionando recursos para la maquina clientWeb2
    clientWeb2.vm.provider "clientWeb2" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
    end
    # Directorio sincronizado para la máquina clientWeb2
    clientWeb2.vm.synced_folder "c:/temp", "/vagrant/tmp"
  end

  # Configuración para la máquina proxyServer
  config.vm.define :proxyServer do |proxyServer|
    proxyServer.vm.box = "bento/ubuntu-22.04"
    proxyServer.vm.network :private_network, ip: "192.168.100.10"
    proxyServer.vm.hostname = "proxyServer"
    # Aprovisionamiento tipo Shell
    proxyServer.vm.provision "shell", path: "scripts/script_proxyServer.sh"
    proxyServer.vm.provision "shell", path: "scripts/script_proxyServer-Consul.sh"
    # Aprovisionando recursos para la maquina proxyServer
    proxyServer.vm.provider "proxyServer" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
    end
    # Directorio sincronizado para la máquina proxyServer
    proxyServer.vm.synced_folder "c:/temp", "/vagrant/tmp"
  end
end
