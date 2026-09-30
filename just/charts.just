DEFAULT_CHART_OCI_REGISTRY := "oci://ghcr.io/nutanix-cloud-native/nkp-nutanix-product-catalog/charts"

# Pull a Helm chart from an HTTP repo and push it to an OCI registry.
# Example: just publish-chart-oci https://mesosphere.github.io/charts/staging ndk 2.3.0
[script]
publish-chart-oci chart-repo chart-name chart-version registry=DEFAULT_CHART_OCI_REGISTRY:
  set -euo pipefail
  helm repo add "{{chart-name}}" "{{chart-repo}}"
  helm repo update
  helm pull "{{chart-name}}/{{chart-name}}" --version "{{chart-version}}"
  helm push "{{chart-name}}-{{chart-version}}.tgz" "{{registry}}"
