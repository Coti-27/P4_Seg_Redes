# How to use these files

The provided `Makefile` has the following rules:

- `build`: create the base container image and the container images for
    `router`, `jump` and `work` machines.
- network: create the Docker networks `dmz` and `dev` using their
    respective subnets.
- containers: run the containers `router`, `jump` and `work`, adding them
    to the expected networks using their expected IP addresses.
- remove: stop the containers and remove the networks.
- clean: used to remove temporary files from the project.

To build and start all the services and the networks, you must use:

```
make containers
```

## Connecting to the SSH servers

As defined in the laboratory definition:

- All the accesses should be done using `jump` as "jump machine".
- There are only two users: `dev` and `op`.
- The users must only login in `work` machine.
- The `dev` user cannot access to any other machine.
- The `op` user can access to all the machines, but always running SSH
    from `work`.
- No server can be accessed using passwords, a pair of private-public
    key should be used.
- The files `op_key` and `op_key.pub` contains the private and public key
    for the user `op`.
- The files `dev_key` and `dev_key.pub` contains the private and
    public key for the user `dev`.
