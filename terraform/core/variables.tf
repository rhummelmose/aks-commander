### RESOURCE PROVISIONING
variable "tenant_id" {
  type        = string
  description = "The AD subscription in which to provision resources"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription in which to provision resources"
}

variable "prefix" {
  type        = string
  description = "Prefix for all the resources provisioned"
}

variable "region" {
  type        = string
  description = "The Azure region in which to provision resources"
}

variable "domain" {
  type        = string
  description = "The domain to use when configuring DNS and Traffic Manager. Leave as null to skip domain creation."
  default     = null
}

variable "subdomain" {
  type        = string
  description = "The subdomain to use when configuring DNS and Traffic Manager. Required if domain is specified. "
  default     = null
}
