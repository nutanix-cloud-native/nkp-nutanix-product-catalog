ARTIFACT_BUNDLE := REPO_ROOT+"/nkp-partner-catalog.tar"
OCI_REGISTRY := "ghcr.io/nutanix-cloud-native"

create-publish-artifacts: nkp-cli
  [ -z "${COLLECTION_TAG:-}" ] && echo "COLLECTION_TAG environment variable is not set" && exit 1; \
  echo "ARTIFACT_CONSTRAINT: ${ARTIFACT_CONSTRAINT:-}" && \
  echo "ARTIFACT_APPS: ${ARTIFACT_APPS:-}" && \
  echo "COLLECTION_TAG: ${COLLECTION_TAG:-}" && \
  [ -n "${ARTIFACT_APPS:-}" ] && [ -n "${ARTIFACT_CONSTRAINT:-}" ] && echo "Only one of ARTIFACT_APPS or ARTIFACT_CONSTRAINT may be set" && exit 1; \
  "{{ NKP_CLI }}" create catalog-bundle --repo-dir "{{ REPO_ROOT }}" --collection-tag ${COLLECTION_TAG} ${ARTIFACT_APPS:+--apps=${ARTIFACT_APPS}} ${ARTIFACT_CONSTRAINT:+--constraint=${ARTIFACT_CONSTRAINT}} && \
  "{{ NKP_CLI }}" push bundle --bundle "{{ ARTIFACT_BUNDLE }}" --to-registry "{{ OCI_REGISTRY }}"
