# Nutanix NKP Product Catalog

All source code and other contents in this repository are covered by the Nutanix License and Services Agreement, which is located at https://www.nutanix.com/legal/eula 

# Overview

This catalog repository holds all the Nutanix Products and their respective version HelmRepositories and HelmReleases.

# Receipes

## How to list all the catalogs on management cluster?
<pre>
kubectl get ocirepository -n <workspace_namespace>
</pre>
you can get workspace_namespace by running following command
<pre>
nkp get workspaces
</pre>

## How to list all the apps provided by added catalogs on management cluster?
<pre>
kubectl get apps -n <workspace_namespace>
</pre>

For more details, you can refer to Nutanix Portal for Nutanix Kubernetes Platform documentation.