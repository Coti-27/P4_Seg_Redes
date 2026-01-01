#!/bin/bash

# Directorio de destino para los certificados
TARGET_DIR="certs"

# Crear la carpeta si no existe
mkdir -p $TARGET_DIR

echo "Iniciando generación de certificados en /$TARGET_DIR"

# Generar la CA
openssl genrsa -out $TARGET_DIR/ca_priv.pem 4096
openssl req -x509 -new -nodes -key $TARGET_DIR/ca_priv.pem -sha256 -days 365 -out $TARGET_DIR/cert_CA.crt -subj "/CN=MyLocalCA"

# Función para generar certificado firmado para un nodo
gen_node_cert() {
  NODE_NAME=$1
  IP=$2
  
  echo "Generando certificado para: $NODE_NAME ($IP)..."

  # Llave privada del nodo
  openssl genrsa -out $TARGET_DIR/${NODE_NAME}-priv.pem 2048
  
  # Archivo de configuración temporal para SAN
  cat > $TARGET_DIR/${NODE_NAME}.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = ${NODE_NAME}
[v3_req]
subjectAltName = @alt_names
[alt_names]
IP.1 = ${IP}
DNS.1 = ${NODE_NAME}
EOF

  # Generar la solicitud de firma de certificado
  openssl req -new -key $TARGET_DIR/${NODE_NAME}-priv.pem -out $TARGET_DIR/${NODE_NAME}.csr -config $TARGET_DIR/${NODE_NAME}.cnf
  
  # Firmar el certificado con la CA
  openssl x509 -req -in $TARGET_DIR/${NODE_NAME}.csr -CA $TARGET_DIR/cert_CA.crt -CAkey $TARGET_DIR/ca_priv.pem \
    -CAcreateserial -out $TARGET_DIR/${NODE_NAME}.crt -days 365 -sha256 -extfile $TARGET_DIR/${NODE_NAME}.cnf -extensions v3_req
    
  # Limpiar archivos temporales de solicitud
  rm $TARGET_DIR/${NODE_NAME}.csr $TARGET_DIR/${NODE_NAME}.cnf
}

# Generar certificados para los 3 servicios con sus IPs correspondientes
gen_node_cert "mydb-broker" "10.0.1.4"
gen_node_cert "mydb-auth" "10.0.2.3"
gen_node_cert "mydb-doc" "10.0.2.4"

echo "Proceso finalizado. Archivos guardados en /$TARGET_DIR"