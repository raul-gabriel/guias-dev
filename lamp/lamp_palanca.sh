#!/bin/bash
# Script para controlar servicios LAMP (Apache, MySQL, PHP)
# Uso: lamp {start|stop|restart|status} [mysql|apache]

SERVICES="mysql apache2"

# Función para ejecutar acción en servicios
execute_action() {
    local action=$1
    local target_services=$2
    
    for service in $target_services; do
        case $action in
            start)
                sudo systemctl start $service
                ;;
            stop)
                sudo systemctl stop $service
                ;;
            restart)
                sudo systemctl restart $service
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ $service $action"
        else
            echo "✗ Error al $action $service"
        fi
    done
}

# Determinar qué servicios afectar
if [ -n "$2" ]; then
    case "$2" in
        mysql)
            TARGET_SERVICES="mysql"
            ;;
        apache|apache2)
            TARGET_SERVICES="apache2"
            ;;
        *)
            echo "Servicio no válido. Usa: mysql o apache"
            exit 1
            ;;
    esac
else
    TARGET_SERVICES=$SERVICES
fi

case "$1" in
    start)
        echo "🚀 Iniciando servicios LAMP..."
        execute_action "start" "$TARGET_SERVICES"
        echo ""
        echo "LAMP está corriendo. Accede a http://localhost"
        ;;
    
    stop)
        echo "🛑 Deteniendo servicios LAMP..."
        execute_action "stop" "$TARGET_SERVICES"
        echo ""
        echo "Servicios detenidos. Recursos liberados."
        ;;
    
    restart)
        echo "🔄 Reiniciando servicios LAMP..."
        execute_action "restart" "$TARGET_SERVICES"
        echo ""
        echo "Servicios reiniciados correctamente."
        ;;
    
    status)
        echo "📊 Estado de servicios LAMP:"
        echo ""
        for service in $SERVICES; do
            if systemctl is-active --quiet $service; then
                echo "✓ $service: CORRIENDO"
            else
                echo "✗ $service: DETENIDO"
            fi
        done
        ;;
    
    *)
        echo "Uso: lamp {start|stop|restart|status} [mysql|apache]"
        echo ""
        echo "Comandos disponibles:"
        echo "  lamp start          - Iniciar Apache y MySQL"
        echo "  lamp start mysql    - Iniciar solo MySQL"
        echo "  lamp start apache   - Iniciar solo Apache"
        echo "  lamp stop           - Detener todos"
        echo "  lamp stop mysql     - Detener solo MySQL"
        echo "  lamp restart apache - Reiniciar solo Apache"
        echo "  lamp status         - Ver estado de los servicios"
        exit 1
        ;;
esac
exit 0
