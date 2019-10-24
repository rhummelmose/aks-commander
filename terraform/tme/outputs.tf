output "traffic_manager_endpoint_name" {
  value = azurerm_traffic_manager_endpoint.traffic_manager_endpoint.name
}

output "traffic_manager_endpoint_target" {
  value = azurerm_traffic_manager_endpoint.traffic_manager_endpoint.target
}
