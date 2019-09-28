######################################################################### MODULES
module "rbac" {
  source = "./modules/rbac"
  name = var.name
}

module "aks" {
  source = "./modules/aks"
  name = var.name
  region = var.region
  service_principal_client_id = module.rbac.cluster_id
  service_principal_client_secret = module.rbac.cluster_app_secret
}

######################################################################### ALL
locals {
  
}
