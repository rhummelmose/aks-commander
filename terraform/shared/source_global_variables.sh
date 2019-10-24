#!/bin/bash

### RESOURCE PROVISIONING
export TF_VAR_prefix="aks-commander"
export TF_VAR_region="westeurope"
export TF_VAR_tenant_id="72f988bf-86f1-41af-91ab-2d7cd011db47" # microsoft.com
export TF_VAR_subscription_id="eabef2b9-8358-462c-a10a-f3691e1c83a6" # rahummel-subscription-microsoft-internal
export TF_VAR_subdomain="aks-commander"
export TF_VAR_domain="cloudnativegbb.com"

### TERRAFORM BACKEND
export TF_VAR_tf_backend_tenant_id="72f988bf-86f1-41af-91ab-2d7cd011db47" # microsoft.com
export TF_VAR_tf_backend_client_id="7a4e19af-73ea-4d66-8d4f-6ccc05d3baf2" # rahummel-terraform-provisioner
export TF_VAR_tf_backend_client_secret=$AKSCOMM_TF_BACKEND_CLIENT_SECRET
export TF_VAR_tf_backend_subscription_id="eabef2b9-8358-462c-a10a-f3691e1c83a6" # rahummel-subscription-microsoft-internal
export TF_VAR_tf_backend_resource_group_name="terraform-rg"
export TF_VAR_tf_backend_storage_account_name="rahummelterraformstorage"
export TF_VAR_tf_backend_container_name="aks-commander-tfstate"
