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

variable "kubernetes_version" {
  default = "1.15.7"
  type = string
}

variable "use_managed_identity" {
  default = false
  type = bool
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

variable "availability_zones" {
  default = [ "1", "2", "3"]
  type = list(string)
}

variable "private_cluster_enabled" {
  default = false
  type = bool
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

variable "outbound_type" {
  default = "loadBalancer"
  type = string
}

variable "docker_bridge_cidr" {
  default = null
  type = string
}

variable "windows_admin_username" {
  default = "winadmin"
  type = string
}

variable "windows_admin_password" {
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
