set unstable

BUNDLE_NAME := "nkp-nutanix-product-catalog"

# Release oci artifacts for catalog applications
[no-exit-message]
publish-artifacts release-spec registry: nkp-cli
  {{ NKP_CLI }} experimental catalog release --release-spec {{ release-spec }} --repo-dir "{{ REPO_ROOT }}" --push-to-registry {{ registry}}


# Create a full bundle for a single application
# Example: just create-application-full-bundle ndk 2.1.0
[script]
create-application-full-bundle application-name application-version output-file="": nkp-cli
  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT
  output_file="{{output-file}}"

  if [ -z "$output_file" ]; then
    output_file="{{application-name}}-{{application-version}}-full.tar"
  fi

  OUTPUT_FILE="$output_file" APP_NAME="{{application-name}}" APP_VERSION="{{application-version}}" yq -n \
    '.schema = "catalog.nkp.nutanix.com/v1/catalog-release-spec" |
     .releases = [{
       "fileName": strenv(OUTPUT_FILE),
       "includeApplicationImages": true,
       "baseRegistry": "ghcr.io/nutanix-cloud-native",
       "applications": [{"name": strenv(APP_NAME), "version": strenv(APP_VERSION)}]
     }]' > "$tmpfile"

  echo "Building application bundle for {{application-name}} {{application-version}}... (output file: $output_file)"
  cat "$tmpfile"
  "{{ NKP_CLI }}" experimental catalog release --release-spec "$tmpfile" --repo-dir "{{ REPO_ROOT }}"

# Create a full bundle for a collection of applications.
# Usage: just create-collection-full-bundle <collection-tag> [output-file] [release-spec]
[script]
create-collection-full-bundle collection-tag output-file="" release-spec=".release/dev.yaml": nkp-cli
  output_file="{{output-file}}"
  tag_name="{{collection-tag}}"

  if [ -z "$output_file" ]; then
    output_file="{{BUNDLE_NAME}}-{{collection-tag}}-full.tar"
  fi

  if [ -z "$(yq '.releases[] | select(.tagName == "'"$tag_name"'")' {{release-spec}})" ]; then
    echo "Error: Tag '$tag_name' not found in {{release-spec}}"
    exit 1
  fi

  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  OUTPUT_FILE="$output_file" TAG_NAME="$tag_name" yq \
    'del(.releases[] | select(.tagName != strenv(TAG_NAME))) |
     .releases[0].fileName = strenv(OUTPUT_FILE)' \
    "{{release-spec}}" > "$tmpfile"

  echo "Building collection full bundle for $tag_name... (output file: $output_file)"
  cat "$tmpfile"
  "{{ NKP_CLI }}" experimental catalog release --release-spec "$tmpfile" --repo-dir "{{ REPO_ROOT }}"

# Build full bundles for all tags in a release spec
[script]
build-full-bundles release-spec output-dir: nkp-cli
  mkdir -p "{{ output-dir }}"
  while IFS=$'\t' read -r tag filename; do
    if [ -z "$filename" ]; then
      echo "Error: Tag '$tag' in {{ release-spec }} has no fileName"
      exit 1
    fi
    bundle="{{ output-dir }}/$filename"
    echo "Building bundle for $tag... (output file: $bundle)"
    just create-collection-full-bundle "$tag" "$bundle" {{ release-spec }}
  done < <(yq -r '.releases[] | select(.includeApplicationImages == true) | [.tagName, .fileName] | @tsv' {{ release-spec }})
