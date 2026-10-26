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


2. Configure Docker Daemon Permissions
Ensure your WSL non-root user can interact with the Docker daemon without permission denial:

Bash
sudo usermod -aG docker $USER
newgrp docker
# Or switch to root: sudo su
3. Normalize Line Endings (CRLF to LF)
If this repository is checked out or mounted from Windows storage paths (/mnt/c/...), Windows carriage returns (CRLF) will trigger shell execution failures. Convert all scripts and the Makefile to Unix format:

Bash
dos2unix scripts/*.sh Makefile
chmod +x scripts/*.sh
Run in VS Code
This repository is pre-configured for direct execution inside Visual Studio Code.

Clone the repository and open the root folder:

Bash
git clone <REPO_URL>
cd Ingress-NGINX-to-Istio-Gateway-Migration-Guide
code .
Run via VS Code Integrated Terminal (WSL):
Open the terminal inside WSL and run:

Bash
make up
Run via VS Code Task Menu:

Press Ctrl+Shift+P (or Cmd+Shift+P on macOS).

Select Tasks: Run Task.

Select Migration: Up.

The automated sequence provisions the Kind cluster with host port mappings, installs Ingress-NGINX and Istio, deploys the httpbin service in each namespace, and configures the local routing bridge in under 3 minutes.

How to Validate
Automated Validation
Run the test suite via the Makefile:

Bash
make validate
Or execute the VS Code Task Migration: Validate.

Manual Validation
Send HTTP GET requests to localhost:80 using different virtual host headers:

Query the Ingress-NGINX controller:

Bash
curl -sI -H "Host: app.local" http://localhost/get | grep -i '^server:'
Expected Response:

HTTP
Server: nginx
Query the Istio Ingress Gateway:

Bash
curl -sI -H "Host: app.istio.local" http://localhost/get | grep -i '^server:'
Expected Response:

HTTP
server: istio-envoy
The test script inspects these headers with jq and exits with return code 0 when both signatures are verified.

Why No Port-Forward or Tunnel Is Needed
Standard local Kubernetes setups often require kubectl port-forward processes or minikube tunnel daemons to expose cluster networking to host ports.

This project avoids background forwarders through kind-config.yaml:
The Docker container running the control plane maps host port 80 directly to container port 80. The Ingress-NGINX controller binds to the node's port 80. During the migration phase, traffic addressed to app.istio.local is bridged into the Istio Gateway's Envoy listener. Both controllers are reachable directly at http://localhost/ via hostname resolution.
