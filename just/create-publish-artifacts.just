ARTIFACT_BUNDLE := REPO_ROOT+"/nkp-nutanix-product-catalog.tar"

create-publish-artifacts OCI_REGISTRY COLLECTION_TAG ARTIFACT_CONSTRAINT ARTIFACT_APPS: nkp-cli
  [ -z "{{COLLECTION_TAG}}" ] && echo "COLLECTION_TAG is required" && exit 1; \
  [ -z "{{OCI_REGISTRY}}" ] && echo "OCI_REGISTRY is required" && exit 1; \
  [ -n "{{ARTIFACT_APPS}}" ] && [ -n "{{ARTIFACT_CONSTRAINT}}" ] && echo "Only one of ARTIFACT_APPS or ARTIFACT_CONSTRAINT may be set" && exit 1; \
  "{{NKP_CLI}}" create catalog-bundle \
  --repo-dir "{{REPO_ROOT}}" \
  --collection-tag "{{COLLECTION_TAG}}" \
  $( [ -n "{{ARTIFACT_APPS}}" ] && echo "--apps={{ARTIFACT_APPS}}" ) \
  $( [ -n "{{ARTIFACT_CONSTRAINT}}" ] && echo "--constraint={{ARTIFACT_CONSTRAINT}}" ) && \
  "{{ NKP_CLI }}" push bundle --bundle "{{ ARTIFACT_BUNDLE }}" --to-registry "{{ OCI_REGISTRY }}"
