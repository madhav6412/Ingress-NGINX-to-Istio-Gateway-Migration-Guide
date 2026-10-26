#!/bin/bash
set -euo pipefail

CLUSTER_NAME="ingress-istio-migration"

echo "Tearing down kind cluster '${CLUSTER_NAME}'..."
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind delete cluster --name "${CLUSTER_NAME}"
  echo "Kind cluster deleted."
else
  echo "Cluster '${CLUSTER_NAME}' does not exist. Nothing to clean."
fi

rm -rf .bin
echo "Environment cleanup complete."
