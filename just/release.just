set unstable

# Release oci artifacts for catalog applications
[no-exit-message]
[script]
publish-artifacts registry collection-tag apps: nkp-cli
  tmpdir="$(mktemp -d)"
  "{{ NKP_CLI }}" create catalog-bundle --repo-dir "{{ REPO_ROOT }}" --collection-tag "{{collection-tag}}" --apps="{{apps}}" --output-file "$tmpdir/bundle.tar"
  "{{ NKP_CLI }}" push bundle --bundle "$tmpdir/bundle.tar" --to-registry "{{ registry }}"
