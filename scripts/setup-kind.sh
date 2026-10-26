#!/bin/bash
set -euo pipefail

CLUSTER_NAME="ingress-istio-migration"

echo "[1/5] Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo >&2 "Error: docker is required but not installed."; exit 1; }
command -v kind >/dev/null 2>&1 || { echo >&2 "Error: kind is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo >&2 "Error: kubectl is required but not installed."; exit 1; }

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Deleting existing cluster..."
  kind delete cluster --name "${CLUSTER_NAME}"
fi

echo "Creating kind cluster '${CLUSTER_NAME}' with host port mappings 80/443..."
kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml

kubectl cluster-info --context "kind-${CLUSTER_NAME}"
echo "Kind cluster '${CLUSTER_NAME}' created successfully."
