#!/bin/bash

# 1. Habilitar el reenvío de paquetes
sysctl -w net.ipv4.ip_forward=1

# 2. Desactivar el filtro de ruta inversa (Evita que el router descarte paquetes asimétricos)
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0

# 3. Limpiar reglas
iptables -F
iptables -t nat -F

# 4. Políticas por defecto
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 5. NAT: Crucial para que los paquetes TCP no se pierdan entre subredes Docker
iptables -t nat -A POSTROUTING -j MASQUERADE

service rsyslog start
echo "Router configurado con Forwarding y Masquerade..."

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi