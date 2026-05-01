set unstable

# Release oci artifacts for catalog applications
[no-exit-message]
publish-artifacts release-spec registry: nkp-cli
  {{ NKP_CLI }} experimental catalog release --release-spec {{ release-spec }} --repo-dir "{{ REPO_ROOT }}" --push-to-registry {{ registry}}

# Create airgapped catalog bundle (includes container images and OCI artifacts)
# Usage: just create-airgapped-bundle <collection-tag> <output-file> [release-spec]
# Example: just create-airgapped-bundle 2.18 my-airgapped.tar
[script]
create-airgapped-bundle collection-tag output-file release-spec=".release/stable.yaml": nkp-cli
  tag_version=$(echo "{{collection-tag}}" | sed 's/^v\?\([0-9]*\.[0-9]*\).*/\1/')

  if ! echo "$tag_version" | grep -qE '^[0-9]+\.[0-9]+$'; then
    echo "Error: Invalid version format. Expected major.minor (e.g., '2.18')"
    exit 1
  fi

  if ! yq '.releases[] | select(.tagName == "'$tag_version'")' {{release-spec}} > /dev/null 2>&1; then
    echo "Error: Version '$tag_version' not found in {{release-spec}}"
    exit 1
  fi

  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  cp {{ REPO_ROOT }}/.release/airgapped.yaml.tmpl "$tmpfile"

  yq -i \
    '.releases[0].tagName = "'$tag_version'" |
     .releases[0].fileName = "{{output-file}}" |
     .releases[0].applications = (load("{{release-spec}}") | .releases[] | select(.tagName == "'$tag_version'") | .applications)' \
    "$tmpfile"

  echo "Building airgapped bundle for $tag_version..."
  cat "$tmpfile"
  "{{ NKP_CLI }}" experimental catalog release --release-spec "$tmpfile" --repo-dir "{{ REPO_ROOT }}"
