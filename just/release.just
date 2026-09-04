set unstable

# Release oci artifacts for catalog applications
[no-exit-message]
publish-artifacts release-spec registry: nkp-cli
  {{ NKP_CLI }} experimental catalog release --release-spec {{ release-spec }} --repo-dir "{{ REPO_ROOT }}" --push-to-registry {{ registry}}

# Create airgapped catalog bundle (includes container images and OCI artifacts)
# Usage: just create-airgapped-bundle <collection-tag> [output-file] [release-spec]
# Example: just create-airgapped-bundle 2.18 my-airgapped.tar
[script]
create-airgapped-bundle collection-tag output-file="" release-spec=".release/full.yaml": nkp-cli
  tag_version=$(echo "{{collection-tag}}" | sed 's/^v\?\([0-9]*\.[0-9]*\).*/\1/')

  if ! echo "$tag_version" | grep -qE '^[0-9]+\.[0-9]+$'; then
    echo "Error: Invalid version format. Expected major.minor (e.g., '2.18')"
    exit 1
  fi

  major="${tag_version%%.*}"
  minor="${tag_version##*.}"
  if [ "$major" -gt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -gt 19 ]; }; then
    tag_suffix="full"
    default_prefix="full"
  else
    tag_suffix="airgapped"
    default_prefix="airgapped"
  fi
  release_tag="${tag_version}.x-${tag_suffix}"
  output_file="{{output-file}}"
  if [ -z "$output_file" ]; then
    output_file="${default_prefix}-nkp-nutanix-product-catalog-${tag_version}.tar"
  fi

  if [ -z "$(yq '.releases[] | select(.tagName == "'"$release_tag"'")' {{release-spec}})" ]; then
    echo "Error: Version '$release_tag' not found in {{release-spec}}"
    exit 1
  fi
  applications_json=$(yq -c '.releases[] | select(.tagName == "'"$release_tag"'") | .applications' {{release-spec}})

  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  cp {{ REPO_ROOT }}/.release/full.yaml.tmpl "$tmpfile"

  yq -i -y \
    --arg tag "$release_tag" \
    --arg file "$output_file" \
    --argjson apps "$applications_json" \
    '.releases[0].tagName = $tag |
     .releases[0].fileName = $file |
     .releases[0].applications = $apps' \
    "$tmpfile"

  echo "Building airgapped bundle for $tag_version... (collection tag: $release_tag, output file: $output_file)"
  cat "$tmpfile"
  "{{ NKP_CLI }}" experimental catalog release --release-spec "$tmpfile" --repo-dir "{{ REPO_ROOT }}"
