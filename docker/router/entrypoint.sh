#!/bin/bash

# Habilitar el reenvío de paquetes (Forwarding) - Crucial para un router
sysctl -w net.ipv4.ip_forward=1

# Limpiar reglas previas
iptables -F
iptables -t nat -F

# Políticas por defecto (Fase 1: Permitimos para configurar, endureceremos en Fase 4)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# NAT/Masquerade: Permite que los nodos de las redes internas (srv, dev, dmz)

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Iniciar servicios necesarios
service rsyslog start

echo "Router configurado y funcionando..."

# Mantener el contenedor ejecutándose
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi