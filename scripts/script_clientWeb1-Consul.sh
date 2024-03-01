#!/bin/bash
# Configuración script_clienteWeb1
# Edward Trejos
# Microproyecto - Cloud
# Este script permite la confiuguración de consul y la aplicación en node.js
# 25/02/2024

# 1ra parte, instalación de node.j2

# Ruta al archivo de log
LOG_FILE="/var/log/cluster.log"

# Cambiar permisos y propietario archivo log
sudo chmod u+w /var/log/cluster.log
sudo chown vagrant /var/log/cluster.log

# Actualizar y actualizar paquetes
sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
sudo apt install -y nodejs npm >> "$LOG_FILE" 2>&1
sudo npm install -g pm2 >> "$LOG_FILE" 2>&1

# Instalación de dependencias globales de npm
sudo npm install -g pm2 >> "$LOG_FILE" 2>&1

# Creación del directorio para la aplicación Node.js
mkdir ~/workspace
cd ~/workspace

# Contenido del archivo a crear para la aplicacion en node.js
NODE_APP_CONTENT=$(cat <<EOF
const http = require('http');

// Creación del servidor HTTP
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hola Mundo, ejecucion desde my_app clienWeb1!\n');
});

// Escucha en el puerto 3000
server.listen(3000, '127.0.0.1', () => {
  console.log('Servidor Node.js en ejecución en http://127.0.0.1:3000/');
});
EOF
)

# Ruta del archivo de la aplicación Node.js
NODE_APP_FILE="my_app.js"

# Verificar si el archivo ya existe
if [ -f "$NODE_APP_FILE" ]; then
    # Si existe, procedo a comparar el contenido
    if cmp -s "$NODE_APP_FILE" <(echo "$NODE_APP_CONTENT"); then
        echo "El archivo $NODE_APP_FILE ya existe y tiene el mismo contenido."
    else
        # Si no tiene el mismo contenido, se sobrescribe el archivo
        echo "$NODE_APP_CONTENT" > "$NODE_APP_FILE"
        echo "El archivo $NODE_APP_FILE ya existe pero se ha actualizado con el nuevo contenido."
    fi
else
    # Si no existe, se crea el archivo y agrego el contenido
    echo "$NODE_APP_CONTENT" > "$NODE_APP_FILE"
    echo "Se ha creado el archivo $NODE_APP_FILE."
fi

# Iniciar la aplicación Node.js con PM2 para que se ejecute en segundo plano
pm2 start my_app.js >> "$LOG_FILE"
pm2 save >> "$LOG_FILE"
pm2 startup systemd >> "$LOG_FILE"

# Guardar el entorno PM2
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u vagrant --hp /home/vagrant >> "$LOG_FILE"

# Informar al usuario
echo "La aplicación Node.js se ha configurado y se ha iniciado correctamente." >> "$LOG_FILE"

#2da parte para la configuración del cluster consul

# Descargar consul HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >> "$LOG_FILE" 2>&1
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >> "$LOG_FILE" 2>&1
sudo apt update && sudo apt install consul >> "$LOG_FILE" 2>&1

#Iniciar el consul
consul agent -data-dir=/tmp/consul -node=clientweb1 -bind=192.168.100.11 -join=192.168.100.10 &

#Crear el archivo con la instrucción en formato json para el registro del servicio
sudo mkdir /etc/consul
#!/bin/bash

# Contenido del archivo a crear JSON File para la configuracion del HAPROXY en consul
SERVICE_JSON_CONTENT=$(cat <<EOF
{
  "services": [
    {
      "Name": "my_app",
      "Tags": [
        "nodejs",
        "app"
      ],
      "Address": "192.168.100.11",
      "Port": 3000,
      "Check": {
        "HTTP": "http://192.168.100.11:3000",
        "Interval": "10s"
      }
    },
    {
      "Name": "index_page",
      "Tags": [
        "html",
        "static"
      ],
      "Address": "192.168.100.11",
      "Port": 80,
      "Check": {
        "HTTP": "http://192.168.100.11",
        "Interval": "10s"
      }
    }
  ]
}
EOF
)

# Ruta del archivo JSON del servicio
SERVICE_JSON_FILE="/etc/consul/clientWeb1-service.json"

# Verificar si el archivo ya existe
if [ -f "$SERVICE_JSON_FILE" ]; then
    # Si existe, procedo a comparar el contenido
    if cmp -s "$SERVICE_JSON_FILE" <(echo "$SERVICE_JSON_CONTENT"); then
        echo "El archivo $SERVICE_JSON_FILE ya existe y tiene el mismo contenido."
    else
        # Si no tiene el mismo contenido, se sobrescribe el archivo
        echo "$SERVICE_JSON_CONTENT" | sudo tee "$SERVICE_JSON_FILE" > /dev/null
        echo "El archivo $SERVICE_JSON_FILE ya existe pero se ha actualizado con el nuevo contenido."
    fi
else
    # Si no existe, se crea el archivo y agrego el contenido
    echo "$SERVICE_JSON_CONTENT" | sudo tee "$SERVICE_JSON_FILE" > /dev/null
    echo "Se ha creado el archivo $SERVICE_JSON_FILE."
fi

#Registrar el servicio de haproxy en consul
consul services register /etc/consul/clientWeb1-service.json >> "$LOG_FILE" 2>&1
