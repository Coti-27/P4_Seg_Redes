#!/bin/bash

# 1. Configuración de Red: Puerta de enlace hacia el Router
# Eliminamos la ruta por defecto de Docker y forzamos el uso del router
ip route del default 2>/dev/null || true
ip route add default via 10.0.1.2

# 2. Configuración de Firewall (IPTABLES)
# Limpiamos reglas anteriores para asegurar que la conectividad de la Fase 2 no se bloquee
iptables -F
iptables -P INPUT ACCEPT   # Temporalmente en ACCEPT para validar conectividad
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir tráfico local e ICMP (ping)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# 3. Configuración de Seguridad SSH (sshd_config)
# Requisito: Deshabilitar root y usar solo llaves
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restricción de usuarios según el enunciado:
# - 'jump' es el único para el primer salto desde el exterior.
# - 'op' puede acceder a todas las máquinas.
echo "AllowUsers jump op" >> /etc/ssh/sshd_config

# 4. Iniciar servicios obligatorios
service rsyslog start
service ssh start

echo "Nodo JUMP iniciado: Configuración de ruteo y SSH aplicada."

# 5. Mantener el contenedor activo
# Corregimos el uso de "$@" por "$1" para mayor estabilidad
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi