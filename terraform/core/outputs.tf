output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.log_analytics_workspace.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

output "traffic_manager_profile_name" {
  value = var.domain != null ? azurerm_traffic_manager_profile.traffic_manager_profile[0].name : null
}

output "traffic_manager_profile_id" {
  value = var.domain != null ? azurerm_traffic_manager_profile.traffic_manager_profile[0].id : null
}

output "application_aks_cluster_application_id" {
  value = var.use_managed_identity != true ? azuread_application.application_aks_cluster[0].application_id : null
}

output "random_password_application_aks_cluster_result" {
  value = var.use_managed_identity != true ? random_password.random_password_application_aks_cluster[0].result : null
}
