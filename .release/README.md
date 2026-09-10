# Release Specifications

Release spec files in this directory define catalog collections for the Nutanix Kubernetes Platform (NKP). Each file follows the `catalog.nkp.nutanix.com/v1/catalog-release-spec` schema.

## Files

| File | Purpose |
|------|---------|
| `dev.yaml` | **Development releases** — generates OCI-only artifacts for development tags (e.g., `2.20-dev`, `2.19-dev`). Used in CI on every push. |
| `dev-bundles.yaml` | **Development full bundles** — generates `.tar` bundles that include container images for the latest NKP version (`2.20`). Uses `includeApplicationImages: true`. |
| `stable.yaml` | **Stable releases** — generates OCI-only artifacts for stable NKP versions (`2.19`, `2.18`, `2.17`, `2.16`). Includes full application lists with pinned versions. |
| `stable-bundles.yaml` | **Stable full bundles** — generates `.tar` bundles with container images for stable NKP versions (`2.19`, `2.18`). |

## Usage

### OCI-only artifacts (dev)

Pushed automatically on every commit:

```bash
just publish-artifacts .release/dev.yaml ghcr.io/nutanix-cloud-native
```

### Full bundles with images

Build locally or in CI:

```bash
# Build all image-inclusive bundles for dev
just build-full-bundles .release/dev-bundles.yaml ./bundles

# Build all image-inclusive bundles for stable
just build-full-bundles .release/stable-bundles.yaml ./bundles

# Build a single app bundle
just create-application-full-bundle ndk 2.1.0
```

## Key Fields

- `tagName` — NKP version tag (e.g., `2.20-dev` or `2.19`)
- `fileName` — Output artifact filename
- `includeApplicationImages: true` — Include container images in bundle (full bundle)
- `baseRegistry` — Default image registry for included applications
- `constraints.nkpVersion` — Minimum NKP version required for compatibility
- `applications` — List of catalog applications with pinned versions
- `collectionAnnotations` — OCI metadata annotations
