FROM debian:12

RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    iputils-ping \
    rsyslog \
    openssh-server \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
