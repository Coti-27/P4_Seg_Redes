[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/eIEHWroe)
# Network Security Laboratory — Deliverable 4

This repository contains the minimal setup to start working on the assignment.

## How to use this repository

Welcome to the base repository for Lab 4. This repository provides:

- A `src` directory with a skeleton for the requested service:
  - Minimal Go package definition.
  - A `Makefile` with some helpers to build the service.

- A `deployment` directory with the needed files to create a deployment of the
  requested network.
  - A set of `Dockerfile` files and the configuration files needed to build the base image,
    and some of the required nodes (`router`, `jump` and `work`).
  - A `Makefile` to build the images and launch a deployment.

- The statement with the requirements of this lab in the `doc` directory.

After you understand every piece of code provided in this repository, you should "make this
repository yours": that means updating this `README.md`.

Even if you use the provided helpers, explain here how your software is built and executed.

If you decided to use a different library in the deliverable 3, it is not needed to explain
the chosen one here again.

## Helpers

- `src/Makefile`: it includes the build instruction for the main program. If you add packages
  to the solution or rename the existing one, update the Makefile accordingly.

- `deployment/Makefile`: it includes the image build process and deployment instructions
  for the nodes `router`, `jump` and `work` as an example.

## Helpers for certificates

The `src/Makefile` still includes the helpers to generate self-signed certificates.
You can use it during the development process, but remember that it is needed to use
a real certificate, signed by a real CA.

The code in `cmd/mydb/main.go` assumes the certificates are in specific locations. As the
services would be deployed in different machines, it would be a good option to make those
paths configurable.

**DISCLAIMER**

The certificate generation and installation commands assume a
**Debian GNU/Linux–based distribution**. If you use a different OS, adapt the commands
accordingly, since some commands may differ.
