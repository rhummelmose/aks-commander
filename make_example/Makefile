TFVARS			?="${PROJECT_DIR}/terraform.tfvars"

ENVCODE			?=$(shell grep -e '^env_code\s*=' ${TFVARS} | cut -d"=" -f2 | tr -d '" ' )
ENVCODE_UPPER		?=$(shell echo ${ENVCODE} | tr [a-z] [A-Z])
PROJECT			?=$(shell grep -e '^cluster_name\s*=' ${TFVARS} | cut -d"=" -f2 | tr -d '" ' )
PROJECT_UPPER		?=$(shell echo ${PROJECT} | tr [a-z] [A-Z])
LOCATION		?=$(shell grep -e '^location\s*=' ${TFVARS} | cut -d"=" -f2 | tr -d '" ' )
LOCATION_SHORT		?=$(shell grep -e '^location_short\s*=' ${TFVARS} | cut -d"=" -f2 | tr -d '" ' )

RG_STATE_NAME		?="GF-RG-${PROJECT_UPPER}-STATE-${ENVCODE_UPPER}"
STORAGE_ACCOUNT		?=$(shell echo "gfsto${PROJECT}tf${ENVCODE}${LOCATION_SHORT}" | tr [A-Z] [a-z])
ACCESS_KEY		?=$(shell az storage account keys list --resource-group ${RG_STATE_NAME} --account-name ${STORAGE_ACCOUNT} --query '[0].value' --output tsv)
ACCOUNT_TYPE            ?=$(shell az account show --query 'user.type' --output tsv)

ifeq (${ACCOUNT_TYPE}, servicePrincipal)
SIGNEDIN_USER           ?=$(shell az account show --query 'user.name' --output tsv)
SIGNEDIN_USER_OBJECTID  ?=$(shell az ad sp show --id ${SIGNEDIN_USER} --query 'objectId' --output tsv)
else
SIGNEDIN_USER_OBJECTID  ?=$(shell az ad signed-in-user show --query 'objectId' --output tsv)
endif

export ARM_SUBSCRIPTION_ID=$(shell az account show --query 'id' --output tsv)
export ARM_TENANT_ID=$(shell az account show --query 'tenantId' --output tsv)

check-env:
ifndef PROJECT_DIR
$(error PROJECT_DIR is not set)
endif

humio:
ifndef HUMIO_APIKEY
$(error HUMIO_APIKEY is not set)
endif
export TF_VAR_HUMIO_APIKEY=$(HUMIO_APIKEY)


vsts-login:
ifdef servicePrincipalId
	echo "vsts-login"
export ARM_SUBSCRIPTION_ID=$(shell az account show --query 'id' --output tsv)
export ARM_TENANT_ID=$(shell az account show --query 'tenantId' --output tsv)
export ARM_CLIENT_ID="${servicePrincipalId}"
export ARM_CLIENT_SECRET="${servicePrincipalKey}"
endif

.PHONY: setupstate
setupstate:
	az group create --name ${RG_STATE_NAME} --location ${LOCATION}
	az group deployment create --resource-group ${RG_STATE_NAME} --template-file arm/storage_container.json --parameters arm/storage_container.parameters.json --parameters storageAccountName=${STORAGE_ACCOUNT}
STORAGE_ACCOUNT?=$(shell echo "gfsto${PROJECT}tf${ENVCODE}${LOCATION_SHORT}" | tr [A-Z] [a-z])

init: check-env vsts-login humio debug
	-rm -f ${HOME}/.kube/config
	terraform init -reconfigure -backend-config="storage_account_name=${STORAGE_ACCOUNT}" -backend-config="access_key=${ACCESS_KEY}" ${PROJECT_DIR}

plan: init
	terraform plan --var-file=${TFVARS} -var "tenant=${ARM_TENANT_ID}" -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "client_id=${servicePrincipalId}" -var "client_secret=${servicePrincipalKey}" -var "signedin_user_objectid=${SIGNEDIN_USER_OBJECTID}" ${PROJECT_DIR}

apply: init
	terraform apply --var-file=${TFVARS} -var "tenant=${ARM_TENANT_ID}" -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "client_id=${servicePrincipalId}" -var "client_secret=${servicePrincipalKey}" -var "signedin_user_objectid=${SIGNEDIN_USER_OBJECTID}" -auto-approve ${PROJECT_DIR}

refresh: init
	terraform refresh --var-file=${TFVARS} -var "tenant=${ARM_TENANT_ID}" -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "client_id=${servicePrincipalId}" -var "client_secret=${servicePrincipalKey}" -var "signedin_user_objectid=${SIGNEDIN_USER_OBJECTID}" ${PROJECT_DIR}

graph: init
	terraform graph --var-file=${TFVARS} ${PROJECT_DIR} | dot -Tsvg > /tmp/graph.svg

output: init
	terraform plan -out=/tmp/output/tfplan --var-file=${TFVARS} -var "tenant=${ARM_TENANT_ID}" -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "client_id=${servicePrincipalId}" -var "client_secret=${servicePrincipalKey}" -var "signedin_user_objectid=${SIGNEDIN_USER_OBJECTID}" ${PROJECT_DIR}
	terraform graph /tmp/output/tfplan --var-file=${TFVARS} -var "tenant=${ARM_TENANT_ID}" -var "subscription_id=${ARM_SUBSCRIPTION_ID}" -var "client_id=${servicePrincipalId}" -var "client_secret=${servicePrincipalKey}" -var "signedin_user_objectid=${SIGNEDIN_USER_OBJECTID}" ${PROJECT_DIR}

destroy: init
	terraform destroy --var-file=${TFVARS} ${PROJECT_DIR}

debug: 
	@echo ENV                 : ${ENVCODE_UPPER}
	@echo PROJECT             : ${PROJECT_UPPER}
	@echo LOCATION            : ${LOCATION}
	@echo LOCATION_SHORT      : ${LOCATION_SHORT}
	@echo RG STATE NAME       : ${RG_STATE_NAME}
	@echo STORAGE ACCOUNT     : ${STORAGE_ACCOUNT}
	@echo ARM_SUBSCRIPTION_ID : ${ARM_SUBSCRIPTION_ID}
	@echo ARM_TENANT_ID       : ${ARM_TENANT_ID}
	@echo ARM_CLIENT_ID       : ${ARM_CLIENT_ID}
	@echo ARM_CLIENT_SECRET   : ${ARM_CLIENT_SECRET}
