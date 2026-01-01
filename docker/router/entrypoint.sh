#!/bin/bash

# Habilitar el reenvío de paquetes IP
sysctl -w net.ipv4.ip_forward=1
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $i; done

# Configurar la ruta por defecto hacia las redes internas
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Establecer políticas por defecto restrictivas para el router
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Reglas de entrada INPUT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir acceso SSH desde la red Jump
iptables -A INPUT -s 10.0.1.0/24 -j ACCEPT

# Reglas de reenvío FORWARD para el router
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT
iptables -A FORWARD -p tcp -d 10.0.1.4 --dport 8080 -j ACCEPT
iptables -A FORWARD -p tcp -d 10.0.1.3 --dport 22 -j ACCEPT

# Permitir tráfico entre todas las interfaces de red (evita bloqueos innecesarios)
iptables -A FORWARD -i eth+ -o eth+ -j ACCEPT

# Reglas específicas para permitir acceso a nodos Work desde Jump
iptables -A FORWARD -s 10.0.3.3 -d 10.0.1.4 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.0.1.4 -d 10.0.2.3 -p tcp --dport 8080 -j ACCEPT
iptables -A FORWARD -s 10.0.1.4 -d 10.0.2.4 -p tcp --dport 8080 -j ACCEPT

# Configurar NAT para las redes internas
iptables -t nat -A POSTROUTING -j MASQUERADE

# Configuración de auditoría con iptables LOG
echo "$(date) [AUDITORIA] Registro de auditoría del router iniciado." | tee -a /var/log/syslog

# Reglas de auditoría para conexiones SSH y API
iptables -A FORWARD -p tcp --dport 22 -d 10.0.1.3 -m comment --comment "AUDIT_SSH"
iptables -A FORWARD -p tcp --dport 8080 -d 10.0.1.4 -m comment --comment "AUDIT_API"

# Registrar intentos de acceso denegados
iptables -A FORWARD -j LOG --log-prefix "FW_REJECT: " --log-level 4

echo "Sistema de monitorización activo."
echo "Router Activo. Reglas de firewall aplicadas."

if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi