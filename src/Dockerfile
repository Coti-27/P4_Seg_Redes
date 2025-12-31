# Etapa 1: Compilación
FROM golang:1.24 AS builder

WORKDIR /src

# Copiamos los archivos de definición de módulos primero para cachear capas
COPY go.mod go.sum ./
RUN go mod download

# Copiamos todo el código fuente
COPY . .

# Compilamos los 3 binarios
RUN go build -o /bin/mydb-auth ./cmd/auth/main.go
RUN go build -o /bin/mydb-doc ./cmd/doc/main.go
RUN go build -o /bin/mydb-broker ./cmd/broker/main.go

# Etapa 2: Imagen final
FROM debian:12

# Instalamos TODAS las herramientas necesarias para el entrypoint y SSH
RUN apt-get update && apt-get install -y \
    ca-certificates \
    iproute2 \
    iputils-ping \
    curl \
    procps \
    iptables \
    openssh-server \
    rsyslog \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Creamos el directorio para el socket de SSH
RUN mkdir -p /var/run/sshd

# Copiamos los 3 binarios generados
COPY --from=builder /bin/mydb-auth /usr/local/bin/mydb-auth
COPY --from=builder /bin/mydb-doc /usr/local/bin/mydb-doc
COPY --from=builder /bin/mydb-broker /usr/local/bin/mydb-broker

# Copiamos y preparamos el entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# El entrypoint recibirá como argumento el nombre del binario a ejecutar
ENTRYPOINT ["/entrypoint.sh"]