# Práctica 4

Los objetivos de esta práctica son los siguientes:

- Entender e implementar un sistema distribuido no trivial con
  diferentes usuarios y niveles de acceso.
- Entender e implementar mecanismos de protección frente a intrusos.
- Entender e implementar mecanismos de detección de intrusos.
- Entender e implementar mecanismos de *logging* y auditoría.

## Enunciado

En esta práctica vamos a implementar un sistema distribuido basándonos
en la práctica 3, que haga uso de los mecanismos de seguridad que hemos
visto en teoría. Este sistema distribuido tiene dos componentes que se
describen a continuación.

### Servicio de base de datos

Nuestro servicio de base de datos del entregable 3 de laboratorio debe
reestructurarse de manera que pueda escalar para ser un servicio en la nube
y que exista personal que se encargue de su mantenimiento. Para ello,
la aplicación se dividirá en tres partes:

- `mydb-auth`: un servicio de autenticación que implementa todo lo
  relacionado con la autenticación y autorización de usuarios.

- `mydb-doc`: un servicio de almacenamiento que implementa todo lo
  relacionado con la gestión de los documentos almacenados.

- `mydb-broker`: un servicio que recibe las peticiones de los usuarios y
  redirige las llamadas a `mydb-auth` o a `mydb-doc` dependiendo
  de qué petición se trate. De esta forma:

  - `/version` la atiende el propio `mydb-broker`.

  - `/login` y `/signup` las redirigirá a `mydb-auth`.

  - El resto las redirige a `mydb-doc`.

#### Requisitos

Como requisitos de implementación del servicio de base de datos se
encuentran los siguientes:

- Cada nuevo componente tiene que estar en su propio nodo de red.
- Cada nuevo componente debe comunicarse con el resto utilizando una
  API REST.
- La comunicación de todos los componentes debe hacerse por **HTTPS**.
- Los certificados utilizados para la comunicación HTTPS deben estar
  firmados por una entidad certificadora válida.
- Toda petición de usuario debe pasar por el `mydb-broker` y este debe
  proporcionar exactamente la misma API que la definida en la práctica 3.
- Si es necesario, se pueden implementar nuevos *endpoints* en `mydb-auth`
  o en `mydb-doc`, pero no deben ser accesibles por los clientes
  externos.
- Las pruebas *end to end* y los clientes creados en la práctica 3 deben
  funcionar exactamente igual, sin ningún tipo de modificación.
- Se debe proporcionar un mecanismo automático (script, Makefile,
  etc.) que:
  - Cree todos los recursos necesarios.
  - Arranque todos los nodos del sistema.
  - Pare el sistema y destruya todo lo construido.
  - Ejecute pruebas automáticas.

### Acceso SSH al personal

Además, se debe gestionar el acceso SSH del personal en todas las
máquinas. Hay dos usuarios:

- `dev` es un usuario desarrollador que solo tiene acceso a una
  máquina de trabajo que llamaremos `work`. Este usuario *no* tiene
  acceso a `sudo`. El *único* nodo al que tiene acceso es `work`.

- `op` es un usuario operador que tiene acceso a *todas* las máquinas
  del sistema y que, además, puede ejecutar `sudo` *sin necesidad de
  introducir ninguna clave*.

#### Requisitos

Como requisitos de implementación del acceso SSH del personal se
encuentran los siguientes:

- El acceso de `root` por SSH debe estar deshabilitado.
- Solo se permite el acceso utilizando cifrado asimétrico (clave
  pública/privada de SSH).
- El personal `dev` tiene a su disposición la máquina `work` a la que
  *únicamente* puede llegar a través de un nodo de salto (*jump
  host*) llamado `jump`.
- El personal `op` puede acceder a cualquier máquina. Sin embargo,
  solo puede hacerlo desde la máquina `work`, a la cual debe acceder
  previamente usando `jump` como intermediario. Por ejemplo, si
  `op` quiere acceder al servidor de `mydb-auth`, primero debería acceder a
  `work` y después saltar a dicho servidor.
- En la máquina `jump` existen los usuarios `op` y `jump`. Sin
  embargo, solo `jump` puede usarse desde el exterior. Por ello, tanto
  los usuarios `dev` como `op` tienen que usar el usuario `jump` para
  poder iniciar el primer salto al sistema. El usuario `op` debe poder
  acceder a esta máquina también, pero nunca directamente desde el exterior;
  siempre saltando desde la máquina `work`.

## Política de seguridad de la red

- *Cada nodo* implementará un cortafuegos utilizando `iptables`.
- Las políticas por defecto de las *chains* para la tabla *filter* deben ser:
  - `INPUT` → `DROP`.
  - `FORWARD` → `DROP`.
  - `OUTPUT` → `ACCEPT`.

- ICMP está permitido en todas las direcciones.
- Todos los nodos deben ser capaces de actualizarse desde los
  repositorios de Debian, por lo que debe permitirse el tráfico de los protocolos
  involucrados.
- HTTPS está permitido en todos los nodos.
- Se definen tres redes diferentes:

  - `dmz`: la red donde se ubicarán los servicios que tienen que
    ser contactados y accesibles desde el exterior (`mydb-broker` y el
    servidor SSH de `jump`).
  - `srv`: la red donde se ubicarán los nodos que ejecutan los servicios
    `mydb-auth` y `mydb-doc`.

  - `dev`: la red donde se ubicarán los servicios para el personal. En
    este caso, el nodo `work`.

- En el esquema de red se definen los rangos y las IP para cada uno
  de los nodos y las redes que se deben implementar para la práctica.

  ![Esquema de red](diagrama.png)

- Todo el tráfico de entrada y de salida va por el host.

- Desde el host *solo* se puede acceder a los nodos a través del
  `router`. Aunque `docker` permite acceder a cada uno de ellos
  directamente a través de su IP, se debe *inhabilitar* esta opción
  en los cortafuegos.

- Todos los nodos deben tener activo el sistema de *logs* estándar `rsyslog`.

## ¿Qué se pide?

1. Implementar el sistema distribuido descrito anteriormente
  utilizando contenedores Docker.

    - Se proporcionará un `Makefile` que tendrá cuatro objetivos:
      - `build`: creará todas las imágenes y redes necesarias.
      - `containers`: lanzará todos los contenedores en el orden adecuado.
      - `remove`: parará y borrará todos los contenedores en marcha y
        eliminará todas las redes creadas.
      - `run-tests`: ejecutará una batería de pruebas que ejercite toda
        la API. Las pruebas pueden implementarse en Bash o en Python.

1. `README.md` o `README.pdf` explicando brevemente el proyecto,
  cómo instalarlo y cómo ejecutarlo. Debe contener las instrucciones
  necesarias para que cualquier profesional, sin necesidad de conocer
  cómo está implementado, pueda ejecutarlo localmente sin problemas.

Las prácticas entregadas se probarán con `curl` y la librería `requests`
de Python 3.13 para su evaluación mediante pruebas automáticas,
por lo que es muy importante implementar la API tal y como se especifica.
Además, se examinarán las reglas definidas en `iptables`, los permisos de los
archivos y otros aspectos que influyen en la seguridad del sistema
distribuido.

## ¿Qué se valora?

1. El grado de automatización en el despliegue y la configuración de los
  contenedores.

1. La claridad y estructuración del código de forma que sea fácil de
  seguir y de leer.

1. La estructura del directorio en cuanto a ficheros de configuración
  y *scripts* de generación de imágenes de contenedor.

1. Extras que subirán la nota:

    - En `iptables`, definir como política por defecto de `OUTPUT` `DROP`
      en vez de `ACCEPT`.
    - Instalación y configuración de `fail2ban` en el caso de múltiples
      intentos fallidos de *login* al servicio durante un periodo de tiempo.
    - Instalación y configuración de un sistema de detección de intrusos
      (`snort`, `tripwire`, etc.).
    - Centralización de los *logs* generados por `rsyslog`. Esto se puede
      conseguir configurando todos los servicios `rsyslog` de cada máquina
      de forma que envíen los mensajes a un nodo en la red `dev`
      (por ejemplo, un nodo llamado `logs`).
    - Habilitar `auditd` en cualquiera de los nodos, especialmente aquellos
      más expuestos a la interacción manual de los usuarios.
    - Cualquier otra propuesta acordada con el profesor.

## Método de entrega

La práctica se entregará a través de la plataforma GitHub Classroom en la tarea
creada para tal efecto. Cualquier entrega fuera de ese sistema será desestimada.
