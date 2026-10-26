#!/bin/bash
set -euo pipefail

echo "[4/5] Creating namespaces..."
kubectl apply -f manifests/ingress/namespace.yaml
kubectl apply -f manifests/istio/namespace.yaml

echo "Deploying httpbin service to namespace 'lab-ingress'..."
kubectl apply -f manifests/app/httpbin.yaml -n lab-ingress

echo "Deploying httpbin service to namespace 'lab-istio' (with Istio sidecar injection)..."
kubectl apply -f manifests/app/httpbin.yaml -n lab-istio

echo "Applying Ingress-NGINX routing rule (app.local)..."
kubectl apply -f manifests/ingress/ingress.yaml

echo "Applying Istio Gateway and VirtualService (app.istio.local)..."
kubectl apply -f manifests/istio/gateway.yaml
kubectl apply -f manifests/istio/virtualservice.yaml

echo "Applying migration bridge for dual-controller local routing..."
kubectl apply -f manifests/istio/migration-bridge.yaml

echo "Waiting for httpbin pods to reach Ready state..."
kubectl wait --namespace lab-ingress \
  --for=condition=ready pod \
  --selector=app=httpbin \
  --timeout=120s

kubectl wait --namespace lab-istio \
  --for=condition=ready pod \
  --selector=app=httpbin \
  --timeout=120s

echo "All workloads, Ingress rules, and Istio Gateway routes are deployed and ready."
