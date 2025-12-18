FROM golang:1.25 AS builder

WORKDIR /src
COPY . .

RUN make mydb

FROM midebian
COPY --from=builder /src/mydb /usr/local/bin/mydb
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]