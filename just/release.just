set unstable

# Release oci artifacts for catalog applications
[no-exit-message]
[script]
publish-artifacts registry collection-tag apps: nkp-cli
  tmpdir="$(mktemp -d)"
  "{{ NKP_CLI }}" create catalog-bundle --repo-dir "{{ REPO_ROOT }}" --collection-tag "{{collection-tag}}" --apps="{{apps}}" --output-file "$tmpdir/bundle.tar"
  "{{ NKP_CLI }}" push bundle --bundle "$tmpdir/bundle.tar" --to-registry "{{ registry }}"

# Create airgapped catalog bundle (includes container images and OCI artifacts)
# Usage: just create-airgapped-bundle <collection-tag> [apps]
# Example: just create-airgapped-bundle v2.6.0 "nutanix-ai=2.6.0"
# Example: just create-airgapped-bundle v2.6.0  (bundles all apps)
[script]
create-airgapped-bundle collection-tag apps="": nkp-cli
  tmpdir="$(mktemp -d)"
  if [ -n "{{apps}}" ]; then
    "{{ NKP_CLI }}" create catalog-bundle --repo-dir "{{ REPO_ROOT }}" --collection-tag "{{collection-tag}}" --apps="{{apps}}" --airgapped --output-file "$tmpdir/bundle-airgapped.tar"
  else
    "{{ NKP_CLI }}" create catalog-bundle --repo-dir "{{ REPO_ROOT }}" --collection-tag "{{collection-tag}}" --airgapped --output-file "$tmpdir/bundle-airgapped.tar"
  fi
  mv "$tmpdir/bundle-airgapped.tar" "{{ REPO_ROOT }}/nutanix-product-catalog-{{collection-tag}}-airgapped.tar"
  echo "Created {{ REPO_ROOT }}/nutanix-product-catalog-{{collection-tag}}-airgapped.tar"

# Create airgapped bundle excluding specified app versions
# Usage: just create-airgapped-bundle-skip <collection-tag> <skip>
# Example: just create-airgapped-bundle-skip v2.6.0 "nutanix-ai=2.5.0"
# Example: just create-airgapped-bundle-skip v2.6.0 "nutanix-ai=2.5.0,kserve=0.14.0"
[script]
create-airgapped-bundle-skip collection-tag skip: nkp-cli
  apps_dir="{{ REPO_ROOT }}/applications"
  all_apps=""
  for app_dir in "$apps_dir"/*/; do
    app="$(basename "$app_dir")"
    for ver_dir in "$app_dir"*/; do
      [ -d "$ver_dir" ] || continue
      ver="$(basename "$ver_dir")"
      all_apps="${all_apps}${app}=${ver},"
    done
  done
  all_apps="${all_apps%,}"
  skip_list="$(echo "{{skip}}" | tr ',' '\n' | tr -d ' ')"
  include_apps=""
  for item in $(echo "$all_apps" | tr ',' '\n'); do
    skip=0
    for s in $skip_list; do
      [ "$item" = "$s" ] && skip=1 && break
    done
    [ $skip -eq 0 ] && include_apps="${include_apps}${item},"
  done
  include_apps="${include_apps%,}"
  [ -z "$include_apps" ] && echo "No apps to bundle after skipping" && exit 1
  just create-airgapped-bundle "{{collection-tag}}" "$include_apps"

# Push airgapped bundle to S3 bucket (similar to Kommander release.s3)
# Requires env vars: S3_BUCKET, S3_PATH (optional), AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
# For S3-compatible (MinIO): also set S3_ENDPOINT_URL
# Usage: just push-bundle-to-s3 <collection-tag>
[script]
push-bundle-to-s3 collection-tag:
  bundle_file="{{ REPO_ROOT }}/nutanix-product-catalog-{{collection-tag}}-airgapped.tar"
  if [ ! -f "$bundle_file" ]; then
    echo "Bundle not found. Run: just create-airgapped-bundle {{collection-tag}} [apps]"
    exit 1
  fi
  s3_path="${S3_PATH:-catalog-bundles/}"
  s3_path="${s3_path%/}/"  # ensure trailing slash
  s3_key="${s3_path}nutanix-product-catalog-{{collection-tag}}-airgapped.tar"
  if [ -n "${S3_ENDPOINT_URL:-}" ]; then
    aws s3 cp --endpoint-url "$S3_ENDPOINT_URL" --no-progress "$bundle_file" "s3://${S3_BUCKET}/${s3_key}"
  else
    aws s3 cp --no-progress "$bundle_file" "s3://${S3_BUCKET}/${s3_key}"
  fi
  echo "Published to s3://${S3_BUCKET}/${s3_key}"

# Full pipeline: create airgapped bundle and push to S3
# Usage: just publish-airgapped-bundle <collection-tag> [apps]
publish-airgapped-bundle collection-tag apps="": (create-airgapped-bundle collection-tag apps) (push-bundle-to-s3 collection-tag)

# Full pipeline: create airgapped bundle (excluding skip list) and push to S3
# Usage: just publish-airgapped-bundle-skip <collection-tag> <skip>
publish-airgapped-bundle-skip collection-tag skip: (create-airgapped-bundle-skip collection-tag skip) (push-bundle-to-s3 collection-tag)
