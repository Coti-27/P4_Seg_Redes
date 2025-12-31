#!/bin/bash

# --- Configuración de Red Dinámica ---
IP_ADDR=$(hostname -I | awk '{print $1}')
GATEWAY=$(echo $IP_ADDR | cut -d. -f1-3).2

# Forzamos la desactivación del filtro de ruta inversa
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0

ip route del default 2>/dev/null || true
ip route add default via $GATEWAY

# --- Configuración de Firewall (IPTABLES) ---
iptables -F

# REGLA ORO: Permitir conexiones establecidas para evitar el colgado del handshake SSL
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Aplicar política DROP al final
iptables -P INPUT DROP
iptables -P FORWARD DROP

service ssh start
service rsyslog start

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi