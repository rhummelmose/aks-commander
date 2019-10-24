#!/bin/bash

echo "Verifying Azure CLI.."
az --version > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "Azure CLI is missing. Exiting.."
    exit 1
fi

exit 0
