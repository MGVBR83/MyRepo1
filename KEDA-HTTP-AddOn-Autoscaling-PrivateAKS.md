# Autoscaling HTTP Workloads on Private AKS using KEDA HTTP Add-on

## 1. Purpose

This document describes how to configure event-driven autoscaling for HTTP-based workloads on a **private AKS cluster** using the **KEDA HTTP Add-on**, given the following existing setup:

1. The AKS cluster is provisioned via **Terraform**, with the **core KEDA add-on** enabled through the `workload_autoscaler_profile` block (`azurerm_kubernetes_cluster` resource).
2. **KEDA HTTP Add-on** is separately installed via **Helm** (`kedacore/http-add-on`) from the **AKS Run Command** blade in the Azure Portal, into the `keda` namespace.

---

## 2. Architecture Overview

```
                        ┌───────────────────────────────────────────┐
                        │              Private AKS Cluster            │
                        │                                             │
   Client HTTP  ──────▶ │  Ingress / Service  ──▶  keda-http-add-on  │
   Request              │                          Interceptor Proxy  │
                        │                              │              │
                        │                              ▼              │
                        │                     Buffers / queues        │
                        │                     request if scaled to 0  │
                        │                              │              │
                        │                              ▼              │
                        │                    HTTP Add-on Scaler       │
                        │                    (reports pending reqs)   │
                        │                              │              │
                        │                              ▼              │
                        │              KEDA Operator (kube-system)    │
                        │                 — from managed add-on —     │
                        │                              │              │
                        │                              ▼              │
                        │        HorizontalPodAutoscaler (HPA)        │
                        │                              │              │
                        │                              ▼              │
                        │         Target Deployment (scale 0 → N)     │
                        └───────────────────────────────────────────┘
```

**Key components:**

| Component | Role | Where it should live |
|---|---|---|
| KEDA Operator + Metrics Server | Core autoscaling engine; watches `ScaledObject`/`ScaledJob`, drives HPA | Managed add-on, `kube-system` (via Terraform) |
| KEDA HTTP Add-on — Interceptor | Reverse proxy that sits in front of the workload; queues/holds requests while the app is scaling from 0 | Installed separately via Helm, typically its own namespace (e.g. `keda-http-add-on` or `keda`) |
| KEDA HTTP Add-on — External Scaler | Watches request counts observed by the Interceptor and reports pending request metrics to KEDA core | Installed together with the Interceptor via the same Helm chart |
| `HTTPScaledObject` (CRD) | Declares which Service/Deployment to scale based on HTTP traffic | Application namespace |

---

## 3. Why the HTTP Add-on Must Be Installed Separately

Microsoft's own documentation on the AKS-managed KEDA add-on is explicit about this limitation: the HTTP Add-on is **not** installed as part of the managed KEDA extension and must be deployed independently. The managed add-on only ships **core KEDA** (operator + metrics adapter) — it does not include HTTP-based scaling capability, which is still a separate KEDA sub-project (`kedacore/http-add-on`).

---

## 4. Confirm only the AKS-managed release remains

helm list -n kube-system | grep -i keda
kubectl get pods -n kube-system | grep -i keda


**Terraform Configuration (Core KEDA via Managed Add-on):**

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-private-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aksprivate"

  private_cluster_enabled = true

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_D4s_v5"
    node_count = 3
  }

  identity {
    type = "SystemAssigned"
  }

**Enables the AKS-managed KEDA add-on (core operator + metrics server):**
  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = false
  }

  oidc_issuer_enabled       = true   # required if HTTPScaledObjects/ScaledObjects use Workload Identity
  workload_identity_enabled = true
}

**Verification after `terraform apply`:**

```bash
az aks command invoke \
  --resource-group <rg-name> \
  --name aks-private-cluster \
  --command "kubectl get pods -n kube-system | grep keda"
```

Expected output: pods named `aks-managed-keda-operator-*` and `aks-managed-keda-operator-metrics-apiserver-*` running in `kube-system`.

---

## 5. Installing the KEDA HTTP Add-on on a Private Cluster (via Run Command)

Because the cluster is private, `helm` and `kubectl` cannot reach the API server directly from a local machine unless you have connectivity through a jumpbox, VPN, VNet peering, or a self-hosted runner inside the VNet. The **AKS Run Command** feature (`az aks command invoke`, or the "Run command" blade in the Portal) is the supported way to execute commands against a private cluster's API server without needing direct network line-of-sight — Azure executes the command from a pod inside the cluster on your behalf.

### 5.1 Add the Helm repo and install the HTTP Add-on

From the **Run command** blade (Azure Portal → AKS cluster → Kubernetes resources → Run command):

helm install http-add-on <<JFROG URL>> --namespace keda --create-namepsace --username << non user id>> --password << non user-id password>>
  "


### 5.2 Verify the installation

From the **Run command** blade (Azure Portal → AKS cluster → Kubernetes resources → Run command):

kubectl get pods -n keda

Expected pods:
- `keda-add-ons-http-controller-manager-*` (controller/scaler)
- `keda-add-ons-http-interceptor-*` (proxy)

---

## 6. Deploying the Application and HTTPScaledObject

### 6.1 Sample target Deployment + Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-http-app
  namespace: workloads
spec:
  replicas: 0
  selector:
    matchLabels:
      app: sample-http-app
  template:
    metadata:
      labels:
        app: sample-http-app
    spec:
      containers:
        - name: sample-http-app
          image: <your-registry>/sample-http-app:latest
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: sample-http-app-svc
  namespace: workloads
spec:
  selector:
    app: sample-http-app
  ports:
    - port: 8080
      targetPort: 8080
```

### 6.2 HTTPScaledObject

```yaml
apiVersion: http.keda.sh/v1alpha1
kind: HTTPScaledObject
metadata:
  name: sample-http-app-scaledobject
  namespace: workloads
spec:
  hosts:
    - myapp.internal.contoso.com
  scaleTargetRef:
    name: sample-http-app
    kind: Deployment
    service: sample-http-app-svc
    port: 8080
  replicas:
    min: 0
    max: 20
  scaledownPeriod: 300
  scalingMetric:
    requestRate:
      granularity: 1s
      targetValue: 100
      window: 1m
```

Apply via Run Command in the same pattern as Section 5, or through your existing GitHub Actions → Octopus/Terraform pipeline once kubeconfig/`kubelogin` access to the private cluster is wired up (per your existing CI work).

### 7.3 How traffic reaches the Interceptor

For the HTTP Add-on to intercept and buffer requests while scaling from zero, incoming traffic must be routed **through the Interceptor service**, not directly to your application Service. Two common patterns:

- **Ingress-based routing:** point your Ingress controller (NGINX, App Gateway Ingress Controller, etc.) at the `keda-add-ons-http-interceptor-proxy` Service instead of the app Service directly, using the `Host` header match defined in `HTTPScaledObject.spec.hosts`.
- **Direct Service substitution:** for internal-only traffic, update the calling service's DNS/Service reference to point at the interceptor Service, with the original app Service left only as `scaleTargetRef`.

---

## 8. Testing the Autoscaling Behavior

```bash
# Confirm scale-to-zero at rest
kubectl get deployments -n durai
kubectl get deploy <<sample-http-app>> -n durai
# replicas: 0

# Generate load through the interceptor endpoint
hey -z 60s -c 20 http://<interceptor-external-ip-or-hostname>/

# Watch HPA and pod scale-out in real time
kubectl get hpa -n durai -w
kubectl get pods -n durai -w
```

Expect: pod count rises within the `granularity`/`window` interval configured on `scalingMetric.requestRate`, and scales back to 0 after `scaledownPeriod` (300s in the example) with no further traffic.

---

## 9. Monitoring & Troubleshooting

| Symptom | Likely Cause | Check |
|---|---|---|
| Requests time out while scaled to 0 | Interceptor not in the traffic path | Confirm Ingress/Service points at interceptor, not app Service directly |
| HPA shows `<unknown>` for metrics | HTTP Add-on scaler pod not reporting | `kubectl logs -n keda deploy/keda-add-ons-http-controller-manager` |
| Run Command fails / times out | Private cluster networking / control-plane throttling | Retry; for repeated use, consider a self-hosted runner inside the VNet as you've explored for other AKS pipelines |
| Scale-down not respecting `scaledownPeriod` | Cached HPA behavior / default Kubernetes stabilization window | Cross-check `HorizontalPodAutoscaler` object's `behavior.scaleDown.stabilizationWindowSeconds` |
---

## 10. Summary Checklist

- [ ] Confirm Terraform-managed KEDA add-on is the **only** core KEDA installation (`kube-system`, release `aks-managed-keda`)
- [ ] Install **only** `kedacore/keda-add-ons-http` via Helm (via Run Command, given private cluster networking)
- [ ] Route ingress/service traffic through the Interceptor
- [ ] Define `HTTPScaledObject` per workload
- [ ] Validate scale-to-zero and scale-out under load
<!-- - [ ] Migrate the Run Command Helm install into your existing GitHub Actions/Terraform pipeline for repeatability, rather than leaving it as a manual Portal step -->

---
