#!/bin/bash

# Globals
debug_file_name="deployment_targets_for_application.debug"

# Get and verify arguments
application_repository=$1

if [ -z "$application_repository" ]; then
    echo "Application repository required as 1st argument.."
    exit 1
fi

# Initialize return value
deployment_targets=$(echo [] | jq .)

# Ensure portability
deployment_targets_for_application_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Find target environments
target_environments=$(echo [] | jq .)
for environment_path in ${deployment_targets_for_application_sh_script_path}/../environments/*/ ; do
    environment=$(basename "$environment_path")
    applications_json=$(yq read --tojson "${environment_path}/applications.yml")
    num_matching_applications=$(echo $applications_json | jq --arg application_repository $application_repository '.applications | map(select(.repository == $application_repository)) | length')
    if [ "$num_matching_applications" -gt "0" ]; then
        target_environments=$(echo $target_environments | jq --arg environment "$environment" '. += [$environment]')
    fi
done

# If no target environments, return empty array
num_target_environments=$(echo "$target_environments" | jq 'length')
if [ "$num_target_environments" -eq "0" ]; then
    echo "$deployment_targets" | jq .
    exit 0
fi

# Move to aks module directory (required for terraform state command)
cd "${deployment_targets_for_application_sh_script_path}/../terraform/aks"

# Loop over all target environments, their workspaces and extract cluster information
for environment in $(echo $target_environments | jq --raw-output '@tsv'); do
    
    echo "Handling environment: ${environment}" >> $debug_file_name

    # Terraform init
    source "${deployment_targets_for_application_sh_script_path}/../terraform/shared/init.sh" "$environment" "aks" >> $debug_file_name

    # Get loopable list of workspaces
    # NOTE THIS IS DANGEROUS AND WILL LIKELY BREAK IN FUTURE VERSION OF TERRAFORM
    workspaces=$(terraform workspace list | tr -d ' *')
    for workspace in $workspaces; do
    
        echo "Handling workspace: ${workspace}" >> $debug_file_name

        # Get resource group and cluster name
        terraform workspace select $workspace >> $debug_file_name 2>&1
        remote_state=$(terraform state pull)
        cluster_name=$(echo $remote_state | jq --raw-output '.outputs.cluster_name.value')
        resource_group=$(echo $remote_state | jq --raw-output '.outputs.cluster_resource_group_name.value')

        echo "Cluster name: ${cluster_name}" >> $debug_file_name
        echo "Resource group: ${resource_group}" >> $debug_file_name

        if [ "$cluster_name" != "null" ] && [ "$resource_group" != "null" ]; then
            deployment_targets=$(echo $deployment_targets | \
                jq --arg resource_group $resource_group --arg cluster_name $cluster_name \
                '. += [{"resource-group": $resource_group, "cluster-name": $cluster_name}]')
        fi

    done

done

echo $deployment_targets | jq .

exit 0
