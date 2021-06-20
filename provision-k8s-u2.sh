#!/bin/bash
set -eux

ip_address="$1"; shift

export API_ADDR="${ip_address}"
export DNS_DOMAIN="cluster2.local"
export POD_NET="10.2.0.0/16"
export SRV_NET="100.2.0.0/16"

kubeadm init --pod-network-cidr ${POD_NET} --service-cidr ${SRV_NET} --service-dns-domain "${DNS_DOMAIN}" --apiserver-advertise-address ${API_ADDR}
mkdir -p /root/.kube || true
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=v1.20.1&env.IPALLOC_RANGE=10.2.0.0/16"
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl label node u2 submariner.io/gateway=true
kubectl create ns syntropy-operator || true
helm repo add leogsilva https://leogsilva.github.io/charts/ || true
helm install syntropy-agent leogsilva/syntropy-agent -f /home/vagrant/values.yaml -n syntropy-operator 

# subctl join broker-info.subm --cable-driver wireguard --repository docker.io/leogsilva --version dev --clusterid cluster2 --natt=false
