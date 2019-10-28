output "traffic_manager_endpoint_name" {
  value = azurerm_traffic_manager_endpoint.traffic_manager_endpoint.name
}

output "traffic_manager_endpoint_target" {
  value = azurerm_traffic_manager_endpoint.traffic_manager_endpoint.target
}

output "traffic_manager_endpoint_workspace" {
  value = data.external.kubernetes_cluster_ingress_ip.result.terraform_workspace
}

output "traffic_manager_endpoint_aks_cluster_name" {
  value = data.external.kubernetes_cluster_ingress_ip.result.aks_cluster_name
}

output "traffic_manager_endpoint_aks_cluster_resource_group_name" {
  value = data.external.kubernetes_cluster_ingress_ip.result.aks_cluster_resource_group_name
}
