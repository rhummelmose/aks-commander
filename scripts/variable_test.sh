#!/bin/bash

resource_group=$1
cluster_name=$2
namespace=$3
deployment_targets=$4
azure_devops_pat=$5

if [ -z $resource_group ] || [[ "$resource_group" == '$(resource-group)' ]]; then
    echo "Resource group required as 1st argument.."
    exit 1
fi

if [ -z $cluster_name ] || [[ "$cluster_name" == '$(cluster-name)' ]]; then
    echo "Cluster name required as 2nd argument.."
    exit 1
fi

if [ -z $namespace ] || [[ "$namespace" == '$(namespace)' ]]; then
    echo "Namespace required as 3rd argument.."
    exit 1
fi

declare deployment_targets_json_type
deployment_targets_json_type=$(echo "$deployment_targets" | jq --raw-output 'type')
if [ $? -ne 0 ] || [[ $deployment_targets_json_type != "array" ]]; then
    printf "Invalid deployment targets passed as 4th arrgument: %q ..\n" "$deployment_targets"
    exit 1
fi

if [ -z $azure_devops_pat ]; then
    echo "Azure DevOps PAT required as 5th argument.."
    exit 1
fi

new_variable_value=$(echo $deployment_targets | jq --compact-output '. += [{"resource-group": "'$resource_group'", "cluster-name": "'$cluster_name'", "namespace": "'$namespace'"}]')

export AZURE_DEVOPS_EXT_PAT=$azure_devops_pat
az pipelines variable-group variable update --organization "https://dev.azure.com/rhummelmose" --project aks-commander --group-id 3 --name AKSCOMM_DEPLOYMENT_TARGETS --value "$new_variable_value"
