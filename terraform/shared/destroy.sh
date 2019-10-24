#!/bin/bash

# Exit if anything breaks
set -e

# Sets global variables in the environment
./../../scripts/source_global_variables.sh

# Terraform
terraform init
terraform destroy -var-file=""
