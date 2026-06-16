# Run e2e tests for a specific application and version.
# Set E2E_KUBECONFIG to use an existing cluster, otherwise a kind cluster is created.
# Usage: just e2e-test envoy-gateway 1.6.3
#        E2E_KUBECONFIG=~/.kube/config just e2e-test envoy-gateway 1.6.3
e2e-test app version: nkp-cli
    cd apptests && go test ./suites/ -v -timeout=15m -count=1 --ginkgo.v --ginkgo.label-filter="{{app}}" -app-version={{version}}

# Run e2e tests for all applications at all versions.
[no-exit-message]
[script]
e2e-test-all:
    set -euo pipefail
    failed=0
    for dir in applications/*/*/; do
      app=$(echo "$dir" | cut -d/ -f2)
      version=$(echo "$dir" | cut -d/ -f3)
      echo "=== Testing $app @ $version ==="
      if ! just e2e-test "$app" "$version"; then
        failed=1
      fi
    done
    exit $failed
