#!/bin/bash
set -euo pipefail

echo "[2/5] Deploying official Ingress-NGINX controller for kind..."

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for Ingress-NGINX controller pod to reach Ready condition..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Ingress-NGINX controller is operational."
