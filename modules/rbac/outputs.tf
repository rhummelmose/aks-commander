output "cluster_id" {
  value = azuread_service_principal.aks_cluster.application_id
}

output "cluster_app_id" {
  value = azuread_application.aks_cluster.application_id
}

output "cluster_app_secret" {
  value = random_string.aks_cluster_password.result
}

output "client_app_id" {
  value =  azuread_application.client.application_id
}

output "server_app_id" {
  value = azuread_application.server.application_id
}

output "server_app_secret" {
  value = random_string.application_server_password.result
}
