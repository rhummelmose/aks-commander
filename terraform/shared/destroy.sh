#!/bin/bash

# Exit if anything breaks
set -e

# Get terraform relative path
terraform_relative_path=$1

# Ensure portability
scripts_path="$(cd "$(dirname "$0")" && pwd)"

# Terraform init
source "${scripts_path}/init.sh" $terraform_relative_path

terraform destroy -auto-approve -var-file="${scripts_path}/../${terraform_relative_path}/terraform.tfvars" "${scripts_path}/../${terraform_relative_path}"
