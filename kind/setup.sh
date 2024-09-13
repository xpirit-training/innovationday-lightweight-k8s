# Delete the old cluster
sudo kind delete cluster -n innoday

# Create a new cluster with the config file (ingress + port mappings)
sudo kind create cluster -n innoday --config kind/config-with-port-mappings.yaml

# Create a namespace
sudo kubectl create ns innoday

# Set the namespace as default
sudo kubectl config set-context --current --namespace innoday

# Apply the manifests for wordpress and mysql
sudo kubectl apply -f manifests

# Apply the ingress controller
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml