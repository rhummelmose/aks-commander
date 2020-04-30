######################################################################### BACKEND
terraform {
  backend "azurerm" {
    key                  = "aks.terraform.tfstate"
  }
}

######################################################################### PROVIDERS
provider "azurerm" {
  subscription_id = var.subscription_id
  version = "~> 2.7.0"
  features {}
}

######################################################################### DATA
data "terraform_remote_state" "remote_state_core" {
  backend = "azurerm"
  workspace = terraform.workspace

  config = {
    subscription_id      = var.tf_backend_subscription_id
    resource_group_name  = var.tf_backend_resource_group_name
    storage_account_name = var.tf_backend_storage_account_name
    container_name       = var.tf_backend_container_name
    key                  = "core.terraform.tfstate"
  }
}

data "terraform_remote_state" "remote_state_rbac" {
  count = var.enable_aad ? 1 : 0
  backend = "azurerm"
  workspace = terraform.workspace

  config = {
    subscription_id      = var.tf_backend_subscription_id
    resource_group_name  = var.tf_backend_resource_group_name
    storage_account_name = var.tf_backend_storage_account_name
    container_name       = var.tf_backend_container_name
    key                  = "rbac.terraform.tfstate"
  }
}

######################################################################### RESOURCES

resource "random_password" "random_password_windows_profile_admin_password" {
  length = 32
  special = true
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "${var.prefix}-aks-cluster-${terraform.workspace}"
  location            = var.region
  resource_group_name = data.terraform_remote_state.remote_state_core.outputs.resource_group_name
  dns_prefix          = "${var.prefix}-aks-cluster-${terraform.workspace}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    min_count           = 3
    max_count           = 10
    vm_size             = "Standard_DS1_v2"
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    availability_zones  = var.availability_zones
    enable_auto_scaling = true
    vnet_subnet_id      = var.vnet_subnet_id
  }

  dynamic "identity" {
    for_each = var.use_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "service_principal" {
    for_each = var.use_managed_identity ? [] : [1]
    content {
      client_id     = data.terraform_remote_state.remote_state_core.outputs.application_aks_cluster_application_id
      client_secret = data.terraform_remote_state.remote_state_core.outputs.random_password_application_aks_cluster_result
    }
  }

  private_cluster_enabled = var.private_cluster_enabled

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    load_balancer_sku  = var.load_balancer_sku
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = var.outbound_type
  }

  windows_profile {
    admin_username = var.windows_admin_username
    admin_password = var.windows_admin_password != null ? var.windows_admin_password : random_password.random_password_windows_profile_admin_password.result
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = data.terraform_remote_state.remote_state_core.outputs.log_analytics_workspace_id
    }
    kube_dashboard {
      enabled = false
    }
  }

  # RBAC without AAD
  dynamic "role_based_access_control" {
    for_each = var.enable_aad ? [] : [1]
    content {
      enabled = !var.disable_rbac
    }
  }

  # RBAC with AAD
  dynamic "role_based_access_control" {
    for_each = var.enable_aad ? [1] : []
    content {
      enabled = !var.disable_rbac
      azure_active_directory {
        server_app_id     = data.terraform_remote_state.remote_state_rbac[0].outputs.server_app_id
        server_app_secret = data.terraform_remote_state.remote_state_rbac[0].outputs.server_app_secret
        client_app_id     = data.terraform_remote_state.remote_state_rbac[0].outputs.client_app_id
        tenant_id         = data.terraform_remote_state.remote_state_rbac[0].outputs.tenant_id
      }
    }
  }

}
