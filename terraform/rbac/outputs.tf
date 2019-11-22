output "tenant_id" {
  value = var.tenant_id
}

output "client_app_id" {
  value = var.client_app_id != "" ? var.client_app_id : azuread_service_principal.client[0].application_id
}

output "server_app_id" {
  value = var.server_app_id != "" ? var.server_app_id : azuread_service_principal.server[0].application_id
}

output "server_app_secret" {
  value = var.server_app_secret != "" ? var.server_app_secret : random_password.application_server_password[0].result
}
