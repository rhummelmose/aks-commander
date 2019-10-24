#!/bin/bash

target_cycle_timeout_seconds=15
sleep_seconds_between_retries=5
max_retries_per_cycle=$(expr $target_cycle_timeout_seconds / $sleep_seconds_between_retries)

verify_service_principal () {
    local service_principal_id=$1
    echo "Ensuring service principal with id: ${service_principal_id}.."
    local retry_counter=0
    while : ; do
        az ad sp show --id $service_principal_id --output none > /dev/null 2>&1
        if [ "$?" -eq 0 ]; then
            echo "Found service principal. Continueing.."
            break
        fi
        if [ "$retry_counter" -eq $max_retries_per_cycle ]; then
            echo "Max retries exceeded. Exiting.."
            exit 1
        fi
        echo "Couldn't find service principal. Retrying in ${sleep_seconds_between_retries} seconds.."
        retry_counter=$(expr $retry_counter + 1)
        sleep "${sleep_seconds_between_retries}s"
    done
}

for service_principal_id in "$@"
do
    verify_service_principal $service_principal_id
done
