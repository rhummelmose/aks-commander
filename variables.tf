variable "rbac_aad_tenant_id" {
  type        = string
  description = "The Azure Active Directory tenant that will be used when authenticating with Kubernetes from kubectl etc."
}

variable "cluster_aad_tenant_id" {
  type        = string
  description = "The Azure Active Directory tenant that will be used for the identity of the cluster. This has to be the home tenant of the subscription you deploy in"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription in which to deploy the cluster"
}

variable "prefix" {
  type        = string
  description = "Prefix for all the resources provisioned"
}

variable "region" {
  type        = string
  description = "The Azure region in which to provision resources"
}
