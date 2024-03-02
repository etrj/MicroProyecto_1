#!/bin/bash
# Configuración script_clienteWeb1
#
# Alexander Rodriguez
# Luis Mantilla
# Edward Trejos
#
# Microproyecto - Cloud
# 25/02/2024
# Este script de aprovisionamiento instala el servicio de apache2
# Tambien crea una pagina denominada index.html con el nombre del servidor.
# 01/03/2024
# Se actualizan el script para mejorar el comportamiento y validacion de archivos
# para su creación.

# Ruta al archivo de registro
LOG_FILE="/var/log/script_clienteWeb1.log"

# Función para registrar mensajes en el archivo de registro
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Actualizar e instalar paquetes
log_message "Actualizando e instalando paquetes..."
sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1

# Verificar si la actualización e instalación de paquetes fue exitosa
if [ $? -ne 0 ]; then
    log_message "Error: Actualización e instalación de paquetes fallida. Revisar el archivo de registro." 
    exit 1
fi

log_message "Instalando Apache en el servidor..."
# Instalar Apache en el servidor
sudo apt install apache2 -y >> "$LOG_FILE" 2>&1

# Verificar si la instalación de Apache fue exitosa
if [ $? -ne 0 ]; then
    log_message "Error: Instalación de Apache fallida. Revisar el archivo de registro." 
    exit 1
fi

log_message "Habilitando el servicio Apache..."
# Habilitar el servicio Apache
sudo systemctl enable apache2 >> "$LOG_FILE" 2>&1

# Verificar si la habilitación del servicio Apache fue exitosa
if [ $? -ne 0 ]; then
    log_message "Error: Habilitación del servicio Apache fallida. Revisar el archivo de registro."
    exit 1
fi

log_message "Creando el archivo HTML de prueba de balanceo de carga..."

# Crear el archivo HTML de prueba de balanceo de carga
DOCUMENT_ROOT="/var/www/html"
INDEX_FILE="$DOCUMENT_ROOT/index.html"

# Verificar si el archivo index.html ya existe
if [ ! -f "$INDEX_FILE" ]; then
    # Contenido del archivo index.html
    HTML_CONTENT='
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Prueba de Balanceo de Carga - clienteWeb1</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                text-align: center;
                padding-top: 50px;
            }
            h1 {
                color: #333;
            }
            p {
                color: #666;
            }
        </style>
    </head>
    <body>
        <h1>Prueba de Balanceo de Carga</h1>
        <p>Esta página fue generada por el servidor: <strong>clienteWeb1</strong></p>
    </body>
    </html>
    '
    # Crear el archivo index.html
    echo "$HTML_CONTENT" | sudo tee "$INDEX_FILE" > /dev/null
    log_message "Archivo index.html creado en $DOCUMENT_ROOT"
else
    log_message "El archivo index.html ya existe en $DOCUMENT_ROOT"
fi

log_message "Reiniciando el servidor web Apache..."
# Reiniciar el servidor web para aplicar los cambios
sudo systemctl restart apache2 >> "$LOG_FILE" 2>&1

# Verificar si el reinicio del servidor web Apache fue exitoso
if [ $? -ne 0 ]; then
    log_message "Error: Reinicio del servidor web Apache fallido. Revisar el archivo de registro." 
    exit 1
fi

# Verificar que el puerto 80 este en ejecución
sudo netstat -tuln | grep :80 >> "$LOG_FILE"
log_message "Configuración completada con éxito."