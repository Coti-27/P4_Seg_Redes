#!/bin/bash

# 1. Configuración de Red: Puerta de enlace hacia el Router (Red DEV)
# Forzamos que todo el tráfico salga por la IP del router en esta subred
ip route del default 2>/dev/null || true
ip route add default via 10.0.3.2

# 2. Configuración de Firewall (IPTABLES)
# Limpiamos reglas para asegurar que el curl al broker no se bloquee localmente
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir tráfico local e ICMP (ping)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# 3. Configuración de Seguridad SSH (sshd_config)
# Requisito: Deshabilitar root y usar solo llaves
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Permitir acceso a los usuarios del personal
echo "AllowUsers op dev" >> /etc/ssh/sshd_config

# 4. Iniciar servicios obligatorios
service rsyslog start
service ssh start

echo "Nodo WORK iniciado: Cortafuegos abierto para pruebas y SSH configurado."

# 5. Mantener el contenedor activo
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi
