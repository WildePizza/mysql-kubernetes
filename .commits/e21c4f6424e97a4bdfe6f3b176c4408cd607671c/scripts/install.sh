#!/bin/bash

sha=$1
password=$2
using_nfs=$3

wait_until_ready() {
  url=$1
  substring1="The requested URL returned error"
  substring2="Could not resolve host: raw.githubusercontent.com"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring1 || $output =~ $substring2 ]]; then
    sleep 1
    wait_until_ready
  fi
}
generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  echo $(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}

if [ ! -n "$password" ]; then
  password=$(generate_secure_password)
  echo "Generated root password: $password"
fi

sudo mkdir /var/lib/mysql
wait_until_ready https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/$sha/scripts/deinstall.sh
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/$sha/scripts/deinstall.sh | bash -s
kubectl create secret generic mysql-root-pass --from-literal=password=$password
if [ "$using_nfs" = true ]; then
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: $(hostname -I | awk {'print $1'})
    path: /exports/documents
  persistentVolumeReclaimPolicy: Recycle
OEF
else
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: mysql-pv-claim
  storageClassName: local-storage
  local:
    path: "/mnt/data/mysql"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: In
          values:
          - "true"
OEF
fi
echo "Installing MySQL"
wait_until_ready https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/yaml/mysql.yaml
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/yaml/mysql.yaml
echo "Waiting for MySQL to be ready..." >&2
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    sleep 1
done
echo "Installing PhpMyAdmin"
wait_until_ready https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/yaml/phpmyadmin.yaml
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/yaml/phpmyadmin.yaml