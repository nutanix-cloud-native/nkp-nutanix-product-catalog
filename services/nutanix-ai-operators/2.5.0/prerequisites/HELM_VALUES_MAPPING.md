# Helm Values to Kustomization Mapping

## Question: How do I enable `gatewayAPI` and `envoyGateway` CRDs?

### Original Helm Command:
```bash
helm template eg oci://docker.io/envoyproxy/gateway-crds-helm \
  --version v1.5.0 \
  --set crds.gatewayAPI.enabled=true \
  --set crds.envoyGateway.enabled=true | \
  kubectl apply --server-side --force-conflicts -f -
```

### In the Kustomization Approach:

Instead of using Helm values to **enable/disable** which CRDs to include during templating, we **directly apply** the CRD manifests from their source repositories.

## Mapping Table

| Helm Setting | Kustomization Equivalent | Implementation |
|--------------|-------------------------|----------------|
| `crds.gatewayAPI.enabled=true` | Apply Gateway API CRDs | GitRepository + Kustomization pointing to `kubernetes-sigs/gateway-api` |
| `crds.envoyGateway.enabled=true` | Apply Envoy Gateway CRDs | GitRepository + Kustomization pointing to `envoyproxy/gateway` CRDs path |

## How It Works

### 1. Gateway API CRDs (`gatewayAPI.enabled=true`)

**Helm Approach:**
```yaml
# In the Helm chart's values.yaml
crds:
  gatewayAPI:
    enabled: true  # ← This includes Gateway API CRDs in the template
```

**Kustomization Approach:**
```yaml
# GitRepository fetches the Gateway API source
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: gateway-api
spec:
  url: https://github.com/kubernetes-sigs/gateway-api
  ref:
    tag: v1.3.0  # ← Version control
  ignore: |
    /*
    !/config/crd/experimental/  # ← Channel selection (experimental vs standard)

---
# Kustomization applies the CRDs
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: gateway-api-crd
spec:
  sourceRef:
    kind: GitRepository
    name: gateway-api
  path: ./config/crd/experimental  # ← Apply experimental channel CRDs
```

**Result:** All Gateway API CRDs are applied (equivalent to `enabled=true`)

---

### 2. Envoy Gateway CRDs (`envoyGateway.enabled=true`)

**Helm Approach:**
```yaml
# In the Helm chart's values.yaml
crds:
  envoyGateway:
    enabled: true  # ← This includes Envoy Gateway-specific CRDs
```

**Kustomization Approach:**
```yaml
# GitRepository fetches the Envoy Gateway source
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: envoy-gateway
spec:
  url: https://github.com/envoyproxy/gateway
  ref:
    tag: v1.5.0  # ← Version control
  ignore: |
    /*
    !/charts/gateway-helm/crds/  # ← Only CRD directory

---
# Kustomization applies the Envoy Gateway CRDs
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: envoy-gateway-crd
spec:
  sourceRef:
    kind: GitRepository
    name: envoy-gateway
  path: ./charts/gateway-helm/crds  # ← Apply Envoy-specific CRDs
```

**Result:** All Envoy Gateway CRDs are applied (equivalent to `enabled=true`)

---

## Key Differences

### Helm Approach:
- **Values file controls inclusion** - `enabled: false` would exclude those CRDs from templating
- **Single chart with conditional logic** - One Helm chart contains both sets of CRDs
- **Template-time decision** - Decided when running `helm template`

### Kustomization Approach:
- **Resource presence controls inclusion** - Include/exclude by adding/removing Kustomization resources
- **Separate sources** - Two GitRepositories for each CRD set
- **Apply-time decision** - Decided by which Kustomizations exist in the cluster

## How to Disable CRDs (If Needed)

### Helm Way:
```bash
helm template eg ... --set crds.gatewayAPI.enabled=false
```

### Kustomization Way:
Simply don't include the Kustomization resource, or comment it out:

```yaml
# In prerequisites/kustomization.yaml
resources:
# - envoy-gateway-crd.yaml  # ← Commented out = disabled
- envoy-gateway.yaml
```

Or remove specific sections from `envoy-gateway-crd.yaml`.

## Configuration Options

### Gateway API Channel Selection

| Channel | Path | CRDs Included |
|---------|------|---------------|
| **Standard** | `/config/crd/standard` | Stable APIs (GatewayClass, Gateway, HTTPRoute, etc.) |
| **Experimental** | `/config/crd/experimental` | Standard + Experimental APIs (GRPCRoute, TCPRoute, TLSRoute, etc.) |

**Current Configuration:** `experimental` channel (v1.3.0)

To switch to standard channel:
```yaml
spec:
  ref:
    tag: v1.3.0
  ignore: |
    /*
    !/config/crd/standard/  # ← Change this
```

And update path:
```yaml
spec:
  path: ./config/crd/standard  # ← Change this
```

## Version Management

### Update Gateway API Version:
```yaml
# In envoy-gateway-crd.yaml
spec:
  ref:
    tag: v1.3.0  # ← Change to desired version
```

### Update Envoy Gateway Version:
```yaml
# In envoy-gateway-crd.yaml (Envoy Gateway section)
spec:
  ref:
    tag: v1.5.0  # ← Change to desired version
```

AND

```yaml
# In envoy-gateway.yaml (HelmRelease section)
spec:
  ref:
    tag: v1.5.0  # ← Keep in sync with CRDs
```

## Summary

In the Flux Kustomization approach:

✅ **`gatewayAPI.enabled=true`** = Include the `gateway-api-crd` Kustomization  
✅ **`envoyGateway.enabled=true`** = Include the `envoy-gateway-crd` Kustomization

Both are currently **enabled** because both Kustomization resources exist and apply their respective CRD manifests.

The "enabled" concept is implicit: if the Kustomization resource exists and is applied, those CRDs are "enabled."

