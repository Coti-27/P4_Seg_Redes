#!/bin/bash

# Configurar la ruta por defecto para que todo el tráfico salga a través del nodo FW
ip route del default 2>/dev/null || true
ip route add default via 10.0.1.2

# Configurar reglas básicas de iptables
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir tráfico en la interfaz de loopback y tráfico ICMP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Denegar todo el tráfico entrante no solicitado y permitir el tráfico saliente
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Permitir solo a los usuarios 'jump' y 'op' acceder vía SSH
echo "AllowUsers jump op" >> /etc/ssh/sshd_config

# Iniciar servicios necesarios
service rsyslog start
service ssh start

echo "Nodo JUMP iniciado."

# Ejecutar el comando proporcionado o iniciar una shell interactiva
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi