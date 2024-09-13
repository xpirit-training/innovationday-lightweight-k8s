sudo kind delete cluster -n innoday
sudo kind create cluster -n innoday --config kind/config-with-port-mappings.yaml
