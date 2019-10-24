######################################################################### BACKEND
terraform {
  backend "azurerm" {
    key                  = "aks.terraform.tfstate"
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

data "terraform_remote_state" "remote_state_rbac" {
  backend = "azurerm"
  
  config = {
    tenant_id            = var.tf_backend_tenant_id
    client_id            = var.tf_backend_client_id
    client_secret        = var.tf_backend_client_secret
    subscription_id      = var.tf_backend_subscription_id
    resource_group_name  = var.tf_backend_resource_group_name
    storage_account_name = var.tf_backend_storage_account_name
    container_name       = var.tf_backend_container_name
    key                  = "rbac.terraform.tfstate"
  }
}

######################################################################### RESOURCES
resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "${var.prefix}-aks-cluster-${var.suffix}"
  location            = var.region
  resource_group_name = data.terraform_remote_state.remote_state_core.outputs.resource_group_name
  dns_prefix          = "${var.prefix}-aks-cluster-${var.suffix}"

  agent_pool_profile {
    name                = "default"
    count               = 3
    min_count           = 3
    max_count           = 10
    vm_size             = "Standard_DS1_v2"
    os_type             = "Linux"
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    availability_zones  = [ "1", "2", "3"]
    enable_auto_scaling = true
  }

  service_principal {
    client_id     = data.terraform_remote_state.remote_state_core.outputs.application_aks_cluster_application_id
    client_secret = data.terraform_remote_state.remote_state_core.outputs.random_password_application_aks_cluster_result
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
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

  role_based_access_control {
    enabled = true
      azure_active_directory {
          server_app_id     = data.terraform_remote_state.remote_state_rbac.outputs.server_app_id
          server_app_secret = data.terraform_remote_state.remote_state_rbac.outputs.server_app_secret
          client_app_id     = data.terraform_remote_state.remote_state_rbac.outputs.client_app_id
          tenant_id         = data.terraform_remote_state.remote_state_rbac.outputs.tenant_id
      }
  }
}
