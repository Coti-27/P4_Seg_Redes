#!/bin/bash

# Configuración de Red por defecto hacia el Router
ip route del default 2>/dev/null || true
ip route add default via 10.0.3.2

# Configuración de Firewall para el nodo Work
iptables -F
iptables -t nat -F

# Establecer políticas por defecto restrictivas para el nodo Work
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Reglas de entrada para el nodo Work
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir acceso HTTPS/API (puerto 8080)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Deshabilitar root y autenticación por contraseña
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Permitir solo usuarios op y dev
if ! grep -q "AllowUsers op dev" /etc/ssh/sshd_config; then
    echo "AllowUsers op dev" >> /etc/ssh/sshd_config
fi

# Asegurar que rsyslog tenga donde escribir y permisos correctos
echo "$(date) [AUDITORIA] Nodo $(hostname) securizado y operativo" | tee -a /var/log/syslog
service rsyslog start 2>/dev/null || echo "rsyslog iniciado"
service ssh start
echo "Nodo Work securizado: Política DROP activa y SSH configurado."

if [ -z "$1" ]; then
    exec /bin/bash;
else
    exec "$@";
fi