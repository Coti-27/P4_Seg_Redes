.PHONY: build network containers remove clean certs

# Variables de subredes Docker personalizadas
NET_DMZ = 10.0.1.0/24
NET_SRV = 10.0.2.0/24
NET_DEV = 10.0.3.0/24

# Lanzar todos los contenedores necesarios
containers: build network
	@echo "=== Lanzando nodo Router ==="
	docker run --privileged --rm -ti -d --name router --hostname router --network dmz --ip 10.0.1.2 midebian-router
	docker network connect --ip 10.0.2.2 srv router
	docker network connect --ip 10.0.3.2 dev router

	@echo "=== Lanzando nodos de Salto (Jump/Work) ==="
	docker run --privileged --rm -ti -d --name jump --hostname jump --ip 10.0.1.3 --network dmz midebian-jump
	
	# Inyectamos la llave privada del operador en work para permitir saltos posteriores
	docker run --privileged --rm -ti -d --name work --hostname work --ip 10.0.3.3 --network dev \
		-v $${PWD}/op_key:/home/op/.ssh/id_rsa midebian-work
	
	@echo "=== Lanzando servicios de Base de Datos (Distribuidos) ==="
	# Se añade el montaje de op_key.pub para que el entrypoint lo instale en authorized_keys
	docker run --privileged --rm -ti -d --name mydb-auth --hostname mydb-auth --ip 10.0.2.3 --network srv \
		-v $${PWD}/certs:/certs -v $${PWD}/op_key.pub:/certs/op_key.pub midebian-mydb mydb-auth
	docker run --privileged --rm -ti -d --name mydb-doc --hostname mydb-doc --ip 10.0.2.4 --network srv \
		-v $${PWD}/certs:/certs -v $${PWD}/op_key.pub:/certs/op_key.pub midebian-mydb mydb-doc
	docker run --privileged --rm -ti -d --name mydb-broker --hostname mydb-broker --ip 10.0.1.4 --network dmz \
		-v $${PWD}/certs:/certs -v $${PWD}/op_key.pub:/certs/op_key.pub midebian-mydb mydb-broker

	@echo "=== Configurando rutas y seguridad de identidades ==="
	sleep 2
	# Ajuste de permisos para la llave privada del operador
	docker exec work chown op:op /home/op/.ssh/id_rsa
	docker exec work chmod 600 /home/op/.ssh/id_rsa

	# Rutas de red para conectividad entre subredes
	docker exec work ip route add 10.0.1.0/24 via 10.0.3.2 || true
	docker exec work ip route add 10.0.2.0/24 via 10.0.3.2 || true
	docker exec mydb-auth ip route add 10.0.3.0/24 via 10.0.2.2 || true
	docker exec mydb-doc ip route add 10.0.3.0/24 via 10.0.2.2 || true
	docker exec mydb-broker ip route add 10.0.3.0/24 via 10.0.1.2 || true
	docker exec jump ip route add 10.0.3.0/24 via 10.0.1.2 || true

# Generar certificados TLS
certs:
	@echo "=== Generando certificados TLS mediante script ==="
	bash gen_certs.sh

# Construir todas las imágenes Docker necesarias
build: certs
	@echo "=== Construyendo imágenes Docker ==="
	docker build --rm -f docker/Dockerfile --tag midebian docker/
	docker build --rm -f docker/router/Dockerfile --tag midebian-router docker/router
	docker build --rm -f docker/jump/Dockerfile --tag midebian-jump docker/jump
	docker build --rm -f docker/work/Dockerfile --tag midebian-work docker/work
	docker build --rm -f src/Dockerfile --tag midebian-mydb src/

# Crear redes Docker personalizadas
network:
	@echo "=== Creando redes Docker ==="
	-docker network create -d bridge --subnet $(NET_DMZ) dmz
	-docker network create -d bridge --subnet $(NET_SRV) srv
	-docker network create -d bridge --subnet $(NET_DEV) dev

# Detener y eliminar contenedores y redes
remove:
	@echo "=== Limpiando escenario ==="
	-docker stop router work jump mydb-auth mydb-doc mydb-broker
	-docker network rm dmz srv dev

clean:
	find . -name "*~" -delete
	rm -rf certs/