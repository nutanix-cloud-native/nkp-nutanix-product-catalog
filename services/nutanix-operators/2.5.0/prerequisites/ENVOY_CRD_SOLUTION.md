# Envoy Gateway CRD Installation Solution

## Problem
Helm stores release metadata in Kubernetes secrets with a 1MB size limit. The Envoy Gateway CRDs exceed this limit, causing the error:
```
Secret "sh.helm.release.v1.eg.v1" is invalid: data: Too long: may not be more than 1048576 bytes
```

## Alternatives Considered

### 1. ✅ Flux Kustomization with GitRepository (IMPLEMENTED)
**Pros:**
- Pure Flux/GitOps solution - no custom Jobs or scripts
- Native Flux dependency management with `dependsOn`
- Automatic reconciliation and drift detection
- No custom container images needed
- Applies CRD manifests directly from source
- No Helm release metadata stored
- Clean separation: Gateway API CRDs + Envoy Gateway CRDs

**Cons:**
- Requires Git access (public GitHub repos)
- Cannot customize via Helm values (but CRDs rarely need customization)
- Two separate GitRepository sources

**Implementation:** 
- GitRepository for Gateway API (kubernetes-sigs/gateway-api)
- Kustomization applies Gateway API CRDs from `/config/crd/standard`
- GitRepository for Envoy Gateway (envoyproxy/gateway)
- Kustomization applies Envoy Gateway CRDs from `/charts/gateway-helm/crds`
- Uses Flux's native `dependsOn` for ordering

---

### 2. Job with `helm template` + `kubectl apply`
**Pros:**
- Exactly matches the manual installation command
- Uses server-side apply with force-conflicts flag
- No release metadata stored in secrets
- Works within Kubernetes-native patterns
- Automatically retries on failure (backoffLimit: 10)

**Cons:**
- Requires custom container images with both helm and kubectl
- Requires RBAC setup (ServiceAccount, ClusterRole, ClusterRoleBinding)
- Cannot use FluxCD's HelmRelease dependency management
- Jobs don't automatically reconcile like HelmReleases

**Why not chosen:** Requires custom images and doesn't leverage Flux's native capabilities

---

### 3. Pre-templated Manifests in Repository
**Pros:**
- Simple Kustomization resource
- Full control over manifests
- Easy to review changes

**Cons:**
- Must manually update when upgrading versions
- Manifests become out of sync with upstream
- Increases repository size
- Loses automation benefits

**Why not chosen:** Increases maintenance burden and loses automation

---

### 4. Split CRDs into Separate Charts
**Pros:**
- Each smaller chart stays under 1MB limit
- Uses standard HelmRelease

**Cons:**
- Requires upstream chart modifications
- Not feasible with third-party charts
- Complex dependency management

**Why not chosen:** Cannot modify upstream Envoy Gateway charts

---

## Implemented Solution Details

The Flux Kustomization approach creates:

### 1. Gateway API CRDs
- **GitRepository**: `gateway-api` - Fetches kubernetes-sigs/gateway-api v1.2.1
- **Kustomization**: `gateway-api-crd` - Applies CRDs from `/config/crd/standard`
  - Installs standard Gateway API CRDs (GatewayClass, Gateway, HTTPRoute, etc.)

### 2. Envoy Gateway CRDs
- **GitRepository**: `envoy-gateway` - Fetches envoyproxy/gateway v1.5.0
- **Kustomization**: `envoy-gateway-crd` - Applies CRDs from `/charts/gateway-helm/crds`
  - Depends on `gateway-api-crd` via `dependsOn`
  - Installs Envoy Gateway-specific CRDs

### Dependency Management

The dependency chain is now:
```
gateway-api-crd (Kustomization)
    ↓ dependsOn
envoy-gateway-crd (Kustomization)
    ↓ (natural ordering through retries)
envoy-gateway (HelmRelease)
    ↓ dependsOn
nutanix-ai (HelmRelease)
```

### Key Configuration
- **interval**: 10m - Reconciliation frequency
- **retryInterval**: 1m - Retry on failure every minute
- **timeout**: 5m - Maximum time for reconciliation
- **prune**: true - Remove CRDs if deleted from source
- **wait**: true - Wait for CRDs to be ready before continuing
- **ignore**: Optimizes Git clones by ignoring unnecessary paths

## Testing Recommendations

1. **Verify GitRepository sources**: 
   ```bash
   kubectl get gitrepository gateway-api envoy-gateway -n <workspace-namespace>
   ```

2. **Check Kustomization status**:
   ```bash
   kubectl get kustomization gateway-api-crd envoy-gateway-crd -n <workspace-namespace>
   ```

3. **Verify CRD installation**:
   ```bash
   kubectl get crd | grep gateway
   kubectl get crd | grep envoy
   ```

4. **Monitor envoy-gateway HelmRelease**:
   ```bash
   kubectl get helmrelease envoy-gateway -n <workspace-namespace>
   ```

5. **View Kustomization details if issues occur**:
   ```bash
   kubectl describe kustomization gateway-api-crd -n <workspace-namespace>
   kubectl describe kustomization envoy-gateway-crd -n <workspace-namespace>
   ```

## Upgrade Path

When upgrading Envoy Gateway versions:
1. Update the `tag` in the GitRepository spec (e.g., from `v1.5.0` to `v1.6.0`)
2. Flux will automatically reconcile and apply the new CRD manifests
3. Existing CRDs will be updated in-place
4. No manual intervention required - fully automated GitOps flow

## Benefits of This Approach

1. **GitOps Native**: Fully declarative, all configuration in Git
2. **No Custom Images**: Uses only Flux's built-in capabilities
3. **Automatic Reconciliation**: Flux continuously ensures desired state
4. **Proper Dependency Management**: Uses Flux's native `dependsOn`
5. **Airgap Compatible**: Can mirror Git repositories for airgapped environments
6. **Version Controlled**: All CRD versions tracked in manifests
7. **Auditable**: Changes tracked through Git history
8. **Self-Healing**: Automatically recovers from failures

## Airgap/Darksite Considerations

For airgapped environments:
1. Mirror the GitHub repositories to an internal Git server
2. Update the `url` in the GitRepository specs to point to internal mirrors
3. No OCI registry or Helm repository access needed
4. Pure manifest-based approach works offline

