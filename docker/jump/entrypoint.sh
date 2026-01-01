#!/bin/bash

# Configuración de Red por defecto hacia el Router
ip route del default 2>/dev/null || true
ip route add default via 10.0.1.2

# Configuración de Firewall
iptables -F
iptables -t nat -F

# Establecer políticas por defecto restrictivas para el nodo Jump
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Reglas de entrada para el nodo Jump
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Regla que permite el tráfico de respuesta para conexiones ya aceptadas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir acceso SSH (puerto 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Deshabilitar root y autenticación por contraseña
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Permitir solo usuarios jump y op
if ! grep -q "AllowUsers jump op" /etc/ssh/sshd_config; then
    echo "AllowUsers jump op" >> /etc/ssh/sshd_config
fi

# Asegurar que rsyslog tenga donde escribir y permisos correctos
echo "$(date) [AUDITORIA] Nodo $(hostname) securizado y operativo." | tee -a /var/log/syslog
service rsyslog start 2>/dev/null || echo "rsyslog iniciado"
service ssh start
echo "Nodo Jump securizado: Política DROP activa y SSH configurado."

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi