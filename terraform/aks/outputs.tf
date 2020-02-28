output "kube_config" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config_raw
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.name
}

output "cluster_resource_group_name" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.resource_group_name
}

output "windows_user" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.windows_profile[0].admin_username
}

output "windows_password" {
  value = azurerm_kubernetes_cluster.kubernetes_cluster.windows_profile[0].admin_password
}
