export KUBECONFIG="$HOME/mirko-nkp.conf"
: "${ART_USER:?Set ART_USER to the Artifactory username}"
: "${ART_TOKEN:?Set ART_TOKEN to the Artifactory token}"
: "${PC_USER:?Set PC_USER to the Prism Central username}"
: "${PC_PASSWORD:?Set PC_PASSWORD to the Prism Central password}"

rm -rf "$HOME/dl-work"
mkdir -p "$HOME/dl-work/dl-prereqs"
cd "$HOME/dl-work/dl-prereqs"

# Install the Canaveral CA on NKP nodes.
curl -fsSLO \
  http://canaveral-gatekeeper.canaveral-corp.us-west-2.aws/ca/root-ca.crt

curl -fsSLO \
  http://canaveral-gatekeeper.canaveral-corp.us-west-2.aws/ca/intermediate-ca.crt

cat intermediate-ca.crt root-ca.crt > canaveral-ca.crt

gh api \
  -H 'Accept: application/vnd.github.raw' \
  'repos/nutanix-core/k8s-juno/contents/package/artifactory_certs/daemonset.yaml?ref=artifactory_helper' \
  > daemonset.yaml

kubectl apply -f daemonset.yaml

# Do not start the application until every Artifactory DaemonSet has completed.
while read -r namespace name; do
  [ -n "$namespace" ] || continue
  kubectl -n "$namespace" rollout status "daemonset/$name" --timeout=5m
done < <(
  kubectl get daemonset -A --no-headers |
    awk 'tolower($2) ~ /artifactory/ {print $1, $2}'
)

# Create namespaces so prerequisite Secrets can be created.
kubectl create namespace data-lens \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace ndh-core \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label namespace data-lens \
  app.kubernetes.io/managed-by=Helm \
  --overwrite

kubectl label namespace ndh-core \
  app.kubernetes.io/managed-by=Helm \
  --overwrite

kubectl annotate namespace data-lens \
  meta.helm.sh/release-name=datahub \
  meta.helm.sh/release-namespace=kommander \
  kustomize.toolkit.fluxcd.io/prune=disabled \
  --overwrite

kubectl annotate namespace ndh-core \
  meta.helm.sh/release-name=datahub \
  meta.helm.sh/release-namespace=kommander \
  kustomize.toolkit.fluxcd.io/prune=disabled \
  --overwrite

# Data Lens image-pull Secret.
kubectl -n data-lens create secret docker-registry \
  datahub-1-artifactory-pull \
  --docker-server=artifactory.dyn.ntnxdpro.com \
  --docker-username="$ART_USER" \
  --docker-password="$ART_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# NDH image-pull Secret for both private registries.
export DOCKER_AUTH_CONFIG="$(
python3 - <<'PY'
import base64
import json
import os

user = os.environ["ART_USER"]
token = os.environ["ART_TOKEN"]
auth = base64.b64encode(f"{user}:{token}".encode()).decode()

print(json.dumps({
    "auths": {
        "artifactory.dyn.ntnxdpro.com": {
            "username": user,
            "password": token,
            "auth": auth
        },
        "artifactory-edge-01.corp.p10y.ntnxdpro.com": {
            "username": user,
            "password": token,
            "auth": auth
        }
    }
}))
PY
)"

kubectl -n ndh-core create secret generic ndh-iep-secret \
  --type=kubernetes.io/dockerconfigjson \
  --from-literal=.dockerconfigjson="$DOCKER_AUTH_CONFIG" \
  --dry-run=client -o yaml | kubectl apply -f -

# Prism Central authentication for the compatibility proxy.
PC_BASIC_AUTH="$(
  printf '%s:%s' "$PC_USER" "$PC_PASSWORD" | base64 -w0
)"

kubectl -n data-lens create secret generic dl-pc-proxy-auth \
  --from-literal=auth.conf="proxy_set_header Authorization \"Basic $PC_BASIC_AUTH\";" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n data-lens get secret \
  datahub-1-artifactory-pull \
  dl-pc-proxy-auth

kubectl -n ndh-core get secret ndh-iep-secret

kubectl get nodes
