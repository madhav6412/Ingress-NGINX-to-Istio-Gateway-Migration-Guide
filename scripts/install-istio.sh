#!/bin/bash
set -euo pipefail

ISTIO_VERSION="1.24.1"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

case "${ARCH}" in
  x86_64)  ISTIO_ARCH="amd64" ;;
  aarch64|arm64) ISTIO_ARCH="arm64" ;;
  *) echo >&2 "Unsupported architecture: ${ARCH}"; exit 1 ;;
esac

BIN_DIR="$(pwd)/.bin"
mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "[3/5] Downloading istioctl v${ISTIO_VERSION} for ${OS}-${ISTIO_ARCH}..."
  TARBALL_URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-${OS}-${ISTIO_ARCH}.tar.gz"
  curl -sSL "${TARBALL_URL}" | tar -xz -C "${BIN_DIR}"
  chmod +x "${BIN_DIR}/istioctl"
fi

echo "Installing Istio using the demo profile..."
"${BIN_DIR}/istioctl" install --set profile=demo -y

echo "Waiting for istiod deployment to be available..."
kubectl wait --namespace istio-system \
  --for=condition=available deployment/istiod \
  --timeout=180s

echo "Waiting for istio-ingressgateway deployment to be available..."
kubectl wait --namespace istio-system \
  --for=condition=available deployment/istio-ingressgateway \
  --timeout=180s

echo "Istio control plane and Ingress Gateway are operational."
