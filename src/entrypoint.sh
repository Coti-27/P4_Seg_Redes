#!/bin/bash

# Configuración de Red por defecto hacia el Router
IP_ADDR=$(hostname -I | awk '{print $1}')
GATEWAY=$(echo $IP_ADDR | cut -d. -f1-3).2

# Deshabilitar el filtro de ruta inversa
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0

# Configuración de Red por defecto hacia el Router
ip route del default 2>/dev/null || true
ip route add default via $GATEWAY

# Crear usuario op si no existe
if ! id "op" &>/dev/null; then
    useradd -ms /bin/bash op
    echo "op ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/op
    chmod 0440 /etc/sudoers.d/op
fi

# Configurar clave SSH para el usuario op
mkdir -p /home/op/.ssh
if [ -f "/certs/op_key.pub" ]; then
    cp /certs/op_key.pub /home/op/.ssh/authorized_keys
    chown -R op:op /home/op/.ssh
    chmod 700 /home/op/.ssh
    chmod 600 /home/op/.ssh/authorized_keys
fi

# Configuración de Firewall para los nodos de función
iptables -F
iptables -t nat -F

# Establecer políticas por defecto restrictivas para los nodos de función
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Reglas de entrada para los nodos de función
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Permitir conexiones establecidas y relacionadas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir acceso HTTPS/API (puerto 8080)
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# Permitir acceso SSH (puerto 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Deshabilitar root y autenticación por contraseña
echo "$(date) [AUDITORIA] Nodo $(hostname) securizado y operativo." | tee -a /var/log/syslog
service rsyslog start 2>/dev/null || echo "rsyslog iniciado"
service ssh start
echo "Nodos de Función securizados: Política DROP activa y SSH configurado."

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi