### RESOURCE PROVISIONING
variable "prefix" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "grant_admin_consent" {
  type = bool
  default = false
}

# Optionally manually specify RBAC configuration
variable "client_app_id" {
  type = string
  default = ""
}

variable "server_app_id" {
  type = string
  default = ""
}

variable "server_app_secret" {
  type = string
  default = ""
}
