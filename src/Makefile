.PHONY: all clean certs install-certs uninstall-certs

all: mydb

%: cmd/%/main.go
	go build -ldflags "-s -w" ./cmd/$@
	strip $@

clean:
	find . -name "*~" -delete

# Certificates generation
ca_priv.pem cert_CA.crt:
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -sha256 \
		-subj "/CN=Local Development CA" \
		-keyout ca_priv.pem -out cert_CA.crt \
		-addext "basicConstraints=critical,CA:TRUE" \
		-addext "keyUsage=critical,keyCertSign,cRLSign"

cert-priv.pem:
	openssl genrsa -out $@ 2048

cert-req.csr: cert-priv.pem
	openssl req -new -key cert-priv.pem -out $@ \
		-subj "/CN=myserver.local" \
		-addext "subjectAltName = DNS:myserver.local"

cert.crt: cert-req.csr cert_CA.crt ca_priv.pem
	openssl x509 -req -in cert-req.csr -CA cert_CA.crt -CAkey ca_priv.pem -out $@ \
		-days 3650 -sha512 \
		-extfile san.cnf

certs: cert.crt cert_CA.crt
install-certs: certs
	sudo cp cert_CA.crt /usr/local/share/ca-certificates/
	sudo update-ca-certificates

uninstall-certs:
	sudo rm /usr/local/share/ca-certificates/cert_CA.crt
	sudo update-ca-certificates --fresh
