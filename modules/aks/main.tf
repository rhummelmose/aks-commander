provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.prefix}-rg"
  location = var.region
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-aks-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "${var.prefix}-aks-cluster"

  agent_pool_profile {
    name            = "default"
    count           = 3
    vm_size         = "Standard_D4_v3"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.cluster_service_principal_client_id
    client_secret = var.cluster_service_principal_client_secret
  }

  role_based_access_control {
    enabled = true
      azure_active_directory {
          server_app_id     = var.rbac_server_app_id
          server_app_secret = var.rbac_server_app_secret
          client_app_id     = var.rbac_client_app_id
          tenant_id         = var.rbac_tenant_id
      }
  }
}
