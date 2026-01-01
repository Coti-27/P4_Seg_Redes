#!/bin/bash

# Configurar la ruta por defecto para que apunte al router
ip route del default 2>/dev/null || true
ip route add default via 10.0.3.2

# Configurar las reglas de iptables para abrir todo el tráfico
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir tráfico en la interfaz de loopback y ICMP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Desactivar el reenvío de paquetes IPv4
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Permitir acceso SSH solo a los usuarios 'op' y 'dev'
echo "AllowUsers op dev" >> /etc/ssh/sshd_config

# Iniciar los servicios necesarios
service rsyslog start
service ssh start

echo "Nodo WORK iniciado."

# Si no se pasan argumentos, iniciar una shell bash
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi
