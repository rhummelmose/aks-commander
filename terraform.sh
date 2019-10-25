#!/bin/bash

# Exit if anything breaks
set -e

# Collect arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --action=*)
      terraform_action="${1#*=}"
      ;;
    --module=*)
      terraform_module="${1#*=}"
      ;;
    --workspace=*)
      terraform_workspace="${1#*=}"
      ;;
    --backend-secret=*)
      terraform_backend_secret="${1#*=}"
      ;;
    *)
      printf "****************************\n"
      printf "* Error: Invalid argument. *\n"
      printf "****************************\n"
      exit 1
  esac
  shift
done

# Ensure required arguments
if [ -z $terraform_action ]; then
    echo "Please pass the terraform action name with --action=apply/destroy .."
    exit 1
fi
if [ -z $terraform_module ] || ! [[ "$terraform_module" =~ ^(core|rbac|aks|tme)$ ]]; then
    echo "Please pass the terraform module name with --module=core/rbac/aks/tme .."
    exit 1
fi

# Grab service principal secret (2nd parameter if not set in env, used for Terraform's Azure storage account backend and set in env
if [ ! -z $terraform_backend_secret ]; then
    export AKSCOMM_TF_BACKEND_CLIENT_SECRET=$terraform_backend_secret
fi
if [ -z $AKSCOMM_TF_BACKEND_CLIENT_SECRET ]; then
    echo "Service principal secret for Terraform backend was neither passed as argument or set in env .."
    exit 1
fi

# Ensure portability
terraform_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Terraform init
source "${terraform_sh_script_path}/terraform/shared/init.sh" $terraform_module

terraform "${terraform_action}" -auto-approve -var-file="${terraform_sh_script_path}/terraform_${terraform_module}.tfvars" "${terraform_sh_script_path}/terraform/${terraform_module}"

