#!/bin/bash

# ============================================
# LAMP Stack - Producción (VPS)
# Instalación segura con SSL y hardening
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
║   LAMP Stack - Production Server      ║
║   Secure Installation                 ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script debe ejecutarse como root (sudo)${NC}"
   exit 1
fi

# Solicitar datos
echo -e "${YELLOW}Configuración del servidor:${NC}"
echo ""
read -p "Dominio principal (ej: miapp.com): " DOMAIN
read -p "Email para notificaciones SSL: " SSL_EMAIL
echo ""
read -sp "Contraseña root MySQL (min 16 caracteres): " MYSQL_ROOT_PASS
echo ""
echo ""

# Validar contraseña
if [[ ${#MYSQL_ROOT_PASS} -lt 16 ]]; then
    echo -e "${RED}❌ La contraseña debe tener mínimo 16 caracteres${NC}"
    exit 1
fi

# Validar dominio
if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
    echo -e "${RED}❌ Formato de dominio inválido${NC}"
    exit 1
fi

# Confirmación
echo -e "${YELLOW}Resumen:${NC}"
echo "  Dominio: $DOMAIN"
echo "  Email SSL: $SSL_EMAIL"
echo "  Se instalará: Apache, MySQL, PHP, SSL, Firewall, Fail2ban"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# 1. Actualizar sistema
echo -e "${GREEN}[1/10] Actualizando sistema...${NC}"
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq

# 2. Instalar LAMP
echo -e "${GREEN}[2/10] Instalando LAMP Stack...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y \
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
    php-opcache \
    > /dev/null 2>&1

# 3. Configurar Firewall
echo -e "${GREEN}[3/10] Configurando firewall (UFW)...${NC}"
apt install -y ufw > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1

# 4. Instalar Fail2ban
echo -e "${GREEN}[4/10] Instalando Fail2ban...${NC}"
apt install -y fail2ban > /dev/null 2>&1
systemctl enable fail2ban > /dev/null 2>&1
systemctl start fail2ban

# 5. Configurar MySQL (seguridad)
echo -e "${GREEN}[5/10] Asegurando MySQL...${NC}"

# Configurar root password
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}';"

# Hardening MySQL
mysql -u root -p"${MYSQL_ROOT_PASS}" << MYSQLEOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQLEOF

# Configuración segura MySQL
cat > /etc/mysql/mysql.conf.d/production.cnf << MYSQLCONF
[mysqld]
bind-address = 127.0.0.1
skip-name-resolve
max_connections = 100
max_allowed_packet = 64M
MYSQLCONF

systemctl restart mysql

# 6. Configurar Apache
echo -e "${GREEN}[6/10] Configurando Apache...${NC}"

# Habilitar módulos necesarios
a2enmod rewrite ssl headers deflate expires > /dev/null 2>&1

# Ocultar versión Apache
echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf
echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf

# Crear directorio del sitio
mkdir -p /var/www/$DOMAIN/public
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R 755 /var/www/$DOMAIN

# Página de mantenimiento temporal
cat > /var/www/$DOMAIN/public/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sitio en construcción</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        p { font-size: 1.2em; opacity: 0.9; }
        .emoji { font-size: 5em; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>Sitio en construcción</h1>
        <p>Pronto estaremos en línea</p>
    </div>
</body>
</html>
HTMLEOF

# Virtual Host (HTTP - se convertirá a HTTPS después)
cat > /etc/apache2/sites-available/$DOMAIN.conf << VHOSTEOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/$DOMAIN/public

    <Directory /var/www/$DOMAIN/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Security Headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    # Logs
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
VHOSTEOF

# Activar sitio
a2ensite $DOMAIN.conf > /dev/null 2>&1
a2dissite 000-default.conf > /dev/null 2>&1

# 7. Configurar PHP para producción
echo -e "${GREEN}[7/10] Optimizando PHP...${NC}"
PHP_INI=$(php -i | grep "Loaded Configuration File" | awk '{print $5}')

# Configuración segura PHP
sed -i 's/^display_errors = .*/display_errors = Off/' $PHP_INI
sed -i 's/^display_startup_errors = .*/display_startup_errors = Off/' $PHP_INI
sed -i 's/^expose_php = .*/expose_php = Off/' $PHP_INI
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI
sed -i 's/^post_max_size = .*/post_max_size = 20M/' $PHP_INI
sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI
sed -i 's/^max_execution_time = .*/max_execution_time = 30/' $PHP_INI

# OPcache para producción
cat >> $PHP_INI << PHPEOF

; OPcache Production
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=0
PHPEOF

# 8. Instalar Certbot (SSL)
echo -e "${GREEN}[8/10] Instalando Certbot...${NC}"
apt install -y certbot python3-certbot-apache > /dev/null 2>&1

# 9. Reiniciar Apache
echo -e "${GREEN}[9/10] Reiniciando servicios...${NC}"
systemctl restart apache2
systemctl enable apache2 > /dev/null 2>&1

# 10. Configurar SSL
echo -e "${GREEN}[10/10] Configurando SSL (Let's Encrypt)...${NC}"
certbot --apache \
    --non-interactive \
    --agree-tos \
    --email $SSL_EMAIL \
    --domains $DOMAIN,www.$DOMAIN \
    --redirect \
    2>&1 | grep -v "Saving debug log"

# Renovación automática SSL
systemctl enable certbot.timer > /dev/null 2>&1
systemctl start certbot.timer

# Guardar credenciales en archivo seguro
CREDS_FILE="/root/.lamp_credentials_$(date +%Y%m%d_%H%M%S).txt"
cat > $CREDS_FILE << CREDSEOF
╔════════════════════════════════════════════════╗
║         CREDENCIALES SERVIDOR LAMP             ║
║         Generado: $(date)                  ║
╚════════════════════════════════════════════════╝

DOMINIO: $DOMAIN
URL: https://$DOMAIN

MYSQL ROOT:
  Usuario: root
  Password: $MYSQL_ROOT_PASS
  Conectar: mysql -u root -p

DIRECTORIO WEB:
  Ruta: /var/www/$DOMAIN/public
  Usuario: www-data
  Permisos: 755

LOGS:
  Apache Error: /var/log/apache2/${DOMAIN}_error.log
  Apache Access: /var/log/apache2/${DOMAIN}_access.log
  MySQL: /var/log/mysql/error.log

COMANDOS ÚTILES:
  Reiniciar Apache: systemctl restart apache2
  Reiniciar MySQL: systemctl restart mysql
  Ver logs Apache: tail -f /var/log/apache2/${DOMAIN}_error.log
  Firewall status: ufw status
  SSL renovar manual: certbot renew

SEGURIDAD CONFIGURADA:
  ✅ Firewall (UFW)
  ✅ Fail2ban
  ✅ SSL/HTTPS
  ✅ MySQL hardening
  ✅ PHP production mode
  ✅ Security headers

⚠️  IMPORTANTE:
  1. Copia este archivo a lugar seguro
  2. Borra este archivo del servidor:
     rm $CREDS_FILE
  3. Cambia puerto SSH por defecto
  4. Configura backups automáticos
  5. No uses root para deploy
CREDSEOF

chmod 600 $CREDS_FILE

# Resumen final
clear
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║                                                ║
║        ✅  SERVIDOR CONFIGURADO               ║
║           Instalación completada               ║
║                                                ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
echo -e "${BLUE}🌐 Sitio web:${NC}"
echo "   URL: https://$DOMAIN"
echo "   Ruta archivos: /var/www/$DOMAIN/public"
echo ""
echo -e "${BLUE}🗄️  MySQL:${NC}"
echo "   Usuario: root"
echo "   Conectar: mysql -u root -p"
echo ""
echo -e "${BLUE}🔒 Seguridad activada:${NC}"
echo "   ✅ Firewall (puertos 22, 80, 443)"
echo "   ✅ Fail2ban (protección ataques)"
echo "   ✅ SSL/HTTPS (Let's Encrypt)"
echo "   ✅ MySQL hardening"
echo "   ✅ PHP modo producción"
echo ""
echo -e "${BLUE}📄 Credenciales guardadas en:${NC}"
echo "   ${YELLOW}$CREDS_FILE${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANTE - HACER AHORA:${NC}"
echo "   1. Ver credenciales: ${YELLOW}cat $CREDS_FILE${NC}"
echo "   2. Copiar a lugar seguro"
echo "   3. Borrar del servidor: ${YELLOW}rm $CREDS_FILE${NC}"
echo ""
echo -e "${BLUE}🚀 Próximos pasos:${NC}"
echo "   1. Sube tu aplicación a: /var/www/$DOMAIN/public"
echo "   2. Crea tus bases de datos MySQL"
echo "   3. Configura tus aplicaciones"
echo ""
echo -e "${YELLOW}💡 El sitio está en línea con página de mantenimiento${NC}"
echo -e "${YELLOW}   Accede a: https://$DOMAIN${NC}"
echo ""