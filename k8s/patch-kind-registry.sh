#!/bin/sh
set -o errexit

REGISTRY_DIR="/etc/containerd/certs.d/registry.k8s.hans.io"
for node in $(kind get nodes -n $1); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."https://registry.k8s.hans.io"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF
done
