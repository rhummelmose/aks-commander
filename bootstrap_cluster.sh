#!/bin/bash

# Exit if anything breaks
set -e

# Arguments
terraform_workspace=$1

# Ensure portability
echo "Ensure portability.."
bootstrap_cluster_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Verify arguments
echo "Verify arguments.."
if [ -z $terraform_workspace ]; then
    echo "Terraform workspace is required as 1st parameter.."
    exit 1
fi

# Verify dependencies
echo "Verify dependencies.."
kubectl version --client
if [ $? -ne 0 ]; then
    echo "kubectl required on PATH.."
    exit 1
fi

helm3 version
if [ $? -ne 0 ]; then
    echo "helm3 required on PATH.."
    exit 1
fi

# Move to aks module directory (required for terraform state command)
echo "Move into aks module directory.."
cd "${bootstrap_cluster_sh_script_path}/terraform/aks"

# Terraform init
echo "Run init script.."
source "${bootstrap_cluster_sh_script_path}/terraform/shared/init.sh" "aks"

# Get resource group and cluster name
terraform workspace select $terraform_workspace
terraform state pull

exit 0


# Get kubectl credentials for cluster from Azure CLI
declare get_credentials_output
get_credentials_output=$(az aks get-credentials --resource-group $resource_group --name $cluster_name --admin)
if [ $? -ne 0 ]; then
    echo "Failed to get administrative credentials for kubectl.."
    printf "Error: %s\n" $get_credentials_output
    exit 1
fi

# Apply API resources
kubectl apply -f "${bootstrap_cluster_sh_script_path}/resources/bootstrap_cluster/rbac.yml" &> bootstrap_cluster.out
kubectl apply -f "${bootstrap_cluster_sh_script_path}/resources/bootstrap_cluster/namespaces.yml" &> bootstrap_cluster.out

# Install Helm charts
nginx_ingress_namespace="nginx-ingress"
helm3 install nginx-ingress stable/nginx-ingress --namespace $nginx_ingress_namespace &> bootstrap_cluster.out

# Export provisioned ingress public IP
declare provisioned_ingress_public_ip
export_provisioned_ingress_public_ip () {
    echo "Exporting provisioned ingress public IP.." &> bootstrap_cluster.out
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
            echo "Failed to export provisioned ingress public ip. Retrying in ${sleep_seconds_between_retries} seconds.." &> bootstrap_cluster.out
            retry_counter=$(expr $retry_counter + 1)
            sleep "${sleep_seconds_between_retries}s"
            continue
        fi
        provisioned_ingress_public_ip="$output"
        echo "Successfully got provisioned ingress public IP ${provisioned_ingress_public_ip}.." &> bootstrap_cluster.out
        break
    done
}

export_provisioned_ingress_public_ip

echo "${provisioned_ingress_public_ip}"
