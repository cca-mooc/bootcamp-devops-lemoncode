# 💾 Crear máquina virtual para la base de datos

Ahora vamos a crear la máquina virtual para la base de datos. Para ello, vamos a necesitar las siguientes variables de entorno:

```bash
# 🗄️ SQL Server VM en Azure
DB_VM_NAME="db-vm"
DB_VM_IMAGE="MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2:16.0.230613"
DB_VM_ADMIN_USERNAME="dbadmin"
DB_VM_ADMIN_PASSWORD="Db@dmin123#-"
DB_VM_NSG_NAME="db-vm-nsg"
VM_SIZE="Standard_B2as_v2"
```

o si estás en Windows:

```pwsh
# 🗄️ SQL Server VM en Azure
$DB_VM_NAME="db-vm"
$DB_VM_IMAGE="MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2:16.0.230613"
$DB_VM_ADMIN_USERNAME="dbadmin"
$DB_VM_ADMIN_PASSWORD="Db@dmin123#-"
$DB_VM_NSG_NAME="db-vm-nsg"
$VM_SIZE="Standard_B2s_v2"
```

```bash
echo -e "🖥️ Creando máquina virtual de base de datos $DB_VM_NAME"

az vm create \
--resource-group $RESOURCE_GROUP \
--name $DB_VM_NAME \
--image $DB_VM_IMAGE \
--admin-username $DB_VM_ADMIN_USERNAME \
--admin-password $DB_VM_ADMIN_PASSWORD \
--vnet-name $VNET_NAME \
--subnet $DB_SUBNET_NAME \
--size $VM_SIZE \
--nsg $DB_VM_NSG_NAME
```

o si estás en Windows:

```pwsh
echo -e "🖥️ Creando máquina virtual de base de datos $DB_VM_NAME"

az vm create `
--resource-group $RESOURCE_GROUP `
--name $DB_VM_NAME `
--image $DB_VM_IMAGE `
--admin-username $DB_VM_ADMIN_USERNAME `
--admin-password $DB_VM_ADMIN_PASSWORD `
--vnet-name $VNET_NAME `
--subnet $DB_SUBNET_NAME `
--public-ip-address "" `
--size $VM_SIZE `
--nsg $DB_VM_NSG_NAME 
```

Esta no necesita tener acceso desde fuera de la red virtual en la que se encuentra, por lo que no le asignamos una IP pública. Por otro lado, le hemos añadido un network security group (a través del parámetro --nsg), el cual es un conjunto de reglas que permiten o deniegan el tráfico de red entrante o saliente de los recursos de Azure.

## ⚙️ Crear la extensión de SQL Server para la máquina virtual de la base de datos

Si estás trabajando con SQL Server en máquinas virtuales en Azure puedes usar la extensión de SQL Server gestionar esa máquina virtual con un sabor de base de datos. Para ello, ejecuta el siguiente comando:


```bash
echo -e "⚙️ Añadiendo extensión de SQL Server a la VM de base de datos"
az sql vm create \
--name $DB_VM_NAME \
--license-type payg \
--resource-group $RESOURCE_GROUP \
--sql-mgmt-type Lightweight \
--connectivity-type PRIVATE \
--port 1433 \
--sql-auth-update-username $DB_VM_ADMIN_USERNAME \
--sql-auth-update-pwd $DB_VM_ADMIN_PASSWORD

echo -e "✅ Extensión de base de datos creada"
```

o si estás en Windows:

```pwsh
echo -e "⚙️ Añadiendo extensión de SQL Server a la VM de base
az sql vm create `
--name $DB_VM_NAME `
--license-type payg `
--resource-group $RESOURCE_GROUP `
--sql-mgmt-type Lightweight `
--connectivity-type PRIVATE `
--port 1433 `
--sql-auth-update-username $DB_VM_ADMIN_USERNAME `
--sql-auth-update-pwd $DB_VM_ADMIN_PASSWORD
```

En algunas regiones, como Belgium Central, no está disponible la creación de esta extensión por lo que necesitamos configurar SQL Server manualmente.

## 🔒 Crear una regla de seguridad de red para SQL Server

Para poder acceder a SQL Server desde la API, vamos a crear una regla de seguridad de red para SQL Server. Para ello, ejecuta el siguiente comando:

```bash
echo -e "🔒 Creando regla de seguridad para SQL Server puerto 1433"

az network nsg rule create \
--resource-group $RESOURCE_GROUP \
--nsg-name $DB_VM_NSG_NAME \
--name AllowSQLServer \
--priority 1001 \
--destination-port-ranges 1433 \
--protocol Tcp \
--source-address-prefixes "*" \
--direction Inbound
```

o si estás en Windows:

```pwsh
echo -e "🔒 Creando regla de seguridad para SQL Server puerto 1433"

az network nsg rule create `
--resource-group $RESOURCE_GROUP `
--nsg-name $DB_VM_NSG_NAME `
--name AllowSQLServer `
--priority 1001 `
--destination-port-ranges 1433 `
--protocol Tcp `
--source-address-prefixes $API_SUBNET_ADDRESS_PREFIX `
--direction Inbound
```

Esto lo que significa es que vamos a permitir el tráfico desde la subred de la API a la máquina virtual de la base de datos en el puerto 1433. Si se intenta acceder desde otra subred, no te va a dejar.

Regla para poder conectarme desde casa por RDP:

```bash
MY_HOME=$(curl ifconfig.me)/32  # 🌍 Obtiene tu IP pública y la usa como prefijo


az network nsg rule create \
--resource-group $RESOURCE_GROUP \
--nsg-name $DB_VM_NSG_NAME \
--name AllowRDPFromHome \
--priority 1002 \
--destination-port-ranges 3389 \
--protocol Tcp \
--source-address-prefixes $MY_HOME \
--direction Inbound
```

Ahora que ya tenemos la regla creada, accede al portal de Azure, busca el grupo de recursos que hemos creado y selecciona la máquina virtual de la base de datos. 

En la propia sección de Overview puedes hacer clic en "Connect" y seleccionar RDP para descargar el fichero de conexión. Ábrelo e introduce las credenciales que hemos definido en las variables de entorno (DB_VM_ADMIN_USERNAME y DB_VM_ADMIN_PASSWORD).

![alt text](/04-cloud/azure/iaas/images/connect-db.png)

Con ello podrás ver que puedes acceder a la máquina virtual de la base de datos a través de RDP. Ahora, para nuestro entorno, necesitamos configurar el Firewall de windows para permitir conexiones entrantes en el puerto 1433 (SQL Server). Para ello, abre una terminal de PowerShell como administrador y ejecuta el siguiente comando:


Quedando la foto de la siguiente manera:

![VM para la base de datos](/04-cloud/azure/iaas/images/db-vm.png)

Ahora que ya tenemos la base de datos creada, necesitamos una API que interactúe con ella. Puedes continuar en el siguiente [paso](../02-api-vm/README.md) 🚀.