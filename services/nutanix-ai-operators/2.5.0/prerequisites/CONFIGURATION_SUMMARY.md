# Configuration Summary - Quick Reference

## Current Configuration

### Gateway API CRDs
- **Version**: v1.3.0
- **Channel**: Experimental (includes GRPCRoute, TCPRoute, TLSRoute, UDPRoute)
- **Source**: kubernetes-sigs/gateway-api
- **Path**: `/config/crd/experimental`
- **Helm Equivalent**: `--set crds.gatewayAPI.enabled=true`

### Envoy Gateway CRDs
- **Version**: v1.5.0
- **Source**: envoyproxy/gateway
- **Path**: `/charts/gateway-helm/crds`
- **Helm Equivalent**: `--set crds.envoyGateway.enabled=true`

### Envoy Gateway (Main Installation)
- **Version**: v1.5.0
- **Namespace**: envoy-gateway-system
- **Installation Method**: HelmRelease (OCI)

---

## Visual Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Prerequisites Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────┐    ┌──────────────────────┐       │
│  │  Gateway API v1.3.0  │    │  Envoy Gateway CRDs  │       │
│  │  (Experimental)      │    │      v1.5.0          │       │
│  │                      │    │                      │       │
│  │  GitRepository       │    │  GitRepository       │       │
│  │       +              │    │       +              │       │
│  │  Kustomization       │    │  Kustomization       │       │
│  └──────────┬───────────┘    └──────────┬───────────┘       │
│             │                           │                    │
│             └───────────┬───────────────┘                    │
│                         │ dependsOn                          │
│                         ▼                                    │
│              ┌──────────────────────┐                        │
│              │   Envoy Gateway      │                        │
│              │   v1.5.0             │                        │
│              │   (HelmRelease)      │                        │
│              └──────────┬───────────┘                        │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          │ Both complete before...
                          │
                          ▼
         ┌────────────────────────────────┐
         │   OpenTelemetry Operator       │
         │   v0.93.0 (HelmRelease)        │
         └────────────────────────────────┘
                          │
                          │ Both complete before...
                          │
                          ▼
              ┌───────────────────┐
              │   Nutanix AI      │
              │   v2.5.0          │
              └───────────────────┘
```

---

## How "Enabled" Settings Work

### In Your Manual Helm Command:
```bash
--set crds.gatewayAPI.enabled=true \
--set crds.envoyGateway.enabled=true
```

These flags tell Helm to **include** these CRD subdirectories when templating the chart.

### In Flux Kustomization:

The "enabled" concept is implicit:

| Helm Flag | Flux Implementation | Status |
|-----------|---------------------|--------|
| `crds.gatewayAPI.enabled=true` | `gateway-api-crd` Kustomization exists | ✅ **ENABLED** |
| `crds.envoyGateway.enabled=true` | `envoy-gateway-crd` Kustomization exists | ✅ **ENABLED** |

**To disable**: Simply remove or comment out the corresponding Kustomization resource.

---

## What Gets Installed

### 1. Gateway API CRDs (Experimental v1.3.0)

**Standard Channel CRDs:**
- `gatewayclasses.gateway.networking.k8s.io`
- `gateways.gateway.networking.k8s.io`
- `httproutes.gateway.networking.k8s.io`
- `referencegrants.gateway.networking.k8s.io`
- `backendtlspolicies.gateway.networking.k8s.io`

**Experimental Channel Additions:**
- `grpcroutes.gateway.networking.k8s.io` ← gRPC routing
- `tcproutes.gateway.networking.k8s.io` ← TCP routing
- `tlsroutes.gateway.networking.k8s.io` ← TLS routing  
- `udproutes.gateway.networking.k8s.io` ← UDP routing

### 2. Envoy Gateway CRDs (v1.5.0)

- `envoyproxies.config.gateway.envoyproxy.io`
- `envoypatchpolicies.gateway.envoyproxy.io`
- `clienttrafficpolicies.gateway.envoyproxy.io`
- `backendsecuritypolicies.gateway.envoyproxy.io`
- `securitypolicies.gateway.envoyproxy.io`
- `backendtrafficpolicies.gateway.envoyproxy.io`
- And more...

---

## Channel Comparison: Standard vs Experimental

| Feature | Standard | Experimental |
|---------|----------|--------------|
| Production Ready | ✅ Yes | ⚠️ Beta/Alpha |
| HTTP Routing | ✅ HTTPRoute | ✅ HTTPRoute |
| gRPC Routing | ❌ | ✅ GRPCRoute |
| TCP Routing | ❌ | ✅ TCPRoute |
| TLS Routing | ❌ | ✅ TLSRoute |
| UDP Routing | ❌ | ✅ UDPRoute |
| Gateway API Conformance | Core | Extended |

**Current Selection:** Experimental (v1.3.0) - Provides full protocol support.

---

## Quick Config Changes

### Switch to Standard Channel:

Edit `envoy-gateway-crd.yaml`:

```yaml
# Change from:
ref:
  tag: v1.3.0
ignore: |
  /*
  !/config/crd/experimental/

# To:
ref:
  tag: v1.3.0
ignore: |
  /*
  !/config/crd/standard/
```

And update path:
```yaml
# Change from:
path: ./config/crd/experimental

# To:
path: ./config/crd/standard
```

### Update Gateway API Version:

Edit `envoy-gateway-crd.yaml`:
```yaml
ref:
  tag: v1.4.0  # ← New version
```

### Update Envoy Gateway Version:

Edit **both files**:

1. `envoy-gateway-crd.yaml`:
```yaml
ref:
  tag: v1.6.0  # ← New CRD version
```

2. `envoy-gateway.yaml`:
```yaml
ref:
  tag: v1.6.0  # ← Must match CRD version
```

---

## Verification Commands

```bash
# 1. Check Git sources are fetched
kubectl get gitrepository -n <workspace> | grep -E '(gateway-api|envoy-gateway)'

# 2. Check Kustomizations are applied
kubectl get kustomization -n <workspace> | grep crd

# 3. Verify CRDs exist
kubectl get crd | grep gateway
kubectl get crd | grep envoy

# 4. Count installed CRDs
echo "Gateway API CRDs:" $(kubectl get crd | grep gateway.networking.k8s.io | wc -l)
echo "Envoy Gateway CRDs:" $(kubectl get crd | grep gateway.envoyproxy.io | wc -l)

# 5. Check HelmReleases
kubectl get helmrelease -n <workspace>

# 6. Full status check
kubectl get gitrepository,kustomization,helmrelease -n <workspace>
```

---

## Troubleshooting Quick Reference

| Issue | Check | Solution |
|-------|-------|----------|
| CRDs not appearing | `kubectl describe kustomization gateway-api-crd -n <workspace>` | Check GitRepository connectivity |
| Envoy Gateway pending | `kubectl describe helmrelease envoy-gateway -n <workspace>` | Wait for CRD Kustomizations to complete |
| Version mismatch | Compare tags in both files | Ensure CRD version matches HelmRelease version |
| Experimental CRDs missing | Check `path:` in Kustomization | Verify `experimental` vs `standard` |

---

## Documentation Files

1. **`CONFIGURATION_SUMMARY.md`** (this file) - Quick reference
2. **`HELM_VALUES_MAPPING.md`** - How Helm values map to Kustomization
3. **`IMPLEMENTATION_SUMMARY.md`** - Implementation details and testing
4. **`ENVOY_CRD_SOLUTION.md`** - Full analysis of alternatives and rationale

---

## Summary

✅ **Gateway API**: v1.3.0 Experimental Channel (more routing protocols)  
✅ **Envoy Gateway**: v1.5.0 with CRDs  
✅ **Both "enabled"**: Via Flux Kustomization resources  
✅ **No Helm limit**: Bypasses 1MB secret size issue  
✅ **GitOps-native**: Fully declarative configuration  

