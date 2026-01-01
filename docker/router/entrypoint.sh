#!/bin/bash

# Habilitar el reenvío de paquetes IPv4
sysctl -w net.ipv4.ip_forward=1

# Deshabilitar el filtrado inverso para evitar problemas de routing
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
# Deshabilitar rp_filter en todas las interfaces existentes
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $i; done

# Limpiar reglas de iptables existentes
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Establecer políticas por defecto a ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Configurar Masquerade para el tráfico saliente
iptables -t nat -A POSTROUTING -j MASQUERADE

# Iniciar el servicio de syslog para registrar eventos del sistema
service rsyslog start
echo "Router activo con Forwarding y Masquerade."

# Ejecutar el comando proporcionado o iniciar una shell interactiva
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi