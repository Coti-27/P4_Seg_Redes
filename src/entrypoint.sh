#!/bin/bash

# --- Configuración de Red Dinámica ---
IP_ADDR=$(hostname -I | awk '{print $1}')
GATEWAY=$(echo $IP_ADDR | cut -d. -f1-3).2

# Forzamos la desactivación del filtro de ruta inversa
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0

ip route del default 2>/dev/null || true
ip route add default via $GATEWAY

# --- Configuración de Usuario Operador (Paso 5) ---
# Creamos el usuario op si no existe
if ! id "op" &>/dev/null; then
    useradd -ms /bin/bash op
    echo "op ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/op
    chmod 0440 /etc/sudoers.d/op
fi

# Configuramos su llave pública para el acceso SSH
mkdir -p /home/op/.ssh
# Buscamos la llave en /certs (montada mediante el Makefile)
if [ -f "/certs/op_key.pub" ]; then
    cp /certs/op_key.pub /home/op/.ssh/authorized_keys
    chown -R op:op /home/op/.ssh
    chmod 700 /home/op/.ssh
    chmod 600 /home/op/.ssh/authorized_keys
fi

# --- Configuración de Firewall (IPTABLES) ---
iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP

# --- Inicio de Servicios ---
service rsyslog start
service ssh start

echo "Servicio SSH y Firewall activos. Usuario 'op' configurado."

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi