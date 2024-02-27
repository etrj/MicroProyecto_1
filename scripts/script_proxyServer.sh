#!/bin/bash
# Configuración script_clienteWeb1
# Edward Trejos
# Microproyecto - Cloud
# Este script aprovisiona el proxyServer con la implementación del Haproxy
# Configura el archivo haproxy.cfg con las entradas de backend y frontend
# Crea la pagina para la no disponibilidad del servicio y reinicia los servicios
# 25/02/2024

# Ruta al archivo de log
LOG_FILE="/var/log/provisioning.log"

# Cambiar permisos y propietario archivo log
sudo chmod u+w /var/log/provisioning.log
sudo chown vagrant /var/log/provisioning.log

# Actualizar y actualizar paquetes
sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
sudo apt install net-tools >> "$LOG_FILE" 2>&1


# Instalar haproxy en el servidor
sudo apt install -y haproxy >> "$LOG_FILE" 2>&1

# Comprobar si la instalación de haproxy fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: Failed to install HAProxy." >> "$LOG_FILE"
    exit 1
fi

# Habilitar el servicio haproxy
sudo systemctl enable haproxy >> "$LOG_FILE" 2>&1

# Ruta al archivo haproxy.cfg
HAPROXY_CONFIG_FILE="/etc/haproxy/haproxy.cfg"

# Configuración del archivo haproxy.cfg
HAPROXY_CONFIG="
# Backend para el tráfico del puerto 80
backend web-backend-80
    balance roundrobin
    stats enable
    stats auth admin:admin
    stats uri /haproxy?stats
    server clientWeb1 192.168.100.11:80 check
    server clientWeb2 192.168.100.12:80 check

# Backend para el tráfico del puerto 3000
backend web-backend-3000
    balance roundrobin
    stats enable
    stats auth admin:admin
    stats uri /haproxy?stats
    server clientWeb1 192.168.100.11:3000 check
    server clientWeb2 192.168.100.12:3000 check

# Frontend para el tráfico del puerto 80
frontend http-80
    bind *:80
    default_backend web-backend-80

# Frontend para el tráfico del puerto 3000
frontend http-3000
    bind *:3000
    default_backend web-backend-3000
"

# Agregar las líneas al final del archivo haproxy.cfg
echo "$HAPROXY_CONFIG" | sudo tee -a "$HAPROXY_CONFIG_FILE" >> "$LOG_FILE" 2>&1

# Verificar la sintaxis de haproxy.cfg
sudo haproxy -c -f "$HAPROXY_CONFIG_FILE" >> "$LOG_FILE" 2>&1

# Comprobar si la sintaxis es correcta
if [ $? -ne 0 ]; then
    echo "Error: HAProxy configuration syntax is invalid." >> "$LOG_FILE"
    exit 1
fi

# Crear el archivo de disculpas por la indisponibilidad del servidor    
cat <<EOF | sudo tee /etc/haproxy/errors/503.http >> "$LOG_FILE" 2>&1
HTTP/1.0 503 Service Unavailable
Content-Type: text/html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Disculpas por la Indisponibilidad del Servidor</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #d9534f;
        }
        p {
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Disculpas por la Indisponibilidad del Servidor</h1>
        <p>Lamentamos informarte que el servidor está temporalmente fuera de servicio. Estamos trabajando para solucionar el problema lo antes posible.</p>
        <p>Por favor, inténtalo de nuevo más tarde.</p>
    </div>
</body>
</html>
EOF

# Reiniciar el servicio haproxy para aplicar los cambios
sudo systemctl restart haproxy >> "$LOG_FILE" 2>&1

# Comprobar si el reinicio del servicio fue exitoso
if [ $? -ne 0 ]; then
    echo "Error: Failed to restart HAProxy service." >> "$LOG_FILE"
    exit 1
fi

sudo ps aux | grep haproxy >> "$LOG_FILE"
echo "HAProxy has been configured successfully." >> "$LOG_FILE"