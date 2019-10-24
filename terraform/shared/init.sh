#!/bin/bash

# Exit if anything breaks
set -e

# Get terraform relative path
terraform_relative_path=$1

# Ensure portability
scripts_path="$(cd "$(dirname "$0")" && pwd)"

# Source from env set either locally via IDE or CI/CD
backend_client_secret=$AKSCOMM_TF_BACKEND_CLIENT_SECRET

# Set Azure CLI subscription (hidden requirement on the Azure AD Terraform resource provider)

## tfvars assignments
# takes *.tfvars and assigns env=value
# - works with terraform 0.6 types: string, map
# - map.key becomes map_key
function source_tfvars() {
    eval "$(
        awk 'BEGIN {FS=OFS="="}
        !/^(#| *$)/ && /^.+=.+$/ {
            gsub(/^[ \t]+|[ \t]+$/, "", $1);
            gsub(/\./, "_", $1);
            gsub(/^[ \t]+|[ \t]+$/, "", $2);
            if ($1 && $2) print $0
        }' "$@"
    )"
}

source_tfvars "${scripts_path}/../${terraform_relative_path}/terraform.tfvars"
declare azure_cli_target_subscription
if [ ! -z $subscription_id ]; then
    azure_cli_target_subscription=$subscription_id
elif [ ! -z $tenant_id ]; then
    azure_cli_target_subscription=$(az account list --query "[?tenantId == '${tenant_id}'] | [0].id" --output tsv)
else
    azure_cli_target_subscription=$TF_VAR_subscription_id
fi

az account set --subscription $azure_cli_target_subscription

# Terraform
terraform init \
    -backend-config="tenant_id=${TF_VAR_tf_backend_tenant_id}" \
    -backend-config="client_id=${TF_VAR_tf_backend_client_id}" \
    -backend-config="subscription_id=${TF_VAR_tf_backend_subscription_id}" \
    -backend-config="resource_group_name=${TF_VAR_tf_backend_resource_group_name}" \
    -backend-config="storage_account_name=${TF_VAR_tf_backend_storage_account_name}" \
    -backend-config="container_name=${TF_VAR_tf_backend_container_name}" \
    -backend-config="client_secret=${backend_client_secret}" \
    "${scripts_path}/../${terraform_relative_path}"
