provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.prefix}-rg-${var.suffix}"
  location = var.region
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${var.prefix}-log-analytics-workspace-${var.suffix}"
  location            = var.region
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-aks-cluster-${var.suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
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
    client_id     = var.cluster_service_principal_client_id
    client_secret = var.cluster_service_principal_client_secret
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
    }
    kube_dashboard {
      enabled = false
    }
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
