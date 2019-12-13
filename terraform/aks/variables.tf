### RESOURCE PROVISIONING
variable "subscription_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "disable_rbac" {
  default = false
  type = bool
}

variable "enable_aad" {
  default = true
  type = bool
}

variable "network_plugin" {
  default = "azure"
  type = string
}

variable "network_policy" {
  default = "calico"
  type = string
}

variable "load_balancer_sku" {
  default = "standard"
  type = string
}

variable "vnet_subnet_id" {
  default = null
  type = string
}

variable "service_cidr" {
  default = null
  type = string
}

variable "dns_service_ip" {
  default = null
  type = string
}

variable "docker_bridge_cidr" {
  default = null
  type = string
}

### TERRAFORM BACKEND
variable "tf_backend_subscription_id" {
  type = string
}
variable "tf_backend_resource_group_name" {
  type = string
}
variable "tf_backend_storage_account_name" {
  type = string
}
variable "tf_backend_container_name" {
  type = string
}
