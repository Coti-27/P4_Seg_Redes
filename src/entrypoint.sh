#!/bin/bash

# Obtener la dirección IP y configurar la ruta por defecto
IP_ADDR=$(hostname -I | awk '{print $1}')
GATEWAY=$(echo $IP_ADDR | cut -d. -f1-3).2

# Desactivar el filtrado inverso de paquetes
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0

# Configurar la IP estática y la ruta por defecto
ip route del default 2>/dev/null || true
ip route add default via $GATEWAY

# Crear el usuario 'op' si no existe
if ! id "op" &>/dev/null; then
    useradd -ms /bin/bash op
    echo "op ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/op
    chmod 0440 /etc/sudoers.d/op
fi

# Configurar las claves SSH para el usuario 'op'
mkdir -p /home/op/.ssh
if [ -f "/certs/op_key.pub" ]; then
    cp /certs/op_key.pub /home/op/.ssh/authorized_keys
    chown -R op:op /home/op/.ssh
    chmod 700 /home/op/.ssh
    chmod 600 /home/op/.ssh/authorized_keys
fi

# Configurar el firewall con iptables y permitir SSH y tráfico en el puerto 8080
iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Establecer políticas para denegar todo el tráfico no permitido
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Iniciar los servicios necesarios
service rsyslog start
service ssh start

echo "Servicio SSH y Firewall activos. Usuario 'op' configurado."

# Ejecutar el comando proporcionado o iniciar una shell bash
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi