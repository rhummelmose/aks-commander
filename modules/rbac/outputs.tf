output "cluster_id" {
  value = azuread_service_principal.aks_cluster.application_id
}

output "cluster_app_id" {
  value = azuread_application.aks_cluster.application_id
}

output "cluster_app_secret" {
  value = random_password.aks_cluster_password.result
}

output "client_app_id" {
  value =  azuread_service_principal.client.application_id
}

output "server_app_id" {
  value = azuread_service_principal.server.application_id
}

output "server_app_secret" {
  value = data.external.secret_in_out.result.secret
}
