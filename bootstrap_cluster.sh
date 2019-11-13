#!/bin/bash

# Arguments
terraform_environment=$1
terraform_workspace=$2
terraform_backend_secret=$3

# Ensure portability
echo "Ensure portability.."
bootstrap_cluster_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Verify arguments
echo "Verify arguments.."
if [ -z $terraform_environment ] || [ ! -d "${terraform_sh_script_path}/environments/${terraform_environment}" ]; then
    echo "Please pass an existing environment with --environment=<environment>.."
    exit 1
fi
if [ -z $terraform_workspace ] || [[ "$terraform_workspace" == '$(terraform-workspace)' ]]; then
    echo "Terraform workspace is required as 1st parameter.."
    exit 1
fi

# Grab service principal secret (if passed as argument, used for Terraform's Azure storage account backend and set in env)
source "$bootstrap_cluster_sh_script_path/terraform/shared/source_backend_secret.sh"

# Verify dependencies
echo "Verify dependencies.."
kubectl version --client
if [ $? -ne 0 ]; then
    echo "kubectl required on PATH.."
    exit 1
fi

declare helm3_version_output
helm3_version_output=$(helm3 version)
if [ $? -ne 0 ]; then
    echo "helm3 required on PATH.. Installing if on Linux.."
    # Install Helm v3.0.0-beta.5 if on Linux
    if [[ $(uname) == *"Linux"* ]]; then
        mkdir bootstrap_cluster_sh_helm3_install
        cd bootstrap_cluster_sh_helm3_install
        wget --quiet --output-document="helm3.tar.gz" "https://get.helm.sh/helm-v3.0.0-beta.5-linux-amd64.tar.gz"
        tar -xvf helm3.tar.gz
        sudo mv linux-amd64/helm /usr/local/bin/helm3
        cd ..
        rm -r bootstrap_cluster_sh_helm3_install
    else
        exit 1
    fi
fi

# Move to aks module directory (required for terraform state command)
echo "Move into aks module directory.."
cd "${bootstrap_cluster_sh_script_path}/terraform/aks"

# Terraform init
echo "Run init script.."
source "${bootstrap_cluster_sh_script_path}/terraform/shared/init.sh" "aks"

# Get resource group and cluster name
terraform workspace select $terraform_workspace
terraform state pull > bootstrap_cluster_sh_terraform_aks_remote_state
cluster_name=$(cat bootstrap_cluster_sh_terraform_aks_remote_state | jq --raw-output '.outputs.cluster_name.value')
resource_group=$(cat bootstrap_cluster_sh_terraform_aks_remote_state | jq --raw-output '.outputs.cluster_resource_group_name.value')
rm bootstrap_cluster_sh_terraform_aks_remote_state

# Get kubectl credentials for cluster from Azure CLI
declare get_credentials_output
get_credentials_output=$(az aks get-credentials --overwrite-existing --resource-group $resource_group --name $cluster_name --admin)
if [ $? -ne 0 ]; then
    echo "Failed to get administrative credentials for kubectl.."
    printf "Error: %s\n" $get_credentials_output
    exit 1
fi

# Apply API resources
kubectl apply -f "${bootstrap_cluster_sh_script_path}/environments/${terraform_environment}/kubernetes"

# Install Helm charts
helm3 repo add stable https://kubernetes-charts.storage.googleapis.com/
helm3 repo update
nginx_ingress_namespace="nginx-ingress"
helm3 install nginx-ingress stable/nginx-ingress --namespace $nginx_ingress_namespace

# Export provisioned ingress public IP
declare provisioned_ingress_public_ip
export_provisioned_ingress_public_ip () {
    echo "Exporting provisioned ingress public IP.."
    local max_retries=10
    local sleep_seconds_between_retries=5
    local retry_counter=0
    while : ; do
        local output
        local success
        local max_retries_exceeded
        output=$(kubectl --namespace $nginx_ingress_namespace get services -o jsonpath='{.status.loadBalancer.ingress[0].ip}' nginx-ingress-controller)
        success=$?
        [ $retry_counter -eq $max_retries ]
        max_retries_exceeded=$?
        if [ $success -ne 0 ] || [ -z $output  ] && [ $max_retries_exceeded -eq 0 ]; then
            echo "Failed to export provisioned ingress public ip."
            printf "Output: %s\n" $output
            echo "Exiting.."
            exit 1
        elif [ $success -ne 0 ] || [ -z $output  ] && [ $max_retries_exceeded -ne 0 ]; then
            echo "Failed to export provisioned ingress public ip. Retrying in ${sleep_seconds_between_retries} seconds.."
            retry_counter=$(expr $retry_counter + 1)
            sleep "${sleep_seconds_between_retries}s"
            continue
        fi
        provisioned_ingress_public_ip="$output"
        echo "Successfully got provisioned ingress public IP ${provisioned_ingress_public_ip}.."
        break
    done
}

export_provisioned_ingress_public_ip

echo "${provisioned_ingress_public_ip}"
