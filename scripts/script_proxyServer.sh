#!/bin/bash
# Configuración script_proxyServer
#
# Alexander Rodriguez
# Luis Mantilla
# Edward Trejos
#
# Microproyecto - Cloud
# 25/02/2024
# Este script de aprovisionamiento instala el servicio de haproxy y actualiza el S.O.
# Tambien realiza la configuración en haproxy y la pagina 503 de errores
# Para la no disponibilidad del sistema.
# 01/03/2024
# Se actualizan el script para mejorar el comportamiento y validacion de archivos
# para su creación.

# Ruta al archivo de log
LOG_FILE="/var/log/provisioning.log"

# Función para registrar mensajes en el archivo de registro
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Cambiar permisos y propietario del archivo log
sudo chmod u+w /var/log/provisioning.log
sudo chown vagrant /var/log/provisioning.log

# Actualizar y actualizar paquetes
sudo apt update && sudo apt upgrade -y
log_message "Actualización de paquetes realizada"

sudo apt install net-tools
log_message "Instalación de net-tools realizada"

# Instalar haproxy en el servidor
sudo apt install -y haproxy

# Comprobar si la instalación de haproxy fue exitosa
if [ $? -ne 0 ]; then
    log_message "Error: Failed to install HAProxy."
    exit 1
fi

# Habilitar el servicio haproxy
sudo systemctl enable haproxy
log_message "Habilitación del servicio HAProxy realizada"

# Variable para el archivo de configuración de HAProxy
HAPROXY_CONFIG_FILE="/etc/haproxy/haproxy.cfg"

# Configuración adicional de HAProxy
ADDITIONAL_CONFIG="
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

# Procedimiento para verificar si el archivo ya ha sido actualizado
# Esto ayuda a evitar doble configuración en el archivo
if [ ! -f "$HAPROXY_CONFIG_FILE" ]; then
    log_message "Error: El archivo $HAPROXY_CONFIG_FILE no existe."
    exit 1
fi

# Verificar si el contenido adicional ya ha sido añadido al archivo haproxy.cfg
if grep -q "CONFIG_ADDED" "$HAPROXY_CONFIG_FILE"; then
    log_message "Configuración adicional ya ha sido añadida. No se realizarán cambios."
    exit 0
fi

# Cuando el archivo no tiene la configuración, se añade
echo "$ADDITIONAL_CONFIG" | sudo tee -a "$HAPROXY_CONFIG_FILE" >> "$LOG_FILE" 2>&1
log_message "Configuración adicional de HAProxy realizada"

# Adicionar la marca de que el archivo ya está actualizado
sudo bash -c "echo '# CONFIG_ADDED' >> $HAPROXY_CONFIG_FILE"

# Verificar la sintaxis de haproxy.cfg que no tenga errores en la configuración
sudo haproxy -c -f "$HAPROXY_CONFIG_FILE" >> "$LOG_FILE" 2>&1

# Comprobar si la sintaxis es correcta
if [ $? -ne 0 ]; then
    log_message "Error: HAProxy configuration syntax is invalid."
    exit 1
fi

# Contenido personalizado del archivo 503.http pagina de indisponibilidad del sistema
CUSTOM_503_CONTENT=$(cat <<EOF
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
)

# Ruta del archivo 503.http de la configuración haproxy
ERROR_503_FILE="/etc/haproxy/errors/503.http"

# Verificar si el contenido de indisponibilidad ya está presente en el archivo 503.http
if ! grep -qF "$CUSTOM_503_CONTENT" "$ERROR_503_FILE"; then
    # Si no está presente, sobrescribe el contenido del archivo custom en 503.http
    echo "$CUSTOM_503_CONTENT" | sudo tee "$ERROR_503_FILE" >> "$LOG_FILE" 2>&1
fi

# Reiniciar el servicio haproxy para aplicar los cambios
sudo systemctl restart haproxy >> "$LOG_FILE" 2>&1

# Comprobar si el reinicio del servicio fue exitoso
if [ $? -ne 0 ]; then
    log_message "Error: Failed to restart HAProxy service."
    exit 1
fi

sudo ps aux | grep haproxy >> "$LOG_FILE"
log_message "HAProxy ha sido configurado exitosamente."

log_message "Aprovisionamiento completado exitosamente."

exit 0