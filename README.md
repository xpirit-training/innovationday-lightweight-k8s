# Lightweight k8s

## Use Case

A Customer runs a self-developed backend service application together with a database using docker-compose on an on-premise VM.

We want to (automatically) migrate this setup to k8s.

Requirements/boundaries

- stay on-prem
- do not change the environment as it is managed by an internal IT departement at the customer site
- admin rights on the VM
- linux (ubuntu)

## Goals

1. Comparison of lightweight k8s distributions (see [table](#comparison-of-lightweight-k8s-distributions)).
2. Load test and compare with / without k8s
3. Automatically setup ligthweight k8s on a linux VM
4. (Automatically) Migrate a sample docker-compose workflow

## Comparison of lightweight k8s distributions

| Distribution               | k3s    | k3d    | kind | microk8s | k0     |
| -------------------------- | ------ | ------ | ---- | -------- | ------ |
| Team Member                | Thomas | Stefan | Till | Marius   | Julian |
| Setup & Configuration      |        |        |      |          |        |
| Required Container Runtime |        |        |      |          |        |
| Compatibility              |        |        |      |          |        |
| Scalability                |        |        |      |          |        |
| Security                   |        |        |      |          |        |
| Performance                |        |        |      |          |        |
| Prod Ready                 |        |        |      |          |        |

## Resources
- https://github.com/docker/awesome-compose
- https://github.com/grafana/k6
- https://kompose.io/

- [k0](https://k0sproject.io)
- [k3d](https://k3d.io)
- [k3s]()
- [kind]()
- [microk8s]