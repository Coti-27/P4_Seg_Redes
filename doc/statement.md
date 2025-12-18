# Practice 4

The objectives of this practice are the following:

- Understand and implement a non-trivial distributed system with
  different users and access levels.
- Understand and implement mechanisms for protecting against intruders.
- Understand and implement mechanisms for detecting intruders.
- Understand and implement *logging* and auditing mechanisms.

## Task Description

In this practice, we will implement a distributed system based on
Practice 3, making use of the security mechanisms studied in the lectures.
This distributed system has two components, described below.

### Database Service

Our database service from Laboratory Deliverable 3 must be
restructured so that it can scale as a cloud service
and so that dedicated personnel can maintain it. To this end,
the application will be divided into three parts:

- `mydb-auth`: an authentication service that implements everything
  related to user authentication and authorization.

- `mydb-doc`: a storage service that implements everything related to
  managing stored documents.

- `mydb-broker`: a service that receives user requests and
  forwards calls to either `mydb-auth` or `mydb-doc` depending on
  the request. Specifically:

  - `/version` is handled directly by `mydb-broker`.

  - `/login` and `/signup` are forwarded to `mydb-auth`.

  - All other requests are forwarded to `mydb-doc`.

#### Requirements

The implementation requirements for the database service are as follows:

- Each new component must run on its own network node.
- Each new component must communicate with the others using a
  REST API.
- Communication between all components must use **HTTPS**.
- The certificates used for HTTPS communication must be
  signed by a valid certificate authority.
- Every user request must go through `mydb-broker`, which must
  provide exactly the same API defined in Practice 3.
- If necessary, new endpoints may be implemented in `mydb-auth`
  or `mydb-doc`, but they must not be accessible by external clients.
- The end-to-end tests and the clients created in Practice 3 must work
  exactly the same, without any modification.
- An automatic mechanism (script, Makefile, etc.) must be provided that:
  - Creates all required resources.
  - Starts all system nodes.
  - Stops the system and destroys everything created.
  - Runs automatic tests.

### SSH Access for Staff

Additionally, SSH access for staff must be configured on all
machines. There are two users:

- `dev` is a developer who only has access to a workstation
  called `work`. This user does *not* have access to `sudo`. The
  *only* node they can access is `work`.

- `op` is an operator who has access to *all* machines
  in the system and can execute `sudo` *without needing to
  enter any password*.

#### Requirements

The requirements for staff SSH access are as follows:

- SSH access for `root` must be disabled.
- Access is only allowed using asymmetric encryption (SSH
  public/private key).
- The `dev` user can access the `work` machine, which they can reach
  *only* through a jump node (*jump host*) called `jump`.
- The `op` user can access any machine. However, they can do so
  only from the `work` machine, which must first be accessed
  through `jump`. For example, if `op` wants to access the
  `mydb-auth` server, they must first access `work`, then jump to the server.
- The `jump` machine contains the users `op` and `jump`. However,
  only `jump` may be used from outside the system. Therefore, both
  the `dev` and `op` users must use the `jump` user to initiate the
  first jump. The `op` user must also be able to access this machine,
  but never directly from outside; always by jumping from `work`.

## Network Security Policy

- *Each node* will implement a firewall using `iptables`.
- The default policies for the *chains* in the *filter* table must be:
  - `INPUT` → `DROP`
  - `FORWARD` → `DROP`
  - `OUTPUT` → `ACCEPT`

- ICMP traffic is allowed in all directions.
- All nodes must be able to update from Debian repositories,
  so required protocol traffic must be allowed.
- HTTPS is allowed on all nodes.
- Three different networks are defined:

  - `dmz`: the network where services that must be reachable
    from the outside will be located (`mydb-broker` and the
    SSH server of `jump`).
  - `srv`: the network where the nodes running
    `mydb-auth` and `mydb-doc` will be located.

  - `dev`: the network where staff-related services will be located.
    In this case, the `work` node.

- The network diagram defines the ranges and IP addresses
  for each node and network that must be implemented for the practice.

  ![Network Diagram](diagrama.png)

- All inbound and outbound traffic goes through the host.

- From the host, access to nodes is allowed *only* through the
  `router`. Although Docker allows direct access to nodes via their IP,
  this option must be *disabled* using firewall rules.

- All nodes must have the standard logging service `rsyslog` enabled.

## What is required?

1. Implement the distributed system described above
   using Docker containers.

   - A `Makefile` must be provided with four targets:
     - `build`: creates all required images and networks.
     - `containers`: launches all containers in the correct order.
     - `remove`: stops and removes all running containers and
       deletes all created networks.
     - `run-tests`: runs a test suite that exercises the entire API.
       Tests may be implemented in Bash or Python.

1. A `README.md` or `README.pdf` briefly explaining the project,
   how to install it, and how to run it. It must contain
   all instructions necessary for any professional to run the system
   locally without needing to understand its internal implementation.

Submitted practices will be tested with `curl` and Python 3.13’s
`requests` library for automatic evaluation, so implementing the API
exactly as specified is crucial. Additionally, firewall rules (`iptables`),
file permissions, and other security-related aspects of the distributed
system will be inspected.

## Evaluation Criteria

1. The degree of automation in the deployment and configuration
   of containers.

1. Clarity and structure of the code, ensuring it is easy to
   follow and read.

1. Organization of the directory structure, including configuration
   files and container build scripts.

1. Bonus features that may increase the grade:

  - Setting the default `iptables` `OUTPUT` policy to `DROP`
    instead of `ACCEPT`.
  - Installing and configuring `fail2ban` in the case of multiple
    failed login attempts over a period of time.
  - Installing and configuring an intrusion detection system
    (`snort`, `tripwire`, etc.).
  - Centralizing logs generated by `rsyslog`. This can be achieved by
    configuring all `rsyslog` services to send logs to a node in the
    `dev` network (e.g., a node named `logs`).
  - Enabling `auditd` on any node, especially those exposed to
    manual user interaction.
  - Any additional proposal approved by the instructor.

## Submission Method

The practice must be submitted through the GitHub Classroom assignment
created for this purpose. Any submission outside that system will be rejected.
