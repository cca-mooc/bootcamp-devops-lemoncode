# 💾 Crear máquina virtual Ubuntu para la base de datos (PostgreSQL)

Esta es una versión alternativa que utiliza **Ubuntu** con **PostgreSQL** en lugar de Windows con SQL Server. Es una opción más económica y sencilla de configurar.

## 📋 Variables de entorno necesarias

```bash
# 🐘 PostgreSQL VM en Azure (Ubuntu)
DB_VM_NAME="db-vm"
DB_VM_IMAGE="Ubuntu2204"
DB_VM_ADMIN_USERNAME="dbadmin"
DB_VM_NSG_NAME="db-vm-nsg"
VM_SIZE="Standard_DS1_v2"

# 🔐 Credenciales de PostgreSQL (las usaremos dentro de la VM)
POSTGRES_USER="heroesadmin"
POSTGRES_PASSWORD="Heroes@2024#"
POSTGRES_DB="heroes_db"
```

o si estás en Windows:

```pwsh
# 🐘 PostgreSQL VM en Azure (Ubuntu)
$DB_VM_NAME="db-vm"
$DB_VM_IMAGE="Ubuntu2204"
$DB_VM_ADMIN_USERNAME="dbadmin"
$DB_VM_NSG_NAME="db-vm-nsg"
$VM_SIZE="Standard_B2as_v2"

# 🔐 Credenciales de PostgreSQL (las usaremos dentro de la VM)
$POSTGRES_USER="heroesadmin"
$POSTGRES_PASSWORD="Heroes@2024#"
$POSTGRES_DB="heroes_db"
```

## 🖥️ Crear la máquina virtual

```bash
echo -e "🖥️ Creando máquina virtual Ubuntu para base de datos $DB_VM_NAME"

az vm create \
--resource-group $RESOURCE_GROUP \
--name $DB_VM_NAME \
--image $DB_VM_IMAGE \
--admin-username $DB_VM_ADMIN_USERNAME \
--generate-ssh-keys \
--vnet-name $VNET_NAME \
--subnet $DB_SUBNET_NAME \
--size $VM_SIZE \
--nsg $DB_VM_NSG_NAME 

echo -e "✅ Máquina virtual creada"
```

o si estás en Windows:

```pwsh
echo "🖥️ Creando máquina virtual Ubuntu para base de datos $DB_VM_NAME"

az vm create `
--resource-group $RESOURCE_GROUP `
--name $DB_VM_NAME `
--image $DB_VM_IMAGE `
--admin-username $DB_VM_ADMIN_USERNAME `
--generate-ssh-keys `
--vnet-name $VNET_NAME `
--subnet $DB_SUBNET_NAME `
--size $VM_SIZE `
--nsg $DB_VM_NSG_NAME `
--public-ip-address ""

echo "✅ Máquina virtual creada"
```

> 💡 **Nota**: Usamos `--generate-ssh-keys` para crear automáticamente las claves SSH. Si ya tienes una clave SSH, puedes usar `--ssh-key-values ~/.ssh/id_rsa.pub` en su lugar.

Para poder simplificar las cosas un poco, hemos permitido que el comando le asigne una IP pública, pero en un entorno de producción no es recomendable. Más adelante veremos cómo eliminarla.

## 🔒 Crear reglas de seguridad de red

### Regla para PostgreSQL (puerto 5432)

Para poder acceder a PostgreSQL desde la API:

```bash
echo -e "🔒 Creando regla de seguridad para PostgreSQL puerto 5432"

az network nsg rule create \
--resource-group $RESOURCE_GROUP \
--nsg-name $DB_VM_NSG_NAME \
--name AllowPostgreSQL \
--priority 1001 \
--destination-port-ranges 5432 \
--protocol Tcp \
--source-address-prefixes "*" \
--direction Inbound

echo -e "✅ Regla de seguridad creada"
```

o si estás en Windows:

```pwsh
echo "🔒 Creando regla de seguridad para PostgreSQL puerto 5432"

az network nsg rule create `
--resource-group $RESOURCE_GROUP `
--nsg-name $DB_VM_NSG_NAME `
--name AllowPostgreSQL `
--priority 1001 `
--destination-port-ranges 5432 `
--protocol Tcp `
--source-address-prefixes $API_SUBNET_ADDRESS_PREFIX `
--direction Inbound

echo "✅ Regla de seguridad creada"
```

### Regla para SSH (solo para configuración inicial)

Para conectarnos por SSH y configurar PostgreSQL, necesitamos habilitar temporalmente el acceso SSH:

```bash
echo -e "🔒 Creando regla de seguridad para SSH"

MY_HOME=$(curl -s ifconfig.me)/32  # 🌍 Obtiene tu IP pública

az network nsg rule create \
--resource-group $RESOURCE_GROUP \
--nsg-name $DB_VM_NSG_NAME \
--name AllowSSHFromHome \
--priority 1002 \
--destination-port-ranges 22 \
--protocol Tcp \
--source-address-prefixes $MY_HOME \
--direction Inbound

echo -e "✅ Regla SSH creada"
```

o si estás en Windows:

```pwsh
echo "🔒 Creando regla de seguridad para SSH"

$MY_HOME = (Invoke-RestMethod -Uri "https://ifconfig.me") + "/32"

az network nsg rule create `
--resource-group $RESOURCE_GROUP `
--nsg-name $DB_VM_NSG_NAME `
--name AllowSSHFromHome `
--priority 1002 `
--destination-port-ranges 22 `
--protocol Tcp `
--source-address-prefixes $MY_HOME `
--direction Inbound

echo "✅ Regla SSH creada"
```

## 🌐 Obtener la IP pública 

Para conectarnos a la VM por SSH, necesitamos su IP pública:

```bash
DB_PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP --name ${DB_VM_NAME}PublicIP --query "ipAddress" -o tsv)

echo "✅ IP pública temporal: $DB_PUBLIC_IP"
```

## 🔌 Conectarse por SSH e instalar PostgreSQL

Conéctate a la VM por SSH:

```bash
ssh $DB_VM_ADMIN_USERNAME@$DB_PUBLIC_IP
```

Una vez dentro de la VM, ejecuta los siguientes comandos para instalar y configurar PostgreSQL:

### 1️⃣ Instalar PostgreSQL

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Verificar que PostgreSQL está corriendo
sudo systemctl status postgresql
```

### 2️⃣ Configurar PostgreSQL para aceptar conexiones remotas

```bash
# Cambiar al usuario postgres
sudo -i -u postgres

# Crear usuario y base de datos
psql -c "CREATE USER heroesadmin WITH PASSWORD 'Heroes@2024#';"
psql -c "CREATE DATABASE heroes OWNER heroesadmin;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE heroes TO heroesadmin;"

# Salir del usuario postgres
exit
```

### 3️⃣ Configurar PostgreSQL para escuchar en todas las interfaces

```bash
# Editar postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Busca la línea `#listen_addresses = 'localhost'` y cámbiala por:

```
listen_addresses = '*'
```

> 💡 **Tip**: En nano, usa `Ctrl+W` para buscar y `Ctrl+O` para guardar, `Ctrl+X` para salir.

### 4️⃣ Configurar autenticación para conexiones remotas

```bash
# Editar pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Añade la siguiente línea al final del archivo para permitir conexiones desde la subred de la API (o desde cualquier IP con `0.0.0.0/0` para pruebas):

```
# Permitir conexiones desde la subred de la API
host    all             all             10.0.2.0/24            scram-sha-256

# O para permitir desde cualquier IP (menos seguro, solo para pruebas)
# host    all             all             0.0.0.0/0              scram-sha-256
```

### 5️⃣ Reiniciar PostgreSQL y verificar

```bash
# Reiniciar PostgreSQL para aplicar los cambios
sudo systemctl restart postgresql

# Verificar que PostgreSQL está escuchando en el puerto 5432
sudo ss -tlnp | grep 5432
```

Deberías ver algo como:
```
LISTEN 0      244          0.0.0.0:5432       0.0.0.0:*    users:(("postgres",pid=xxxx,fd=x))
```

### 6️⃣ Configurar el firewall de Ubuntu (UFW)

```bash
# Habilitar el firewall si no está activo
sudo ufw enable

# Permitir SSH
sudo ufw allow 22/tcp

# Permitir PostgreSQL
sudo ufw allow 5432/tcp

# Verificar las reglas
sudo ufw status
```

### 7️⃣ Salir de la VM

```bash
exit
```

## 🧹 Cómo probar desde fuera con la extensión de VS Code para postgres

Abre VS Code y usa la extensión [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres) para conectarte a tu base de datos PostgreSQL usando la IP pública temporal, el usuario y la contraseña que configuraste.

## 🔗 Obtener la IP privada de la base de datos

```bash
DB_PRIVATE_IP=$(az vm show \
--resource-group $RESOURCE_GROUP \
--name $DB_VM_NAME \
--show-details \
--query "privateIps" -o tsv)

echo -e "🔗 IP privada de la base de datos: $DB_PRIVATE_IP"
```

o si estás en Windows:

```pwsh
$DB_PRIVATE_IP = az vm show `
--resource-group $RESOURCE_GROUP `
--name $DB_VM_NAME `
--show-details `
--query "privateIps" -o tsv

echo "🔗 IP privada de la base de datos: $DB_PRIVATE_IP"
```

## 🔗 Cadena de conexión para la API

La cadena de conexión para PostgreSQL desde tu API sería:

```
Host=$DB_PRIVATE_IP;Port=5432;Database=heroes_db;Username=heroesadmin;Password=Heroes@2024#
```

O en formato URI:

```
postgresql://heroesadmin:Heroes@2024#@$DB_PRIVATE_IP:5432/heroes_db
```

## 🆚 Alternativa: Usar cloud-init para automatizar la instalación

Si quieres automatizar toda la instalación de PostgreSQL, puedes usar **cloud-init**. Crea un archivo `cloud-init-postgres.yaml`:

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - postgresql
  - postgresql-contrib

write_files:
  - path: /tmp/setup-postgres.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      # Esperar a que PostgreSQL esté listo
      sleep 10
      
      # Crear usuario y base de datos
      sudo -u postgres psql -c "CREATE USER heroesadmin WITH PASSWORD 'Heroes@2024#';"
      sudo -u postgres psql -c "CREATE DATABASE heroes_db OWNER heroesadmin;"
      sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE heroes_db TO heroesadmin;"
      
      # Configurar para escuchar en todas las interfaces
      sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/14/main/postgresql.conf
      
      # Permitir conexiones remotas
      echo "host    all             all             10.0.2.0/24            scram-sha-256" | sudo tee -a /etc/postgresql/14/main/pg_hba.conf
      
      # Reiniciar PostgreSQL
      sudo systemctl restart postgresql

runcmd:
  - /tmp/setup-postgres.sh
```

Y luego crear la VM con:

```bash
az vm create \
--resource-group $RESOURCE_GROUP \
--name $DB_VM_NAME \
--image $DB_VM_IMAGE \
--admin-username $DB_VM_ADMIN_USERNAME \
--generate-ssh-keys \
--vnet-name $VNET_NAME \
--subnet $DB_SUBNET_NAME \
--size $VM_SIZE \
--nsg $DB_VM_NSG_NAME \
--public-ip-address "" \
--custom-data cloud-init-postgres.yaml
```

---

## 📊 Resumen de la arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Virtual Network                       │
│                                                          │
│  ┌────────────────────┐    ┌────────────────────┐       │
│  │   API Subnet       │    │   DB Subnet        │       │
│  │   10.0.2.0/24     │    │   10.0.1.0/24      │       │
│  │                    │    │                    │       │
│  │  ┌──────────────┐ │    │  ┌──────────────┐  │       │
│  │  │   API VM     │ │───▶│  │   DB VM      │  │       │
│  │  │              │ │    │  │   Ubuntu     │  │       │
│  │  └──────────────┘ │    │  │   PostgreSQL │  │       │
│  │                    │    │  │   :5432      │  │       │
│  └────────────────────┘    │  └──────────────┘  │       │
│                            │   (Sin IP pública) │       │
│                            └────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

---

Ahora que ya tienes la base de datos creada con PostgreSQL, necesitamos una API que interactúe con ella. Puedes continuar en el siguiente [paso](../02-api-vm/README.md) 🚀.

> ⚠️ **Nota**: Si tu API estaba configurada para SQL Server, necesitarás adaptarla para usar PostgreSQL. El driver y la cadena de conexión serán diferentes.
