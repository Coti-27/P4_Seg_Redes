#!/bin/bash

# 1. Habilitar el reenvío de paquetes (Crucial para que funcione como router)
# Permite que el tráfico pase entre las interfaces de las redes dmz, srv y dev
sysctl -w net.ipv4.ip_forward=1

# 2. Desactivar el filtro de ruta inversa (Crítico para tráfico entre subredes Docker)
# Esto evita que el kernel descarte paquetes que llegan por una interfaz distinta a la de salida
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
# Desactivación agresiva en todas las interfaces para evitar bloqueos del kernel
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $i; done

# 3. Limpiar reglas previas de iptables
iptables -F
iptables -t nat -F
iptables -t mangle -F

# 4. Políticas por defecto (Permitir todo en esta fase para facilitar el ruteo)
# Se ajustará a DROP en la Fase 4 según el enunciado
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 5. NAT (Masquerade): Permite que los nodos internos respondan al router correctamente
# Es vital en entornos Docker para enmascarar las IPs de las distintas subredes
iptables -t nat -A POSTROUTING -j MASQUERADE

# 6. Iniciar servicios del sistema
# Requisito: todos los nodos deben tener rsyslog activo
service rsyslog start
echo "Router activo con Forwarding y Masquerade..."

# 7. Mantener el contenedor activo
# Si no se pasan argumentos (comportamiento del Makefile), lanza bash para que el nodo no muera
if [ -z "$1" ]; then
    exec /bin/bash
else
    exec "$@"
fi