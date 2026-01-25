#!/bin/bash
# =============================================================================
# 🐘 Script de instalación y configuración de PostgreSQL
# =============================================================================
# Este script automatiza la instalación de PostgreSQL en Ubuntu y lo configura
# para aceptar conexiones remotas desde la subred de la API.
#
# Uso: sudo ./setup-postgresql.sh
# =============================================================================

set -e  # Salir si hay errores

# 🔐 Configuración de PostgreSQL
POSTGRES_USER="heroesadmin"
POSTGRES_PASSWORD="Heroes@2024#"
POSTGRES_DB="heroes"
API_SUBNET="10.0.2.0/24"

echo "=============================================="
echo "🐘 Instalación y configuración de PostgreSQL"
echo "=============================================="

# 1️⃣ Actualizar el sistema e instalar PostgreSQL
echo ""
echo "1️⃣ Actualizando el sistema e instalando PostgreSQL..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql postgresql-contrib

# Verificar que PostgreSQL está corriendo
echo "✅ Verificando que PostgreSQL está corriendo..."
sudo systemctl status postgresql --no-pager

# 2️⃣ Crear usuario y base de datos
echo ""
echo "2️⃣ Creando usuario y base de datos..."
sudo -u postgres psql -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;"
echo "✅ Usuario y base de datos creados"

# 3️⃣ Configurar PostgreSQL para escuchar en todas las interfaces
echo ""
echo "3️⃣ Configurando PostgreSQL para escuchar en todas las interfaces..."

# Detectar versión de PostgreSQL
PG_VERSION=$(ls /etc/postgresql/)
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

echo "   Versión de PostgreSQL detectada: $PG_VERSION"

# Modificar listen_addresses
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF
echo "✅ listen_addresses configurado a '*'"

# 4️⃣ Configurar autenticación para conexiones remotas
echo ""
echo "4️⃣ Configurando autenticación para conexiones remotas..."

# Añadir regla para la subred de la API
echo "# Permitir conexiones desde la subred de la API" | sudo tee -a $PG_HBA
echo "host    all             all             $API_SUBNET            scram-sha-256" | sudo tee -a $PG_HBA
echo "✅ Regla de autenticación añadida para $API_SUBNET"

# 5️⃣ Reiniciar PostgreSQL
echo ""
echo "5️⃣ Reiniciando PostgreSQL..."
sudo systemctl restart postgresql

# Verificar que PostgreSQL está escuchando en el puerto 5432
echo "✅ Verificando que PostgreSQL está escuchando en el puerto 5432..."
sudo ss -tlnp | grep 5432

# 6️⃣ Configurar el firewall de Ubuntu (UFW)
echo ""
echo "6️⃣ Configurando el firewall (UFW)..."

# Habilitar el firewall si no está activo
sudo ufw --force enable

# Permitir SSH
sudo ufw allow 22/tcp

# Permitir PostgreSQL
sudo ufw allow 5432/tcp

# Verificar las reglas
echo "✅ Reglas del firewall:"
sudo ufw status

echo ""
echo "=============================================="
echo "✅ ¡Instalación completada!"
echo "=============================================="
echo ""
echo "📋 Resumen de la configuración:"
echo "   - Usuario: $POSTGRES_USER"
echo "   - Base de datos: $POSTGRES_DB"
echo "   - Puerto: 5432"
echo "   - Subred permitida: $API_SUBNET"
echo ""
echo "🔗 Cadena de conexión:"
echo "   Host=<IP_PRIVADA>;Port=5432;Database=$POSTGRES_DB;Username=$POSTGRES_USER;Password=$POSTGRES_PASSWORD"
echo ""
