######################################################################### BACKEND
terraform {
  backend "azurerm" {
    key                  = "core.terraform.tfstate"
  }
}

######################################################################### PROVIDER
provider "azurerm" {
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
}
provider "azuread" {
  tenant_id = var.tenant_id
}

######################################################################### RESOURCES
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.prefix}-rg"
  location = var.region
}

resource "random_string" "random_string_log_analytics_workspace_name_suffix" {
  length = 4
  special = false
  upper = false
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${var.prefix}-log-analytics-workspace-${random_string.random_string_log_analytics_workspace_name_suffix.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_traffic_manager_profile" "traffic_manager_profile" {
  count               = var.domain != null ? 1 : 0
  name                = "${var.prefix}-traffic-manager-profile"
  resource_group_name = azurerm_resource_group.resource_group.name

  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "${replace(var.subdomain, ".", "-")}-${replace(var.domain, ".", "-")}"
    ttl           = 1
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_dns_zone" "dns_zone" {
  count               = var.domain != null ? 1 : 0
  name                = var.domain
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_dns_cname_record" "dns_cname_record" {
  count               = var.domain != null ? 1 : 0
  name                = var.subdomain
  zone_name           = azurerm_dns_zone.dns_zone[0].name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 0
  record              = azurerm_traffic_manager_profile.traffic_manager_profile[0].fqdn
}

resource "azurerm_dns_cname_record" "dns_cname_wildcard_record" {
  count               = var.domain != null ? 1 : 0
  name                = "*.${var.subdomain}"
  zone_name           = azurerm_dns_zone.dns_zone[0].name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 0
  record              = azurerm_traffic_manager_profile.traffic_manager_profile[0].fqdn
}

resource "azuread_application" "application_aks_cluster" {
  count = var.use_managed_identity != true ? 1 : 0
  name = "${var.prefix}-aks-cluster"
  type = "native"
}

resource "azuread_service_principal" "service_principal_aks_cluster" {
  count = var.use_managed_identity != true ? 1 : 0
  application_id = azuread_application.application_aks_cluster[0].application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "random_password" "random_password_application_aks_cluster" {
  count = var.use_managed_identity != true ? 1 : 0
  length = 64
  special = true

  keepers = {
    azuread_application = azuread_application.application_aks_cluster[0].application_id
  }
}

resource "azuread_application_password" "application_password_aks_cluster" {
  count = var.use_managed_identity != true ? 1 : 0
  application_object_id = azuread_application.application_aks_cluster[0].id
  value = random_password.random_password_application_aks_cluster[0].result

  end_date = timeadd(timestamp(), "87600h")

  lifecycle {
    ignore_changes = [
      end_date
    ]
  }
}

######################################################################### ALL
locals {
  
}
