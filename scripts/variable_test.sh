#!/bin/bash

variable_group_name=$1
variable_name=$2
resource_group=$3
cluster_name=$4
namespace=$5
azure_devops_pat=$6

if [ -z $variable_group_name ]; then
    echo "Variable group name required as 1st argument.."
    exit 1
fi

if [ -z $variable_name ]; then
    echo "Variable name required as 2nd argument.."
    exit 1
fi

if [ -z $resource_group ] || [[ "$resource_group" == '$(resource-group)' ]]; then
    echo "Resource group required as 3rd argument.."
    exit 1
fi

if [ -z $cluster_name ] || [[ "$cluster_name" == '$(cluster-name)' ]]; then
    echo "Cluster name required as 4th argument.."
    exit 1
fi

if [ -z $namespace ] || [[ "$namespace" == '$(namespace)' ]]; then
    echo "Namespace required as 5th argument.."
    exit 1
fi

if [ -z $azure_devops_pat ]; then
    echo "Azure DevOps PAT required as 5th argument.."
    exit 1
fi

# Credentials
export AZURE_DEVOPS_EXT_PAT=$azure_devops_pat

# Ensure the Azure DevOps extension is installed
az extension add --name azure-devops

# Get the variable group id
echo $variable_group_name
variable_group_id=$(az pipelines variable-group list --organization $SYSTEM_TEAMFOUNDATIONCOLLECTIONURI --project $SYSTEM_TEAMPROJECT | jq --arg variable_group_name "$variable_group_name" '.[] | select(.name == $variable_group_name) | .id')
echo $variable_group_id

# Old variable value
old_variable_value=$(az pipelines variable-group variable list --organization $SYSTEM_TEAMFOUNDATIONCOLLECTIONURI --project $SYSTEM_TEAMPROJECT --group-id $variable_group_id | jq --raw-output ".$variable_name.value")

new_variable_value=$(echo $old_variable_value | jq --compact-output 'fromjson | . += [{"resource-group": "'$resource_group'", "cluster-name": "'$cluster_name'", "namespace": "'$namespace'"}] | tojson')
echo $new_variable_value

az pipelines variable-group variable update --organization $SYSTEM_TEAMFOUNDATIONCOLLECTIONURI --project $SYSTEM_TEAMPROJECT --group-id $variable_group_id --name AKSCOMM_DEPLOYMENT_TARGETS --value "$new_variable_value"
