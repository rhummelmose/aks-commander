#!/bin/bash

# Get terraform relative path
terraform_module=$1

# Ensure portability
init_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install Terraform 0.12.12 if on Linux
if [[ $(uname) == *"Linux"* ]] && [[ $(terraform version) != *"v0.12.13"* ]]; then
    mkdir temp_terraform_install
    cd temp_terraform_install
    wget --quiet --output-document="terraform.zip" "https://releases.hashicorp.com/terraform/0.12.13/terraform_0.12.13_linux_amd64.zip"
    unzip -o terraform.zip
    sudo mv terraform /usr/local/bin/
    cd ..
    rm -r temp_terraform_install
fi

# Sets global variables in the environment
set -o allexport
source "${init_sh_script_path}/../../environments/${terraform_environment}/terraform_backend.env"
source "${init_sh_script_path}/../../environments/${terraform_environment}/terraform_global.env"
set +o allexport

# Source from env set either locally via IDE or CI/CD
# backend_client_secret=$AKSCOMM_TF_BACKEND_CLIENT_SECRET

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

source_tfvars "${init_sh_script_path}/../../environments/${terraform_environment}/terraform_${terraform_module}.tfvars"
declare azure_cli_target_subscription
if [ ! -z $subscription_id ]; then
    azure_cli_target_subscription=$subscription_id
elif [ ! -z $tenant_id ]; then
    azure_cli_target_subscription=$(az account list --query "[?tenantId == '${tenant_id}'] | [0].id" --output tsv)
else
    azure_cli_target_subscription=$TF_VAR_subscription_id
fi

echo "Set Azure CLI account.."
az account set --subscription $azure_cli_target_subscription

# If we're running on Azure DevOps, we have to get credentials from env vars
if [ ! -z $servicePrincipalId ]; then
    export ARM_CLIENT_ID=$servicePrincipalId
fi

if [ ! -z $servicePrincipalKey ]; then
    export ARM_CLIENT_SECRET=$servicePrincipalKey
fi

if [ ! -z $tenantId ]; then
    export ARM_TENANT_ID=$tenantId
    export ARM_SUBSCRIPTION_ID=$(az account show --query 'id' --output tsv)
fi

# Set terraform backend container name according to environment
export TF_VAR_tf_backend_container_name="${terraform_environment}-tfstate"
declare storage_account_exists
storage_account_exists=$(az storage account show --name "$TF_VAR_tf_backend_storage_account_name")
if [ $? -ne "0" ]; then
    echo "Storage account for Terraform backend not found.."
    exit 1
fi
declare storage_account_container_exists
storage_account_container_exists=$(az storage container show --account-name "$TF_VAR_tf_backend_storage_account_name" --name "$TF_VAR_tf_backend_container_name")
if [ $? -ne "0" ]; then
    az storage container create --account-name "$TF_VAR_tf_backend_storage_account_name" --name "$TF_VAR_tf_backend_container_name"
fi

# Terraform (Pass 1 to init due to: https://github.com/hashicorp/terraform/issues/21393)
echo "Do Terraform init.."
echo '1' | terraform init \
    -reconfigure \
    -backend-config="resource_group_name=${TF_VAR_tf_backend_resource_group_name}" \
    -backend-config="storage_account_name=${TF_VAR_tf_backend_storage_account_name}" \
    -backend-config="container_name=${TF_VAR_tf_backend_container_name}" \
    "${init_sh_script_path}/../${terraform_module}"
