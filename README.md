# Ingress to Istio Gateway Migration

A self-contained Kubernetes project demonstrating traffic migration from an Ingress-NGINX controller to an Istio Gateway running on an Envoy proxy. The project deploys both controllers side by side in a local multi-controller topology, executes identical HTTP workloads behind each entry point, and proves the active edge controller via HTTP response server signatures.

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

## Prerequisites

Ensure the following tools are installed on your workstation:

- **Docker Desktop** (or Docker Engine with daemon active)
- **kind** (`v0.20.0` or higher)
- **kubectl** (`v1.28.0` or higher)
- **curl**
- **jq**

## Run in VS Code

This repository is pre-configured for direct execution inside Visual Studio Code.

1. **Clone the repository and open the root folder:**
   ```bash
   git clone <REPO_URL>
   cd ingress-to-istio-gateway-migration
   code .
   ```

2. **Run via VS Code Integrated Terminal:**
   Open the integrated terminal (`Ctrl+`` or `Cmd+``) and run:
   ```bash
   make up
   ```

3. **Run via VS Code Task Menu:**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS).
   - Select **Tasks: Run Task**.
   - Select **Migration: Up**.

The automated sequence will create the cluster, install both controllers, deploy the workloads, and configure routes in under 3 minutes.

## How to Validate

### Automated Validation

Run the test suite via the Makefile:
```bash
make validate
```
Or execute the VS Code Task **Migration: Validate**.

### Manual Validation

Send HTTP GET requests to `localhost:80` using different virtual host headers:

1. **Query the Ingress-NGINX controller:**
   ```bash
   curl -sI -H "Host: app.local" http://localhost/get | grep -i '^server:'
   ```
   **Expected Response:**
   ```http
   Server: nginx
   ```

2. **Query the Istio Ingress Gateway:**
   ```bash
   curl -sI -H "Host: app.istio.local" http://localhost/get | grep -i '^server:'
   ```
   **Expected Response:**
   ```http
   server: istio-envoy
   ```

The test script inspects these headers with `jq` and exits with return code `0` when both signatures are verified.

## Why No Port-Forward or Tunnel Is Needed

Standard local Kubernetes setups often require `kubectl port-forward` processes or `minikube tunnel` daemons to expose cluster networking to host ports.

This project avoids background forwarders through `kind-config.yaml`:
The Docker container running the control plane maps host port `80` directly to container port `80`. The Ingress-NGINX controller binds to the node's port `80`. During the migration phase, traffic addressed to `app.istio.local` is bridged into the Istio Gateway's Envoy listener. Both controllers are reachable directly at `http://localhost/` via hostname resolution.

## Architectural Proof Points

| Dimension | Legacy Ingress-NGINX | Modern Istio Gateway |
| :--- | :--- | :--- |
| **Specification** | Monolithic `Ingress` object | Decoupled `Gateway` + `VirtualService` |
| **Proxy Engine** | NGINX | Envoy |
| **Response Header** | `Server: nginx` | `Server: istio-envoy` |
| **Sidecar Mesh** | External to application pods | Automatic mTLS sidecar injection |
| **Traffic Control** | Regex annotations (`rewrite-target`) | Native URI matching, subsets, and weights |

The `Server` header serves as cryptographic runtime proof: the application pod (`httpbin`) remains identical in both configurations, but the gateway proxy terminating external traffic differs.

## Cleanup

To completely remove the cluster and reset local networking:

```bash
make down
```

Or trigger **Tasks: Run Task** → **Migration: Down** from VS Code.
