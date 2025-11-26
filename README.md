# Nutanix NKP Product Catalog

All source code and other contents in this repository are covered by the Nutanix License and Services Agreement, which is located at https://www.nutanix.com/legal/eula

# Overview

This catalog repository holds all the Nutanix Products and their respective version OCIRepositories and HelmReleases.

# Recipes

## How to list all the catalog applications and collections on management cluster?
<pre>
kubectl get ocirepository -A -l catalog.nkp.nutanix.com/catalog-source-artifact=true
</pre>

## How to list all the apps provided by added catalogs on management cluster?
<pre>
kubectl get apps -A
</pre>

For more details, you can refer to Nutanix Portal for Nutanix Kubernetes Platform documentation.
