#!/bin/bash
set -euo pipefail

extract_server_header() {
  local host="$1"
  local url="$2"
  local raw_header=""

  raw_header=$(curl -sI -H "Host: ${host}" "${url}" | tr -d '\r' | grep -i '^server:' | head -n 1 || true)

  if [ -z "${raw_header}" ]; then
    echo "none"
  else
    echo "${raw_header}" | awk -F': ' '{print $2}' | jq -R . -r
  fi
}

echo "=================================================="
echo " Running Ingress to Istio Traffic Validation      "
echo "=================================================="

echo -n "Probing baseline NGINX Ingress (Host: app.local)... "
NGINX_SERVER=$(extract_server_header "app.local" "http://localhost/get")
echo "${NGINX_SERVER}"

echo -n "Probing migrated Istio Gateway (Host: app.istio.local)... "
ISTIO_SERVER=$(extract_server_header "app.istio.local" "http://localhost/get")
echo "${ISTIO_SERVER}"

echo "=================================================="
echo " Validation Results Matrix                        "
echo "=================================================="
echo "Endpoint: app.local       -> Server: ${NGINX_SERVER}"
echo "Endpoint: app.istio.local -> Server: ${ISTIO_SERVER}"
echo "--------------------------------------------------"

if [[ "${NGINX_SERVER}" =~ nginx ]] && [[ "${ISTIO_SERVER}" =~ istio-envoy ]]; then
  echo "STATUS: PASS"
  echo "Traffic to 'app.local' is terminated by Ingress-NGINX."
  echo "Traffic to 'app.istio.local' is managed by Istio Envoy Gateway."
  exit 0
else
  echo "STATUS: FAIL"
  echo >&2 "Error: Expected 'nginx' for app.local and 'istio-envoy' for app.istio.local."
  exit 1
fi
