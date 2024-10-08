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

| Distribution               | k3s                         | k3d    | kind                                                 | microk8s                                                                            | k0     |
| -------------------------- | --------------------------- | ------ | ---------------------------------------------------- | ----------------------------------------------------------------------------------- | ------ |
| Team Member                | Thomas                      | Stefan | Till                                                 | Marius                                                                              | Julian |
| Setup & Configuration      | Couple commands, quite easy |        | see [here](#kind)                                    | snap, few lines, lots of ready to use addons (dns,ingress,hostpath-storage,metallb) |        |
| Documentation              | Lacking at ingress          |        | very good                                            | sehr gut                                                                            |        |
| Required Container Runtime | cri compliant               |        | docker, podman or nerdctl                            | containerd (included)                                                               |        |
| Ingress                    | Difficult. Setup seems old  |        | easy to setup with prepared nginx-ingress controller | easy to setup (addon), traffic routed to nginx using metallb (addon)                |        |
| Prerequisites              | nA                          |        | go (>=1.16), docker, podman or nerdctl               | linux with snapd                                                                    |        |
| Scalability                | Easy join command           |        | possible, but only when creating the cluster         | easy, new nodes can be added with simple join commands                              |        |
| Security                   |                             |        | tbd                                                  |                                                                                     |        |
| Performance                | Worst                       | Best   | tbd                                                  |                                                                                     | Mid    |
| Prod Ready                 | :x:                         |        | :heavy_check_mark:                                   | :heavy_check_mark:                                                                  |        |

## Resources

- https://github.com/docker/awesome-compose
- https://github.com/grafana/k6
- https://kompose.io/

- [k3s](https://k3s.io)
- [k3d](https://k3d.io)
- [kind](https://kind.sigs.k8s.io)
- [microk8s](https://microk8s.io)
- [k0](https://k0sproject.io)

- [setup docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)

## Our Setup

- compose application: [wordpress](https://github.com/docker/awesome-compose/tree/master/official-documentation-samples/wordpress)
- [resource group](https://portal.azure.com/#@xebia.com/resource/subscriptions/27e474a0-381c-4785-9c7e-b8faf95dc64c/resourceGroups/rg-innoday-1309/overview)
- vm
  - base system ubuntu 24.04 LTS
  - x64
  - D4s_v3
  - trusted launch
  - premium SSD
  - 30GB
  - 1 vm per distro
  - 1 vm without any distro, only with docker
- region north europe
- zone 1

## Steps

1. Setup k8s
2. Deploy application
3. Setup Ingress
4. Load Test

### Deploy application

The application was konverted from compose using kompose.

Afterwards the manifests were modified:
- add nodeport service (only necessary if not using ingress)
- add loadbalancer service (if metallb used)
- add ingress

```bash
# clone repo
git clone https://github.com/xpirit-training/innovationday-lightweight-k8s.git
cd innovationday-lightweight-k8s

# create ns
kubectl create ns innoday

# change the context to avoid mention the innoday namespace
kubectl config set-context --current --namespace innoday

# deploy
kubectl apply -f manifests

# check deployment
kubectl get pods
```

### Test access

1. Get Nodeport: `kubectl -n innoday get svc wordpress -o jsonpath='{.spec.ports[0].nodePort}'`
2. Open this port in your azure network security group
3. Access your application at `http://<machine ip>:<nodeport>`

## Doc-Space

### k3s

### k3d
- docker to be able to use k3d at all --> Note: k3d v5.x.x requires at least Docker v20.10.5 (runc >= v1.0.0-rc93) to work properly (see #807)
- kubectl to interact with the Kubernetes cluster

#### Docker Installation
Docker provides a convenience script to install Docker into development environments non-interactively. 
`curl -fsSL https://get.docker.com -o get-docker.sh`
`sudo sh ./get-docker.sh`

#### Kubectl Installation
Download the latest release with the command:
`curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`
`sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl`

#### k3d Installation
`curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`

#### k3d Configuration
Create a cluster named 'innodaycluster' with just a single server node:
`k3d cluster create innodaycluster`

Use the new cluster with kubectl, e.g.:
`kubectl get nodes`
`k3d kubeconfig get innodaycluster`

Create a cluster, mapping the ingress port 80 to localhost:8081
`k3d cluster create --api-port 6550 -p "8081:80@loadbalancer" --agents 2`

`--api-port 6550` is not required for the example to work.
It is used to have k3s’s API-Server listening on `port 6550` with that port mapped to the host system.
the port-mapping construct `8081:80@loadbalancer` means:
map port `8081` from the host to port `80` on the container which matches the nodefilter loadbalancer.
the loadbalancer nodefilter matches only the serverlb that’s deployed in front of a cluster’s server nodes
all ports exposed on the serverlb will be proxied to the same ports on all server nodes in the cluster

Copy & Paste yml files for deployment of the wordpress application and do deployment:
- Database
`vim db.yml`
`kubectl apply -f db.yml`

- Wordpress
`vim wordpress.yml`
`kubectl apply -f wordpress.yml`

- Expose
`vim expose.yml`
`kubectl apply -f expose.yml`
`kubectl get pods -w`
`k3d cluster edit innodaycluster --port-add "30000-32767:30000-32767@server:0"`


### kind
#### General
Kind (Kubernetes IN Docker) is a k8s solution which works on docker (containerd). It is part of the K8s project under the CNCF.

#### setup
- [install](https://kind.sigs.k8s.io)
- requires go & docker to be installed on the machine
- Install go: `sudo snap install go --classic`
- Install docker: `sudo snap install docker`
- Install kubectl: `sudo snap install kubectl --classic`
- Install from binaries:
```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### create a cluster
- Create a cluster with: `kind create cluster -n innoday --config kind/config-with-port-mapping.yaml`

#### deyployment
- Deploy the application using kubectl like described [here](#deploy-application)

#### Ingress
- Use the ingress-nginx controller with: `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml`

#### Complete setup & deployment steps
See [setup.sh](kind/setup.sh)

### microk8s

- [install](https://microk8s.io/docs/getting-started)
- [addons](https://microk8s.io/docs/addons)
- [http ingress](https://phoenixnap.com/kb/microk8s-ingress)

```bash
# setup
sudo snap install microk8s --classic

# join group
sudo usermod -a -G microk8s $USER
mkdir -p ~/.kube
chmod 0700 ~/.kube
su - $USER

# wait till ready
microk8s status --wait-ready

# test
microk8s kubectl get nodes

# add core-dns
microk8s enable dns

# add ingress
microk8s enable ingress

# add hostpath-storage
microk8s enable hostpath-storage

# add metallb
export MACHINE_IP=<machine ip>
microk8s enable metallb:${MACHINE_IP}-${MACHINE_IP}
```

### k0
- [docs](https://github.com/k0sproject/k0sctl#configuration-file-spec-fields)
- [install_k0] (https://docs.k0sproject.io/stable/install/)
- curl -sSLf https://get.k0s.sh | sudo sh
- k0s install controller --single
- k0s start
- k0s status
- k0s kubectl get nodes
- [install_0sctl] (https://docs.k0sproject.io/stable/k0sctl-install/)
- Install k0sctl tool
- wget https://github.com/k0sproject/k0sctl/releases/download/v0.19.0/k0sctl-linux-amd64
- cp k0sctl-linux-amd64 /usr/local/bin/k0sctl
- chmod +x /usr/local/bin/k0sctl
- Test ->  k0sctl version
- [CleanupSingleNode]
- k0s stop
- k0s reset
- [SingeNodeGuide] (https://docs.k0sproject.io/v0.9.1/k0s-single-node/)
- mkdir -p ${HOME}/.k0s
- k0s default-config | tee ${HOME}/.k0s/k0s.yaml
- sudo k0s server -c ${HOME}/.k0s/k0s.yaml --enable-worker &

sudo k0s server -c ${HOME}/.k0s/k0s.yaml --enable-worker < /dev/null &>/dev/null &

- sudo cat /var/lib/k0s/pki/admin.conf | tee ~/.k0s/kubeconfig
- sudo curl --output /usr/local/sbin/kubectl -L "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
- sudo chmod +x /usr/local/sbin/kubectl
-  cat /var/lib/k0s/pki/admin.conf | tee ~/.kube/config
- kubectl get pods --all-namespaces
