# Testing

This document covers the end-to-end (E2E) test framework for validating Nutanix
product catalog entries.

## Prerequisites

All commands assume you are inside a [devbox](https://www.jetify.com/devbox)
shell. Start one with:

```sh
devbox shell
```

Devbox provides Go, just, jq, and other tools at consistent versions. The shell
init hook adds `.local/bin` to `PATH`, which is where the `nkp` CLI is
downloaded to.

## Running Tests Locally

### Single application

```sh
just e2e-test <app> <version>
```

For example:

```sh
just e2e-test envoy-gateway 1.6.3
```

By default this creates an ephemeral [Kind](https://kind.sigs.k8s.io/) cluster,
installs Flux, deploys the application, and validates the HelmRelease reaches a
`Ready` state. The cluster is torn down after the test completes.

### Using an existing cluster

To skip Kind cluster creation and run against a cluster you already have:

```sh
E2E_KUBECONFIG=~/.kube/config just e2e-test envoy-gateway 1.6.3
```

When `E2E_KUBECONFIG` is set, the test suite connects to the cluster at that
kubeconfig path instead of provisioning a new Kind cluster. Cluster teardown is
also skipped.

### Skipping cluster teardown

To keep the Kind cluster around after a test run (useful for debugging):

```sh
SKIP_CLUSTER_TEARDOWN=1 just e2e-test envoy-gateway 1.6.3
```

### Running specific test labels

The test suites use [Ginkgo v2](https://onsi.github.io/ginkgo/) labels. Each
application has a label matching its directory name, and each test type has a
label (`install`, `upgrade`). You can filter with `--ginkgo.label-filter`:

```sh
cd apptests && go test ./suites/ -v -count=1 \
  --ginkgo.label-filter="envoy-gateway && install" \
  -app-version=1.6.3
```

### Docker host

If you use Colima or another non-default Docker runtime, set `DOCKER_HOST` so
Kind can find the Docker socket:

```sh
export DOCKER_HOST=unix://$HOME/.colima/default/docker.sock
```

## CI Workflow

The E2E tests are **opt-out** per application. A default install + upgrade test
is auto-registered for every folder under `applications/`, except those listed
in the `skipApps` slice in `apptests/suites/suites_test.go`.

The workflow is defined in `.github/workflows/e2e.yaml`.

### Triggers

| Event | Behavior |
|---|---|
| PR with `e2e-<app>` label | Tests the named app (unless it is in `skipApps`). |
| PR with `run-e2e-all` label | Tests all apps not in `skipApps`. |
| PR with no `e2e-*` labels | No tests run. |
| `workflow_dispatch` with app input | Tests the specified app. |
| `workflow_dispatch` without app input | Tests all apps not in `skipApps`. |
| Push to `main` (touching `apptests/`) | Tests all apps not in `skipApps`. |

### How matrix detection works

The `detect-apps` job enumerates every folder under `applications/` and
subtracts the `skipApps` slice parsed from `suites_test.go` — mirroring the
`catalog.ScanAndRegister` auto-discovery used by the Go suite, so CI and the
test code always agree on which apps run. It then intersects the result with any
`e2e-<app>` PR labels to build the matrix. Each `app/version` pair becomes a
separate CI job. If no labels are present on a PR, the matrix is empty and the
e2e job is skipped.

### Diagnostic bundles

When a test fails in CI, the workflow automatically:

1. Runs `nkp diagnose` to collect a diagnostic bundle from the cluster.
2. Uploads the bundle as a GitHub Actions artifact named
   `e2e-<app>-<version>`.

You can download these from the workflow run's **Artifacts** section.

## Test Structure

Tests use the shared `catalog` package from
[kommander-applications/apptests/catalog](https://github.com/mesosphere/kommander-applications/tree/main/apptests/catalog).
This package provides:

- `InitSuite` / `RunSuite` -- Ginkgo suite bootstrap and global variables
- `SetupKindCluster` / `TeardownCluster` -- Kind cluster lifecycle with
  `E2E_KUBECONFIG` support
- `RegisterDefaultTests` -- template install + upgrade test blocks
- `NewAppScenario` -- generic `App` implementing the `AppScenario` interface

The generic harness applies the kustomization at
`applications/<app>/<version>/helmrelease/` and waits for a HelmRelease named
after the app folder to become Ready.

Each template test follows this pattern:

- **Install block** (`Label("install")`) -- creates a cluster, installs Flux,
  deploys the app, and asserts the HelmRelease becomes Ready.
- **Upgrade block** (`Label("upgrade")`) -- checks if a previous version
  exists. If not, the block is skipped. If yes, installs the previous version,
  upgrades, and asserts success.

Each block manages its own cluster lifecycle, so skipped upgrade tests don't
waste time provisioning clusters.

## Enabling Tests for an Application

Tests are registered automatically. `catalog.ScanAndRegister`
walks `applications/` and registers a default install + upgrade template test
for every app folder that is **not** in `skipApps`. Adding a new app folder
gives it E2E coverage with no code change.

### Excluding an Application

If an app cannot pass the generic test (e.g. it uses a non-standard layout
instead of `helmrelease/`, needs dependencies the harness does not install, or
requires GPU/special hardware), add it to the `skipApps` slice in
`apptests/suites/suites_test.go` with a short reason. The current exclusions are:

```go
var skipApps = []string{
	// non-standard layout (release//helmreleases/) the harness does not
	// apply, and Nutanix infra deps (ntnx-system/CSI, GPU operator).
	"ndk", "nutanix-ai",
	// need dependencies the harness does not install (kube-prometheus-stack)
	"opentelemetry-operator",
}
```

This leaves `envoy-gateway`, `envoy-gateway-nai`, and `kserve` covered by the
generic install + upgrade tests.

## Custom Test Files

If an application needs pre-install setup (secrets, ConfigMap patches, CRDs,
etc.), create a dedicated `apptests/suites/<app>_test.go` file instead:

1. Write a Ginkgo `Describe` block with `Label("<app>")` matching the
   directory name.
2. Use `catalog.SetupKindCluster()`, `catalog.Env`, `catalog.K8sClient`, and
   `catalog.NewAppScenario("<app>", *catalog.AppVersion)` from the shared
   package.
3. Add the app to `skipApps` in `suites_test.go` so the generic auto-registered
   test does not also run for it -- the custom test file registers its own
   Ginkgo blocks directly.
