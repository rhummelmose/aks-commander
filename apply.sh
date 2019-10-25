#!/bin/bash

# Exit if anything breaks
set -e

# Get terraform module
terraform_module=$1
if [ -z $terraform_module ]; then
    echo "Please pass the terraform module name as the first parameter.."
    exit 1
fi

# Grab service principal secret (2nd parameter if not set in env, used for Terraform's Azure storage account backend and set in env
if [ ! -z $2 ]; then
    export AKSCOMM_TF_BACKEND_CLIENT_SECRET=$2
fi
if [ -z $AKSCOMM_TF_BACKEND_CLIENT_SECRET ]; then
    echo "Service principal secret for Terraform backend not passed as first arrgument.."
    exit 1
fi

# Ensure portability
apply_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Terraform init
source "${apply_sh_script_path}/terraform/shared/init.sh" $terraform_module

terraform apply -auto-approve -var-file="${apply_sh_script_path}/terraform_${terraform_module}.tfvars" "${apply_sh_script_path}/terraform/${terraform_module}"
