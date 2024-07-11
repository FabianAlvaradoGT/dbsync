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
LOCAL_PG_DB="$2"    # Nombre de la base de datos local

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
    eval "$comando" >/dev/null &
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
    docker exec -i $LOCAL_PG_CONTAINER psql -U $LOCAL_PG_USER -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = '$LOCAL_PG_DB';" >/dev/null
    docker exec -i $LOCAL_PG_CONTAINER psql -U $LOCAL_PG_USER -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$LOCAL_PG_DB';" >/dev/null
    docker exec -i $LOCAL_PG_CONTAINER dropdb -U $LOCAL_PG_USER $LOCAL_PG_DB >/dev/null
}

# Función para forzar la eliminación de la base de datos sin Docker
forzar_eliminacion_sin_docker() {
    psql -U $LOCAL_PG_USER -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = '$LOCAL_PG_DB';" >/dev/null
    psql -U $LOCAL_PG_USER -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$LOCAL_PG_DB';" >/dev/null
    dropdb -U $LOCAL_PG_USER $LOCAL_PG_DB >/dev/null
}

# Función para restaurar la base de datos en Docker
restaurar_en_docker() {
    ejecutar_comando "docker exec -e PGPASSWORD=$AZURE_PG_PASSWORD $LOCAL_PG_CONTAINER pg_dump -h $AZURE_PG_HOST -U $AZURE_PG_USER -d $AZURE_PG_DB > $BACKUP_FILE 2>/dev/null" "🎒 Iniciando el dump de la base de datos en Azure..."
    
    docker exec -i $LOCAL_PG_CONTAINER psql -U $LOCAL_PG_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$LOCAL_PG_DB'" | grep -q 1 && forzar_eliminacion_en_docker

    ejecutar_comando "docker exec -i $LOCAL_PG_CONTAINER createdb -U $LOCAL_PG_USER $LOCAL_PG_DB" "🛠️  Creando la base de datos local en Docker..."
    ejecutar_comando "cat $BACKUP_FILE | docker exec -i $LOCAL_PG_CONTAINER psql -U $LOCAL_PG_USER -d $LOCAL_PG_DB 2>&1" "♻️  Restaurando el dump en la base de datos local en Docker..."
}

# Función para restaurar la base de datos sin Docker
restaurar_sin_docker() {
    ejecutar_comando "PGPASSWORD=$AZURE_PG_PASSWORD pg_dump -h $AZURE_PG_HOST -U $AZURE_PG_USER -d $AZURE_PG_DB > $BACKUP_FILE 2>/dev/null" "🎒 Iniciando el dump de la base de datos en Azure..."
    
    psql -U $LOCAL_PG_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$LOCAL_PG_DB'" | grep -q 1 && forzar_eliminacion_sin_docker

    ejecutar_comando "createdb -U $LOCAL_PG_USER $LOCAL_PG_DB" "🛠️  Creando la base de datos local..."
    ejecutar_comando "PGPASSWORD=$LOCAL_PG_PASSWORD psql -U $LOCAL_PG_USER -d $LOCAL_PG_DB < $BACKUP_FILE 2>&1" "♻️  Restaurando el dump en la base de datos local..."
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
