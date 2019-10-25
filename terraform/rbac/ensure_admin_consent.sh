#!/bin/bash

aad_tenant_id=$1
application_id_server=$2
application_id_client=$3
application_secret_server=$4

target_cycle_timeout_seconds=300
sleep_seconds_between_retries=5
max_retries_per_cycle=$(expr $target_cycle_timeout_seconds / $sleep_seconds_between_retries)
ensure_admin_consent_sh_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

application_grant_admin_consent () {
    local application_id=$1
    echo "Granting admin consent for application with id: ${application_id}.."
    local retry_counter=0
    local aad_graph_exception_substring="AADGraphException"
    while : ; do
        local output
        local success
        local propogation_error
        local should_retry
        output=$(az ad app permission admin-consent --id $application_id 2>&1)
        success=$?
        [[ $output = *"${aad_graph_exception_substring}"* ]]
        propogation_error=$?
        [ "$retry_counter" -ne $max_retries_per_cycle ]
        should_retry=$?
        if [ $success -ne 0 ] && [ $propogation_error -ne 0 ]; then
            echo "Failed to grant consent due to unknown error: ${output}"
            echo "Exiting.."
            exit 1
        elif [ $success -ne 0 ] && [ $propogation_error -eq 0 ] && [ $should_retry -ne 0 ]; then
            echo "Max retries exceeded. Exiting.."
            exit 1
        elif [ $success -ne 0 ] && [ $propogation_error -eq 0 ] && [ $should_retry -eq 0 ]; then
            echo "Failed to grant consent due to propogation error. Retrying in ${sleep_seconds_between_retries} seconds.."
            retry_counter=$(expr $retry_counter + 1)
            sleep "${sleep_seconds_between_retries}s"
            continue
        fi
        echo "Successfully granted consent. Continueing.."
        break
    done
}

verify_admin_consent () {
    local aad_tenant_id=$1
    local client_id=$2
    local secret=$3
    local directory_read_all="Directory.Read.All"
    local retry_counter=0
    while : ; do
        local output
        local success
        local has_directory_read_all
        local should_retry
        echo "Requesting token.."
        output=$(request_ms_graph_token $aad_tenant_id $client_id $secret)
        success=$?
        [ $retry_counter -ne $max_retries_per_cycle ]
        should_retry=$?
        echo "Getting encoded jwt.."
        local encoded_jwt=$(printf '%s' $output | jq --raw-output .access_token)
        echo "Decoding jwt.."
        local decoded_jwt=$(bash "${ensure_admin_consent_sh_script_path}/../shared/jwt_decode.sh" $(printf '%s' $encoded_jwt))
        echo "Checking for required role.."
        [[ $decoded_jwt = *"${directory_read_all}"* ]]
        has_directory_read_all=$?
        if [ $success -ne 0 ]; then
            echo "Failed to verify admin consent due to unknown errror: ${output}"
            echo "Exiting.."
            exit 1
        elif [ $has_directory_read_all -ne 0 ] && [ $should_retry -ne 0 ]; then
            echo "Max retries exceeded. Exiting.."
            exit 1
        elif [ $has_directory_read_all -ne 0 ]; then
            echo "Failed to verify consent. Retrying in ${sleep_seconds_between_retries} seconds.."
            retry_counter=$(expr $retry_counter + 1)
            sleep "${sleep_seconds_between_retries}s"
            continue
        fi
        echo "Successfully granted consent. Continueing.."
        break
    done
}

request_ms_graph_token() {
    local aad_tenant_id=$1
    local client_id=$2
    local secret=$3
    local ms_graph_scope="https://graph.microsoft.com/.default"
    local url="https://login.microsoftonline.com/${aad_tenant_id}/oauth2/v2.0/token"
    curl \
        --silent \
        --request POST \
        --url $url  \
        --header "content-type: application/x-www-form-urlencoded" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "scope=${ms_graph_scope}" \
        --data-urlencode "client_id=${client_id}" \
        --data-urlencode "client_secret=${secret}"
}

echo "Granting admin consent.."
application_grant_admin_consent $application_id_server
application_grant_admin_consent $application_id_client

#echo "Verifying admin consent.."
#verify_admin_consent $aad_tenant_id $application_id_server $application_secret_server

echo "Sleeping for 60s.."
sleep 60s

exit 0
