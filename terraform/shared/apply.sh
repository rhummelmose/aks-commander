#!/bin/bash

# Exit if anything breaks
set -e

# Get terraform relative path
terraform_relative_path=$1

# Ensure portability
scripts_path="$(cd "$(dirname "$0")" && pwd)"

# Sets global variables in the environment
source "${scripts_path}/source_global_variables.sh"

# Terraform init
source "${scripts_path}/init.sh" $terraform_relative_path

terraform apply -auto-approve -var-file="${scripts_path}/../${terraform_relative_path}/terraform.tfvars" "${scripts_path}/../${terraform_relative_path}"
