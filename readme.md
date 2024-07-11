# 🔄 DBSync

## 📕 Descripción

El script `DBSync` es una herramienta de automatización para respaldar y restaurar bases de datos de PostgreSQL y SQL Server, tanto en entornos Docker como no Docker. Este script facilita la replicación de bases de datos desde un servidor en la nube a un servidor local, manejando automáticamente la eliminación y creación de bases de datos, así como la restauración de los datos.

## 🚀 Demo

https://github.com/FabianAlvaradoGT/dbsync/assets/150682805/73c7d29f-9625-4a65-a90e-3efb71272988

## 📝 Requisitos

Antes de ejecutar el script, asegúrate de tener lo siguiente instalado y configurado:

### PostgreSQL

1. **PostgreSQL**:
   - `pg_dump`: Utilidad de línea de comandos para respaldar bases de datos PostgreSQL.
   - `psql`: Utilidad de línea de comandos para ejecutar comandos SQL en PostgreSQL.

### SQL Server

1. **SQL Server Tools**:
   - `sqlcmd`: Una utilidad de línea de comandos para ejecutar comandos T-SQL y scripts SQL.
   - `bcp`: Utilidad de copia masiva para importar/exportar datos.

### Docker

- **Docker** (si planeas usar el modo Docker): Un contenedor de PostgreSQL o SQL Server en ejecución.

### Acceso a la base de datos en la nube

- **Acceso a Azure SQL Server o PostgreSQL**: Credenciales de acceso y permisos necesarios para realizar operaciones de respaldo.

## 👨🏻‍💻 Instalación

### Instalación de PostgreSQL Tools en Linux

```sh
sudo apt-get update
sudo apt-get install postgresql-client
```

### Instalación de SQL Server Tools en Linux

```sh
curl -o- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl -o- https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Instalación de Docker

Sigue las instrucciones de instalación en la página [oficial de Docker](https://docs.docker.com/engine/install/).

## 🏃🏻‍♂️ Uso

### Ejecución del script

1. Clona el repositorio o descarga el script DBSync-\*.sh en tu máquina local.
2. Haz el script ejecutable:

```sh
chmod +x DBSync-*.sh # DBSync-Postgres.sh o DBSync-SQLServer.sh
```

3. Ejecuta el script proporcionando los argumentos necesarios:

```sh
./DBSync-*.sh <docker/no-docker> <nombre_base_datos_local>
```

### Argumentos

- **<docker/no-docker>**: Especifica si la operación se realiza en un entorno Docker (docker) o no (no-docker).
- **<nombre_base_datos_local>**: Nombre de la base de datos local donde se restaurarán los datos.

## 🧪 Ejemplo de Uso

### Sin Docker

```sh
./DBSync-*.sh no-docker my_local_db
```

### Con Docker

```sh
./DBSync-*.sh docker my_local_db
```

## 🛠️ Configuración

### Variables de conexión

Edita el script DBSync.sh para configurar las variables de conexión a tu servidor SQL Server en Azure y el contenedor Docker si es necesario:

```sh
# Variables compartidas
BACKUP_FILE="backup.bak"       # Nombre del archivo de respaldo

# Variables Postgres
POSTGRES_HOST="your_sql_server_host"
POSTGRES_DB="your_database"
POSTGRES_USER="your_username"
POSTGRES_PASSWORD="your_password"
POSTGRES_LOCAL_USER="postgres"
POSTGRES_LOCAL_CONTAINER="postgres"

# Variables SQL Server
SQLSERVER_HOST="your_sql_server_host"
SQLSERVER_DB="your_database"
SQLSERVER_USER="your_username"
SQLSERVER_PASSWORD="your_password"
SQLSERVER_LOCAL_USER="sa"
SQLSERVER_LOCAL_CONTAINER="sqlserver"
```

## ❗ Detalles Importantes

- Seguridad: Asegúrate de que las credenciales y contraseñas no estén expuestas en el script si compartes el código.
- Permisos: El usuario utilizado debe tener los permisos necesarios para realizar operaciones de respaldo y restauración.
- Dependencias: Verifica que todas las herramientas y utilidades necesarias estén instaladas y accesibles en tu entorno.
