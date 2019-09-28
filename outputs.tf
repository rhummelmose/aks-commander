output "rbac_cluster_id" {
  value = module.rbac.cluster_id
}

output "rbac_cluster_app_id" {
  value = module.rbac.cluster_app_id
}

output "rbac_cluster_app_secret" {
  value = module.rbac.cluster_app_secret
}

output "rbac_client_app_id" {
  value =  module.rbac.client_app_id
}

output "rbac_server_app_id" {
  value = module.rbac.server_app_id
}

output "rbac_server_app_secret" {
  value = module.rbac.server_app_secret
}

output "aks_kube_config" {
  value = module.aks.kube_config
}
