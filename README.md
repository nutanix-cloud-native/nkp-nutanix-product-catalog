# Nutanix NKP Product Catalog

All source code and other contents in this repository are covered by the Nutanix License and Services Agreement, which is located at https://www.nutanix.com/legal/eula 

# Overview

This catalog repository holds all the Nutanix Products and their respective version HelmRepositories and HelmReleases.

# Receipes

## How to create catalog on your management cluster?
<pre>
nkp create catalog nutanix-product-apps-catalog \
    -w <workspace_name> \
    --branch <catalog-release-branch-name> \
    --url https://github.com/nutanix-cloud-native/nkp-nutanix-product-catalog
</pre>

## How to list all the catalogs on management cluster?
<pre>
kubectl get gitrepository -n <workspace_namespace>
</pre>
you can get workspace_namespace by running following command
<pre>
nkp get workspaces
</pre>

## How to list all the apps provided by added catalogs on management cluster?
<pre>
kubectl get apps -n <workspace_namespace>
</pre>

## How to install catalog app?
<pre>
</pre>

## How to delete catalog from your management cluster?
<pre>
kubectl delete gitrepository nutanix-product-apps-catalog -n <workspace_namespace>
</pre>

For more details, you can refer to Nutanix Portal for Nutanix Kubernetes Platform documentation.