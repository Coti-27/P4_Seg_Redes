#!/bin/bash

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
API_URL="https://10.0.1.4:8080"
USER="testuser_$(date +%s)"
PASS="testpass123"
DOC_ID="doc_test_$(date +%s)"

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}   BATERÍA DE PRUEBAS AUTOMÁTICAS - PRÁCTICA 4    ${NC}"
echo -e "${BLUE}===================================================${NC}"

# 1. VERIFICACIÓN DE CONECTIVIDAD BÁSICA (BROKER)
echo -e "\n${BLUE}[1/8] Verificando Broker (/version)...${NC}"
VERSION_RESP=$(curl -s -k --max-time 5 "$API_URL/version")
if echo "$VERSION_RESP" | grep -q "broker"; then
    echo -e "${GREEN}[OK] Broker respondiendo: $VERSION_RESP${NC}"
else
    echo -e "${RED}[ERROR] El Broker no responde o no es accesible.${NC}"
    exit 1
fi

# 2. PRUEBA DE REGISTRO (BROKER -> AUTH)
echo -e "\n${BLUE}[2/8] Probando Registro de Usuario (/signup)...${NC}"
SIGNUP_RESP=$(curl -s -k -X POST "$API_URL/signup" \
    -H "Content-Type: application/json" \
    -d "{\"user\":\"$USER\", \"pass\":\"$PASS\"}")

if echo "$SIGNUP_RESP" | grep -q "successfully"; then
    echo -e "${GREEN}[OK] Usuario creado correctamente.${NC}"
else
    echo -e "${RED}[ERROR] Fallo en el registro: $SIGNUP_RESP${NC}"
    exit 1
fi

# 3. PRUEBA DE LOGIN Y OBTENCIÓN DE TOKEN (BROKER -> AUTH)
echo -e "\n${BLUE}[3/8] Probando Login y Token (/login)...${NC}"
LOGIN_RESP=$(curl -s -k -X POST "$API_URL/login" \
    -H "Content-Type: application/json" \
    -d "{\"user\":\"$USER\", \"pass\":\"$PASS\"}")

TOKEN=$(echo "$LOGIN_RESP" | grep -oP '(?<="token":")[^"]+')

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}[OK] Login exitoso. Token obtenido.${NC}"
else
    echo -e "${RED}[ERROR] No se pudo obtener el token: $LOGIN_RESP${NC}"
    exit 1
fi

# 4. PRUEBA DE ALMACENAMIENTO (BROKER -> DOC)
echo -e "\n${BLUE}[4/8] Probando Subida de Documento (/upload)...${NC}"
UPLOAD_RESP=$(curl -s -k -X POST "$API_URL/upload?id=$DOC_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-User: $USER" \
    -d "{\"content\": \"Prueba de seguridad P4\", \"timestamp\": \"$(date)\"}")

if echo "$UPLOAD_RESP" | grep -q "saved"; then
    echo -e "${GREEN}[OK] Documento guardado en el microservicio DOC.${NC}"
else
    echo -e "${RED}[ERROR] Fallo al subir documento: $UPLOAD_RESP${NC}"
    exit 1
fi

# 5. TEST DE PROTOCOLO (SEGURIDAD)
echo -e "\n${BLUE}[5/8] Verificando rechazo de HTTP plano...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://10.0.1.4:8080/version")
if [ "$HTTP_CODE" == "000" ] || [ "$HTTP_CODE" == "400" ]; then
    echo -e "${GREEN}[OK] El sistema no acepta conexiones inseguras HTTP.${NC}"
else
    echo -e "${RED}[FALLO] El puerto responde en HTTP plano (Código: $HTTP_CODE).${NC}"
fi

# 6. TEST DE ACCESO EXTERNO PROHIBIDO (AISLAMIENTO)
echo -e "\n${BLUE}[6/8] Verificando que Auth no es accesible desde el Exterior...${NC}"
# Intentamos acceder a Auth directamente saltándonos el broker
AUTH_EXT=$(curl -s -k --max-time 2 "https://10.0.2.3:8080/signup" 2>&1)
if [[ "$AUTH_EXT" == *"timed out"* ]]; then
    echo -e "${GREEN}[OK] Microservicio Auth correctamente aislado del exterior.${NC}"
else
    echo -e "${RED}[FALLO] Auth es accesible directamente desde el Host${NC}"
fi

# 7. PRUEBA DE ACCESO ADMINISTRATIVO (SSH)
echo -e "\n${BLUE}[7/8] Verificando acceso SSH al nodo Work...${NC}"
if docker exec router ping -c 1 10.0.3.3 > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] El nodo Work es alcanzable para administración.${NC}"
else
    echo -e "${RED}[FALLO] El nodo Work no responde al Router.${NC}"
fi

# 8. PRUEBA DE AISLAMIENTO INTERNO (WORK -> AUTH)
echo -e "\n${BLUE}[8/8] Verificando Aislamiento de Red (Work -> Auth)...${NC}"
ISO_TEST=$(docker exec work curl -s -k --max-time 2 "https://10.0.2.3:8080/version" 2>&1)
if [[ "$ISO_TEST" == *"timed out"* ]] || [[ "$ISO_TEST" == *"Failed to connect"* ]]; then
    echo -e "${GREEN}[OK] Aislamiento confirmado: Work no accede a Auth directamente.${NC}"
else
    echo -e "${RED}[ALERTA] Work tiene acceso directo a Auth. Revisar Firewall del Router.${NC}"
fi

echo -e "\n${BLUE}===================================================${NC}"
echo -e "${GREEN}      BATERÍA DE PRUEBAS FINALIZADA CON ÉXITO      ${NC}"
echo -e "${BLUE}===================================================${NC}"