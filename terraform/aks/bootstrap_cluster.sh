#!/bin/bash

# Exit if anything breaks
set -e

resource_group=$1
cluster_name=$2
bootstrap_cluster_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z $resource_group ]; then
    echo "Resource group required as 1st parameter.."
    exit 1
fi

if [ -z $cluster_name ]; then
    echo "Cluster name required as 2nd parameter.."
    exit 1
fi

kubectl version >> /dev/null
if [ $? -ne 0 ]; then
    echo "kubectl required on PATH.."
    exit 1
fi

helm version >> /dev/null
if [ $? -ne 0 ]; then
    echo "helm required on PATH.."
    exit 1
fi

declare get_credentials_output
get_credentials_output=$(az aks get-credentials --resource-group $resource_group --name $cluster_name --admin)
if [ $? -ne 0 ]; then
    echo "Failed to get administrative credentials for kubectl.."
    printf "Error: %s\n" $get_credentials_output
    exit 1
fi

# Apply API resources
kubectl apply -f "${bootstrap_cluster_sh_script_path}/rbac.yml" &> bootstrap_cluster.out
kubectl apply -f "${bootstrap_cluster_sh_script_path}/namespaces.yml" &> bootstrap_cluster.out

# Install Helm charts
nginx_ingress_namespace="nginx-ingress"
helm install nginx-ingress stable/nginx-ingress --namespace $nginx_ingress_namespace &> bootstrap_cluster.out

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
