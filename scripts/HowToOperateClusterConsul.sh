#!/bin/bash
# Microproyecto
# 22/02/2024 - Edward Trejos 
# Este archivo describe como operar los servicios del cluster consul

# Inicio cluster consul serverProxy
#
# 1. Detener los servicios Consul en todas las máquinas:
sudo systemctl stop consul
# 2. Iniciar el servidor Consul en el servidor proxy (nodo principal del clúster):
consul agent -server -bootstrap-expect=1 -data-dir=/tmp/consul -node=proxyServer -bind=192.168.100.10 -ui -client=0.0.0.0
# 3. Iniciar los agentes de Consul en los nodos clientes (clientweb1 y clientweb2):
consul agent -data-dir=/tmp/consul -node=clientweb1 -bind=192.168.100.11 -join=192.168.100.10
consul agent -data-dir=/tmp/consul -node=clientweb2 -bind=192.168.100.12 -join=192.168.100.10
# 4. Verificar el estado del clúster Consul en todas las maquinas
consul members
# 5. registrar el haproxy-service.json en consul en el proxyServer - balanceo de carga
consul services register /etc/haproxy/haproxy-service.json
# 6. registrar el index y my_app.js en consul en clinetWeb1 y clientWeb2
consul services register /etc/consul/clientWeb1-service.json
consul services register /etc/consul/clientWeb2-service.json
#7. Verificación catalogo de servicios desde clientWeb1, clientWeb2 y proxyServer
consul catalog services
#8.Reiniciar servicio de balanceo de carga en el proxyServer
sudo systemctl restart haproxy
#9.Reiniciar el servicio node.js en los clientes (/home/vagrant/workspace) clienteweb1 y clientweb2
cd /home/vagrant/workspace/
pm2 start my_app.js
#10. Verificación desde el clientWeb1
curl 192.168.100.11:80
curl 192.168.100.11:3000
#11. Verificación desde el clientWeb2
curl 192.168.100.11:80
curl 192.168.100.11:3000
#12. Verificación del dashboard del proxyServer
curl 192.168.100.10:8500

# instalacion de artillery en clientWeb1
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
# cerrar y abrir de nuevo la terminal
nvm install --lts
artillery quick --count 10 -n 20 http://192.168.100.10:80/
artillery quick --count 10 -n 20 http://192.168.100.10:3000/


etc/systemd/system$ cd $HOME
$ sudo mkdir /var/lib/consul
$ sudo chown -R consul:consul /var/lib/consul
$ Environment=HOME=/var/lib/consul

