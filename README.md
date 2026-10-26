# Ingress to Istio Gateway Migration

A self-contained Kubernetes project demonstrating traffic migration from an Ingress-NGINX controller to an Istio Gateway running on an Envoy proxy. The project deploys both controllers side by side in a local multi-controller topology, executes identical HTTP workloads behind each entry point, and proves the active edge controller via HTTP response server signatures.

---

## What This Project Does

In Kubernetes, external traffic routing typically starts with standard `Ingress` resources backed by an NGINX controller. As platform requirements evolve toward zero-trust security, advanced traffic splitting, and circuit breaking, platform engineering teams migrate routing to the Istio service mesh.

This repository provides an automated, local migration environment demonstrating the two paradigms:

1. **Ingress-NGINX Pattern (`app.local`):**
   - Standard Kubernetes `networking.k8s.io/v1` `Ingress` resource.
   - Evaluated by the Ingress-NGINX controller daemon.
   - Forwards directly to application endpoints.
   - Emits the HTTP response header `Server: nginx`.

2. **Istio Gateway Pattern (`app.istio.local`):**
   - Decoupled `networking.istio.io/v1alpha3` `Gateway` (layer 4-6 port/host definitions).
   - Decoupled `VirtualService` (layer 7 routing, retries, and URI matching).
   - Evaluated by the `istio-ingressgateway` deployment running Envoy.
   - Emits the HTTP response header `Server: istio-envoy`.

---

## Prerequisites & Environment Requirements

Ensure the following tools and configurations are in place before starting:

* **Host System / Shell:** Linux or **WSL 2 (Ubuntu 20.04+)** on Windows. Native Windows PowerShell is not supported for script execution because the Makefile targets execute POSIX shell scripts (`.sh`).
* **Docker Desktop:** Running with Docker Engine active.
  * On Windows, ensure Docker Desktop uses the **WSL 2 based engine**.
  * Enable WSL integration for your distro: **Docker Desktop > Settings > Resources > WSL Integration > Turn ON for Ubuntu**.
* **Required CLI Utilities** (installed inside your Linux/WSL environment):
  * `kind` (`v0.24.0` or higher)
  * `kubectl` (`v1.30.0` or higher)
  * `make` (`v4.0` or higher)
  * `dos2unix`
  * `curl`
  * `jq`

---

## Environment Setup (WSL 2 / Ubuntu)

### 1. Install Dependencies
```bash
sudo apt update && sudo apt install -y make dos2unix curl jq

# Install kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind [https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64](https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64)
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "[https://dl.k8s.io/release/$(curl](https://dl.k8s.io/release/$(curl) -L -s [https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl](https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl)"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
