#!/bin/bash

# Desactivar cursor en terminal
tput civis

# Cargar variables del archivo .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ Archivo .env no encontrado. Por favor, cree el archivo y agregue las variables requeridas."
    exit 1
fi

# Verifica que se proporcionen los argumentos necesarios
if [ "$#" -ne 2 ]; then
    echo -e "⚠️  Uso: $0 <docker/no-docker> <nombre_base_datos_local>"
    exit 1
fi

# Variables locales
USO_DOCKER="$1"     # Indicar si se usa Docker o no (docker/no-docker)
LOCAL_DB="$2"    # Nombre de la base de datos local

# Función para mostrar los puntos suspensivos en movimiento
mostrar_puntos_suspensivos() {
    local pid=$1
    local delay=0.5
    local spinstr='|/-\'
    echo -n " "
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Función para ejecutar un comando en segundo plano con puntos suspensivos
ejecutar_comando() {
    local comando=$1
    echo -e -n "$2"
    eval "$comando" &
    local pid=$!
    mostrar_puntos_suspensivos $pid
    wait $pid
    if [ $? -ne 0 ]; then
        echo -e "❌\n" >&2
        exit 1
    else
        echo -e "✅"
    fi
}

# Función para forzar la eliminación de la base de datos en Docker
forzar_eliminacion_en_docker() {
    ejecutar_comando "docker exec -i $SQLSERVER_LOCAL_CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $SQLSERVER_LOCAL_USER -P $SQLSERVER_PASSWORD -Q \"ALTER DATABASE [$SQLSERVER_LOCAL_DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$SQLSERVER_LOCAL_DB];\"" "🗑️  Eliminando la base de datos en Docker..."
}

# Función para forzar la eliminación de la base de datos sin Docker
forzar_eliminacion_sin_docker() {
    ejecutar_comando "/opt/mssql-tools/bin/sqlcmd -S $SQLSERVER_HOST -U $SQLSERVER_USER -P $SQLSERVER_PASSWORD -Q \"ALTER DATABASE [$SQLSERVER_LOCAL_DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$SQLSERVER_LOCAL_DB];\"" "🗑️  Eliminando la base de datos..."
}

# Función para restaurar la base de datos en Docker
restaurar_en_docker() {
    ejecutar_comando "docker exec -e SQLCMDPASSWORD=$SQLSERVER_PASSWORD $SQLSERVER_LOCAL_CONTAINER /opt/mssql-tools/bin/sqlcmd -S $SQLSERVER_HOST -U $SQLSERVER_USER -Q \"BACKUP DATABASE [$SQLSERVER_DB] TO DISK = N'$BACKUP_FILE' WITH NOFORMAT, NOINIT, NAME = N'$SQLSERVER_DB-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10\"" "🎒  Iniciando el backup de la base de datos en Azure..."
    
    # docker exec -i $SQLSERVER_LOCAL_CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $SQLSERVER_LOCAL_USER -P $SQLSERVER_PASSWORD -Q "SELECT 1 FROM sys.databases WHERE name = '$SQLSERVER_LOCAL_DB'" | grep -q 1 && forzar_eliminacion_en_docker

    # ejecutar_comando "docker exec -i $SQLSERVER_LOCAL_CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $SQLSERVER_LOCAL_USER -P $SQLSERVER_PASSWORD -Q \"RESTORE DATABASE [$SQLSERVER_LOCAL_DB] FROM DISK = N'$BACKUP_FILE' WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10;\"" "♻️  Restaurando el backup en la base de datos local en Docker..."
}

# Función para restaurar la base de datos sin Docker
restaurar_sin_docker() {
    ejecutar_comando "/opt/mssql-tools/bin/sqlcmd -S $SQLSERVER_HOST -U $SQLSERVER_USER -P $SQLSERVER_PASSWORD -Q \"BACKUP DATABASE [$SQLSERVER_DB] TO DISK = N'$BACKUP_FILE' WITH NOFORMAT, NOINIT, NAME = N'$SQLSERVER_DB-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10\"" "🎒  Iniciando el backup de la base de datos en Azure..."
    
    /opt/mssql-tools/bin/sqlcmd -S $SQLSERVER_HOST -U $SQLSERVER_USER -P $SQLSERVER_PASSWORD -Q "SELECT 1 FROM sys.databases WHERE name = '$SQLSERVER_LOCAL_DB'" | grep -q 1 && forzar_eliminacion_sin_docker

    ejecutar_comando "/opt/mssql-tools/bin/sqlcmd -S $SQLSERVER_HOST -U $SQLSERVER_USER -P $SQLSERVER_PASSWORD -Q \"RESTORE DATABASE [$SQLSERVER_LOCAL_DB] FROM DISK = N'$BACKUP_FILE' WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10;\"" "♻️  Restaurando el backup en la base de datos local..."
}

# Restaurar la base de datos según el método especificado
if [ "$USO_DOCKER" = "docker" ]; then
    restaurar_en_docker
elif [ "$USO_DOCKER" = "no-docker" ]; then
    restaurar_sin_docker
else
    echo -e "⚠️  Opción desconocida para uso de Docker: $USO_DOCKER. Use 'docker' o 'no-docker'."
    exit 1
fi

# Eliminar el archivo de respaldo local
ejecutar_comando "rm $BACKUP_FILE" "🗑️  Eliminando el archivo de respaldo local..."

echo -e "\n🎉 Copia de seguridad y restauración completadas con éxito 🎉"

# Activar cursor en terminal
tput cnorm
