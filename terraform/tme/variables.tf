### RESOURCE PROVISIONING
variable "subscription_id" {
  type = string
}

variable "prefix" {
  type = string
}

### TERRAFORM BACKEND
variable "tf_backend_resource_group_name" {
  type = string
}
variable "tf_backend_storage_account_name" {
  type = string
}
variable "tf_backend_container_name" {
  type = string
}
