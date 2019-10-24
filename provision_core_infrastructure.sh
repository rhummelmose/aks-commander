#!/bin/bash

# Exit if anything breaks
set -e

# Grab service principal secret (1st parameter, used for Terraform's Azure storage account backend and set in env
export AKSCOMM_TF_BACKEND_CLIENT_SECRET=$1

if [ -z $AKSCOMM_TF_BACKEND_CLIENT_SECRET ]; then
    echo "Service principal secret for Terraform backend not passed as first arrgument.."
    exit 1
fi

# Current scripts path
script_path="$(cd "$(dirname "$0")" && pwd)"

# Terraform apply
bash "${script_path}/terraform/shared/apply.sh" "core"
