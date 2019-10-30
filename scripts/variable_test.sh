#!/bin/bash

resource_group=$1
cluster_name=$2
namespace=$3
deployment_targets=$4

if [ -z $deployment_targets ]; then
    deployment_targets=$AKSCOMM_DEPLOYMENT_TARGETS
fi

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
deployment_targets_json_type=$(echo "$AKSCOMM_DEPLOYMENT_TARGETS" | jq --raw-output 'type')
if [ $? -ne 0 ] && [[ $deployment_targets_json_type != "array" ]]; then
    printf "Invalid value in AKSCOMM_DEPLOYMENT_TARGETS: %q ..\n" $AKSCOMM_DEPLOYMENT_TARGETS
    exit 1
fi

new_variable_value=$(echo $deployment_targets | jq --compact-output '. += [{"resource-group": "'$resource_group'", "cluster-name": "'$cluster_name'", "namespace": "'$namespace'"}]')

echo "##vso[task.setvariable variable=AKSCOMM_DEPLOYMENT_TARGETS]$new_variable_value"
