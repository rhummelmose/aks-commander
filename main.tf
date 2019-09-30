######################################################################### MODULES
module "rbac" {
  source = "./modules/rbac"
  prefix = var.prefix
  rbac_aad_tenant_id = var.rbac_aad_tenant_id
  cluster_aad_tenant_id = var.cluster_aad_tenant_id
}

module "aks" {
  source = "./modules/aks"
  subscription_id = var.subscription_id
  prefix = var.prefix
  region = var.region
  cluster_service_principal_client_id = module.rbac.cluster_id
  cluster_service_principal_client_secret = module.rbac.cluster_app_secret
  rbac_client_app_id = module.rbac.client_app_id
  rbac_server_app_id = module.rbac.server_app_id
  rbac_server_app_secret = module.rbac.server_app_secret
  rbac_tenant_id = var.rbac_aad_tenant_id
}

######################################################################### ALL
locals {
  
}
