output "tenant_id" {
  value = var.tenant_id
}

output "client_app_id" {
  value = azuread_service_principal.client.application_id
}

output "server_app_id" {
  value = azuread_service_principal.server.application_id
}

output "server_app_secret" {
  value = random_password.application_server_password.result
}
