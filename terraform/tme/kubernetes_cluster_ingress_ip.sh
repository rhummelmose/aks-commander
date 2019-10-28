#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Ensure portability
echo "Ensure portability.."
kubernetes_cluster_ingress_ip_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Extract Terraform workspace from JSON passed to stdin
eval "$(jq -r '@sh "terraform_workspace=\(.workspace) aks_cluster_name=\(.aks_cluster_name) aks_cluster_resource_group_name=\(.aks_cluster_resource_group_name)"')"

# Verify arguments
echo "Verify arguments.."
if [ -z $terraform_workspace ]; then
    echo "Terraform workspace is required as parameter workspace.."
    exit 1
fi
if [ -z $aks_cluster_name ]; then
    echo "AKS cluster name is required as parameter aks_cluster_name.."
    exit 1
fi
if [ -z $aks_cluster_resource_group_name ]; then
    echo "AKS resource group name is required as parameter aks_cluster_resource_group_name.."
    exit 1
fi

# Verify dependencies
echo "Verify dependencies.."
kubectl version --client
if [ $? -ne 0 ]; then
    echo "kubectl required on PATH.."
    exit 1
fi

# Get kubectl credentials for cluster from Azure CLI
declare get_credentials_output
get_credentials_output=$(az aks get-credentials --resource-group $aks_cluster_resource_group_name --name $aks_cluster_name --admin)
if [ $? -ne 0 ]; then
    echo "Failed to get administrative credentials for kubectl.."
    printf "Error: %s\n" $get_credentials_output
    exit 1
fi

kubernetes_ingress_ip=output=$(kubectl --namespace nginx-ingress get services -o jsonpath='{.status.loadBalancer.ingress[0].ip}' nginx-ingress-controller)

# Safely produce a JSON object containing the result value.
jq -n \
    --arg kubernetes_ingress_ip "$kubernetes_ingress_ip" \
    --arg terraform_workspace "$terraform_workspace" \
    --arg aks_cluster_name "$aks_cluster_name" \
    --arg aks_cluster_resource_group_name "$aks_cluster_resource_group_name" \
    '{"kubernetes_ingress_ip":$kubernetes_ingress_ip,"terraform_workspace":$terraform_workspace,"aks_cluster_name":$aks_cluster_name,"aks_cluster_resource_group_name":$aks_cluster_resource_group_name}'
