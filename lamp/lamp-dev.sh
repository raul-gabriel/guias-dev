#!/bin/bash

# ============================================
# LAMP Stack - Instalación Simple
# Solo instala Apache + MySQL + PHP
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════╗
║        LAMP Stack Installer           ║
║     Apache + MySQL + PHP              ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# Solicitar solo contraseña root de MySQL
echo -e "${YELLOW}Configuración MySQL:${NC}"
read -sp "Contraseña para root de MySQL: " MYSQL_ROOT_PASS
echo ""
echo ""

# Confirmación
read -p "¿Iniciar instalación? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# 1. Actualizar sistema
echo -e "${GREEN}[1/5] Actualizando sistema...${NC}"
sudo apt update -qq

# 2. Instalar LAMP completo
echo -e "${GREEN}[2/5] Instalando Apache, MySQL, PHP...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    apache2 \
    mysql-server \
    php \
    libapache2-mod-php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    > /dev/null 2>&1

# 3. Habilitar módulos Apache
echo -e "${GREEN}[3/5] Habilitando módulos Apache...${NC}"
sudo a2enmod rewrite > /dev/null 2>&1

# 4. Configurar MySQL root password
echo -e "${GREEN}[4/5] Configurando MySQL...${NC}"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}';" 2>/dev/null

# 5. Reiniciar servicios
echo -e "${GREEN}[5/5] Reiniciando servicios...${NC}"
sudo systemctl restart apache2
sudo systemctl restart mysql
sudo systemctl enable apache2 > /dev/null 2>&1
sudo systemctl enable mysql > /dev/null 2>&1

# Crear archivo de prueba
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

# Dar permisos al usuario actual
sudo chown -R $USER:$USER /var/www/html

# Resumen
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✅ LAMP instalado correctamente    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 Apache:${NC}"
echo "   URL: http://localhost"
echo "   PHP Info: http://localhost/info.php"
echo "   Directorio: /var/www/html/"
echo ""
echo -e "${BLUE}🗄️  MySQL:${NC}"
echo "   Usuario: root"
echo "   Conectar: mysql -u root -p"
echo ""
echo -e "${BLUE}🔧 Comandos útiles:${NC}"
echo "   Reiniciar Apache: sudo systemctl restart apache2"
echo "   Logs Apache: sudo tail -f /var/log/apache2/error.log"
echo "   Reiniciar MySQL: sudo systemctl restart mysql"
echo ""
echo -e "${YELLOW}💡 Comienza a programar en: /var/www/html/${NC}"
echo ""