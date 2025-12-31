FROM debian:12

# Instalar dependencias necesarias para red y servicios
# Se añade curl para poder realizar las validaciones de la Fase 2
RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    iputils-ping \
    rsyslog \
    openssh-server \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar SSH básico
RUN mkdir /var/run/sshd

# Copiar el script de entrada y darle permisos de ejecución
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar el punto de entrada del contenedor
ENTRYPOINT ["/entrypoint.sh"]
