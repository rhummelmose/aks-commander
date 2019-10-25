######################################################################### BACKEND
terraform {
  backend "azurerm" {
    key                  = "tme.terraform.tfstate"
  }
}

######################################################################### PROVIDERS
provider "azurerm" {
  subscription_id = var.subscription_id
}

######################################################################### DATA
data "terraform_remote_state" "remote_state_core" {
  backend = "azurerm"

  config = {
    tenant_id            = var.tf_backend_tenant_id
    client_id            = var.tf_backend_client_id
    client_secret        = var.tf_backend_client_secret
    subscription_id      = var.tf_backend_subscription_id
    resource_group_name  = var.tf_backend_resource_group_name
    storage_account_name = var.tf_backend_storage_account_name
    container_name       = var.tf_backend_container_name
    key                  = "core.terraform.tfstate"
  }
}

######################################################################### RESOURCES
resource "azurerm_traffic_manager_endpoint" "traffic_manager_endpoint" {
  name                = "${var.prefix}-traffic-manager-endpoint-${terraform.workspace}"
  resource_group_name = data.terraform_remote_state.remote_state_core.outputs.resource_group_name
  profile_name        = data.terraform_remote_state.remote_state_core.outputs.traffic_manager_profile_name
  target              = var.target
  type                = "externalEndpoints"
  priority            = 10
}
