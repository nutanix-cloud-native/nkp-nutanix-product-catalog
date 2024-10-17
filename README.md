# Overview

This catalog repository holds all the Nutanix Products and their respective version HelmRepositories and HelmReleases.

# Receipes

## How to create catalog on your management cluster?
<pre>
nkp create catalog nutanix-product-apps-catalog \
    -w WORKSPACE_NAME \
    --branch CATALOG_RELEASE_BRANCH_NAME \
    --url https://github.com/nutanix-cloud-native/nkp-nutanix-product-catalog
</pre>

## How to list all the catalogs on management cluster?
<pre>
kubectl get gitrepository -n WORKSPACE_NAMESPACE
</pre>
you can get WORKSPACE_NAMESPACE by running following command
<pre>
nkp get workspaces
</pre>

## How to list all the apps provided by added catalogs on management cluster?
<pre>
kubectl get apps -n WORKSPACE_NAMESPACE
</pre>

## How to install catalog app?
To install catalog app say nutanix-ai on cluster CLUSTER_NAME, create following appDeployment instance
<pre>
apiVersion: apps.kommander.d2iq.io/v1alpha3
kind: AppDeployment
metadata:
  name: APP_DEPLOYMENT_NAME
  namespace: WORKSPACE_NAMESPACE
spec:
  appRef:
    kind: App
    name: nutanix-ai-1.0.0
  clusterSelector:
    matchExpressions:
    - key: kommander.d2iq.io/cluster-name
      operator: In
      values:
      - CLUSTER_NAME
  configOverrides:
    name: nutanix-ai-1-config-overrides
</pre>

you can create following configmap to pass the helm values to the nutanix-ai helm chart
<pre>
apiVersion: v1
data:
  values.yaml: |
    imagePullSecret:
      # Name of the image pull secret
      name: nai-iep-secret
      # Image registry credentials
      credentials:
        registry: https://index.docker.io/v1/
        username: USERNAME
        password: PASSWORD
        email: EMAIL
    naiApi:
      # NAI API image details
      naiApiImage:
        # The name of the NAI API Docker image
        image: docker.io/nutanix/nai-api
        # The tag of the Docker image to be used
        tag: v1.0.0-rc2
    storageClassName: nai-nfs-storage
kind: ConfigMap
metadata:
  name: nutanix-ai-1-config-overrides
  namespace: WORKSPACE_NAMESPACE
</pre>
pre and post steps for this app can be found in the rerspective app's metadata.yaml overview yaml node.

## How to Uninstall catalog app?
On management cluster, run following:
<pre>
kubectl delete appDeployment APP_DEPLOYMENT_NAME -n WORKSPACE_NAMESPACE
</pre>

## How to delete catalog from your management cluster?
<pre>
kubectl delete gitrepository nutanix-product-apps-catalog -n WORKSPACE_NAMESPACE
</pre>

For more details, you can refer to Nutanix Portal for Nutanix Kubernetes Platform documentation.