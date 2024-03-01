#!/bin/bash
# Configuración script_clienteWeb1
# Edward Trejos
# Microproyecto - Cloud
# Este script de aprovisionamiento instala consul y crea el cluster
# dejando a la maquina del servidor como nodo principal
# 25/02/2024

# Ruta al archivo de log
LOG_FILE="/var/log/consul.log"

# Descargar consul HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >> "$LOG_FILE" 2>&1
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >> "$LOG_FILE" 2>&1
sudo apt update && sudo apt install consul >> "$LOG_FILE" 2>&1

#Iniciar el consul & es para que se ejecute en segundo plano
sudo consul agent -server -bootstrap-expect=1 -data-dir=/tmp/consul -node=proxyServer -bind=192.168.100.10 -ui -client=0.0.0.0 &

# Contenido del archivo a crear o agregar JSON File para la configuracion del HAPROXY en consul
CONTENT=$(cat <<EOF
{
  "service": {
    "name": "haproxy",
    "tags": [
      "web",
      "proxy"
    ],
    "address": "192.168.100.10",
    "port": 80,
    "checks": [
      {
        "http": "http://192.168.100.10:80",
        "interval": "10s"
      }
    ]
  }
}
EOF
)

# Ruta del archivo
JSON_FILE="/etc/haproxy/haproxy-service.json"

# Verifica si el archivo ya existe
if [ ! -f "$JSON_FILE" ]; then
    # Si no existe, crea el archivo y agrega el contenido
    echo "$CONTENT" | sudo tee "$JSON_FILE" >> "$LOG_FILE" 2>&1
else
    # Si existe, verifica si ya contiene el contenido
    if ! grep -qF "$CONTENT" "$JSON_FILE"; then
        # Si no está presente, agrega el contenido al archivo
        echo "$CONTENT" | sudo tee -a "$JSON_FILE" >> "$LOG_FILE" 2>&1
    fi
fi

#Registrar el servicio de haproxy en consul
consul services register /etc/haproxy/haproxy-service.json >> "$LOG_FILE" 2>&1