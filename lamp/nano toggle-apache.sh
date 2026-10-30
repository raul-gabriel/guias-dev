 
#!/bin/bash

STATUS=$(systemctl is-active apache2)

if [ "$STATUS" = "active" ]; then
    echo "🛑 Deteniendo Apache..."
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    echo "✅ Apache detenido"
else
    echo "🚀 Iniciando Apache..."
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "✅ Apache corriendo"
fi

systemctl status apache2 | grep Active