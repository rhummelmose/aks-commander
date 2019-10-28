#!/bin/bash

if [ ! -z $terraform_backend_secret ]; then
    export AKSCOMM_TF_BACKEND_CLIENT_SECRET=$terraform_backend_secret
fi
if [ -z $AKSCOMM_TF_BACKEND_CLIENT_SECRET ]; then
    echo "Service principal secret for Terraform backend was neither passed as argument or set in env .."
    exit 1
fi
