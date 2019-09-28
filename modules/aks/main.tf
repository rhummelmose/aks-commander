provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.name}-rg"
  location = var.region
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.name}-aks-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "${var.name}-aks-cluster"

  agent_pool_profile {
    name            = "default"
    count           = 3
    vm_size         = "Standard_D4_v3"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.service_principal_client_id
    client_secret = var.service_principal_client_secret
  }
}
