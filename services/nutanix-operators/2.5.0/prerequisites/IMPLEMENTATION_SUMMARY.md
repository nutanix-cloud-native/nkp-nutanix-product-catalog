# Envoy Gateway CRD Implementation Summary

## Solution: Pure Flux Kustomization

This implementation uses **Flux Kustomization resources** to install Envoy Gateway CRDs, avoiding the Helm 1MB secret size limit.

## What Was Created

### File: `envoy-gateway-crd.yaml`

Contains **4 Flux resources**:

1. **GitRepository: `gateway-api`**
   - Fetches Gateway API v1.3.0 from kubernetes-sigs/gateway-api
   - Only clones `/config/crd/experimental` directory (experimental channel)
   - Equivalent to: `--set crds.gatewayAPI.enabled=true` in Helm

2. **Kustomization: `gateway-api-crd`**
   - Applies Gateway API CRDs (GatewayClass, Gateway, HTTPRoute, GRPCRoute, TCPRoute, etc.)
   - Runs first in the dependency chain

3. **GitRepository: `envoy-gateway`**
   - Fetches Envoy Gateway v1.5.0 from envoyproxy/gateway
   - Only clones `/charts/gateway-helm/crds` directory
   - Equivalent to: `--set crds.envoyGateway.enabled=true` in Helm

4. **Kustomization: `envoy-gateway-crd`**
   - Applies Envoy Gateway-specific CRDs
   - Depends on `gateway-api-crd` via `dependsOn`

## Installation Order

```
1. gateway-api-crd (Kustomization)
      ↓
2. envoy-gateway-crd (Kustomization)
      ↓
3. envoy-gateway (HelmRelease) ← from envoy-gateway.yaml
      ↓
4. opentelemetry-operator (HelmRelease) ← from opentelemetry.yaml
      ↓
5. nutanix-ai (HelmRelease) ← depends on all above
```

## Key Features

✅ **No custom images** - Pure Flux resources  
✅ **GitOps-native** - Fully declarative  
✅ **Auto-reconciliation** - Flux ensures desired state  
✅ **Proper dependencies** - Uses Flux's `dependsOn`  
✅ **Airgap-ready** - Can mirror Git repos  
✅ **No 1MB limit** - Bypasses Helm secret storage  

## Comparison to Manual Commands

### Your Manual Commands:
```bash
# Gateway API + Envoy CRDs (combined in Helm chart)
helm template eg oci://docker.io/envoyproxy/gateway-crds-helm \
  --version v1.5.0 \
  --set crds.gatewayAPI.enabled=true \
  --set crds.envoyGateway.enabled=true | \
  kubectl apply --server-side --force-conflicts -f -

# Envoy Gateway (main installation)
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.5.0 \
  -n envoy-gateway-system \
  --create-namespace \
  --skip-crds
```

### Flux Equivalent:
- **Gateway API CRDs** (v1.3.0 experimental): GitRepository + Kustomization from `kubernetes-sigs/gateway-api`
  - Equivalent to: `--set crds.gatewayAPI.enabled=true`
- **Envoy Gateway CRDs** (v1.5.0): GitRepository + Kustomization from `envoyproxy/gateway`
  - Equivalent to: `--set crds.envoyGateway.enabled=true`
- **Envoy Gateway**: Installed via HelmRelease in `envoy-gateway.yaml`

**Key Difference:** Instead of templating a single Helm chart with conditional includes, we apply manifests directly from their source repositories.

## Files Modified

1. ✅ `envoy-gateway-crd.yaml` - New Flux Kustomization approach
2. ✅ `envoy-gateway.yaml` - Removed `dependsOn` for CRDs (retries handle timing)
3. ✅ `nutanix-ai.yaml` - Removed `envoy-gateway-crd` dependency (only depends on `envoy-gateway`)
4. ✅ `kustomization.yaml` - Already includes all files

## Testing Commands

```bash
# Verify GitRepositories are ready
kubectl get gitrepository gateway-api envoy-gateway -n <workspace>

# Check Kustomizations are applied
kubectl get kustomization gateway-api-crd envoy-gateway-crd -n <workspace>

# Verify CRDs are installed
kubectl get crd | grep -E '(gateway|envoy)'

# Should see (experimental channel includes more):
# Gateway API CRDs (Standard):
# - gatewayclasses.gateway.networking.k8s.io
# - gateways.gateway.networking.k8s.io
# - httproutes.gateway.networking.k8s.io
# Gateway API CRDs (Experimental):
# - grpcroutes.gateway.networking.k8s.io
# - tcproutes.gateway.networking.k8s.io
# - tlsroutes.gateway.networking.k8s.io
# - udproutes.gateway.networking.k8s.io
# Envoy Gateway CRDs:
# - envoyproxies.config.gateway.envoyproxy.io
# - envoypatchpolicies.gateway.envoyproxy.io
# - clienttrafficpolicies.gateway.envoyproxy.io
# - securitypolicies.gateway.envoyproxy.io
# - etc.

# Check Envoy Gateway HelmRelease
kubectl get helmrelease envoy-gateway -n <workspace>

# Check overall status
kubectl get kustomization,helmrelease -n <workspace>
```

## Troubleshooting

### If GitRepository fails to clone:
```bash
kubectl describe gitrepository gateway-api -n <workspace>
kubectl describe gitrepository envoy-gateway -n <workspace>
```
**Common causes**: Network issues, GitHub rate limits, incorrect tag

### If Kustomization fails:
```bash
kubectl describe kustomization gateway-api-crd -n <workspace>
kubectl describe kustomization envoy-gateway-crd -n <workspace>
```
**Common causes**: Invalid manifests, RBAC issues, dependency not ready

### If envoy-gateway HelmRelease fails:
```bash
kubectl describe helmrelease envoy-gateway -n <workspace>
```
**Common causes**: CRDs not installed yet (will auto-retry), namespace issues

## Upgrading Versions

To upgrade to a newer Envoy Gateway version:

1. Edit `envoy-gateway-crd.yaml`:
   ```yaml
   # Change this:
   ref:
     tag: v1.5.0
   # To:
   ref:
     tag: v1.6.0
   ```

2. Edit `envoy-gateway.yaml`:
   ```yaml
   # Update the OCI tag:
   ref:
     tag: v1.6.0
   ```

3. Commit and push - Flux will automatically reconcile!

## Why This Approach?

| Aspect | HelmRelease (Failed) | Job + kubectl | **Flux Kustomization (Used)** |
|--------|---------------------|---------------|------------------------------|
| Custom Images | ❌ None | ⚠️ Needs kubectl+helm | ✅ None needed |
| Dependencies | ❌ Can't use | ⚠️ Via retries | ✅ Native `dependsOn` |
| Reconciliation | ❌ Fails on 1MB | ⚠️ One-time Job | ✅ Continuous |
| GitOps | ✅ Yes | ⚠️ Partial | ✅ Fully declarative |
| Airgap | ❌ OCI registry | ⚠️ Binary downloads | ✅ Git mirror |
| Maintenance | ❌ Blocked | ⚠️ Medium | ✅ Low |

## Related Documentation

- `ENVOY_CRD_SOLUTION.md` - Detailed explanation of alternatives and rationale
- `envoy-gateway-crd.yaml` - The actual implementation
- `envoy-gateway.yaml` - Envoy Gateway HelmRelease
- `nutanix-ai.yaml` - Main application with dependencies

